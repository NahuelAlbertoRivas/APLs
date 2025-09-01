#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <thread>
#include <iostream>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <future>
#include <csignal>
#include <unistd.h>
#include <iostream>

#include <termios.h>
#include "clases/PartidaCliente.hpp"

termios configOriginal;
bool configOriginalGuardado = false;


void configurarSeniales();
void cerrarCliente(int signum);
void cerrarClienteConRanking(int signum);
void cerrarClienteForzado(int signum);
void restaurarTerminal();

bool conectado = false;

int socketGlobal;

using namespace std;

int main(int argc, char *argv[])
{
    configurarSeniales();

    tcgetattr(STDIN_FILENO, &configOriginal);
    configOriginalGuardado = true;

    string nickname;
    string ipServidor;
    int puerto = 0;

    for (int i = 1; i < argc; ++i)
    {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0)
        {
            cout << "Uso: ./cliente -n <nickname> -p <puerto> -s <ip_servidor>\n";
            cout << "     o bien: ./cliente --nickname <nickname> --puerto <puerto> --servidor <ip>\n";
            cout << "\nOpciones:\n";
            cout << "  -n, --nickname     Nickname del jugador\n";
            cout << "  -p, --puerto       Puerto del servidor\n";
            cout << "  -s, --servidor     IP del servidor\n";
            cout << "  -h, --help         Mostrar ayuda\n";
            cout << "\nEl usuario tiene 15 segundos para enviarle la letra al servidor, o se cierra la partida.\n";
            cout << "Se agregó SIGUSR1 y SIGUSR2 para cerrar el cliente.\n";
            return EXIT_SUCCESS;
        }
    }

    for (int i = 1; i < argc; ++i)
    {
        if ((strcmp(argv[i], "-n") == 0 || strcmp(argv[i], "--nickname") == 0) && i + 1 < argc)
        {
            nickname = argv[++i];
        }
        else if ((strcmp(argv[i], "-p") == 0 || strcmp(argv[i], "--puerto") == 0) && i + 1 < argc)
        {
            puerto = atoi(argv[++i]);
        }
        else if ((strcmp(argv[i], "-s") == 0 || strcmp(argv[i], "--servidor") == 0) && i + 1 < argc)
        {
            ipServidor = argv[++i];
        }
        else
        {
            cerr << "Parametro invalido o faltante." << endl;
            cerr << "Use -h o --help para ver el uso correcto.\n";
            return EXIT_FAILURE;
        }
    }
    
    if (nickname.empty() || ipServidor.empty() || puerto == 0)
    {
        cerr << "Faltan argumentos obligatorios.\n";
        cerr << "Use -h o --help para ver el uso correcto.\n";
        return EXIT_FAILURE;
    }

    struct sockaddr_in socketConfig;
    memset(&socketConfig, '0', sizeof(socketConfig));

    socketConfig.sin_family = AF_INET;
    socketConfig.sin_port = htons(puerto);
    if (inet_pton(AF_INET, ipServidor.c_str(), &socketConfig.sin_addr) <= 0)
    {
        cout << "Dirección IP inválida" << endl;
        return EXIT_FAILURE;
    }

    int socketComunicacion = socket(AF_INET, SOCK_STREAM, 0);
    if (socketComunicacion < 0)
    {
        cout << "Error al crear el socket" << endl;
        return EXIT_FAILURE;
    }

    socketGlobal = socketComunicacion;

    int resultadoConexion = connect(socketComunicacion,
                                    (struct sockaddr *)&socketConfig, sizeof(socketConfig));
    if (resultadoConexion < 0)
    {
        cout << "No se pudo conectar al servidor." << endl;
        close(socketComunicacion);
        return EXIT_FAILURE;
    }

    conectado = true;

    PartidaCliente partida(socketComunicacion);
    partida.iniciarPartida(nickname);

    restaurarTerminal();

    return EXIT_SUCCESS;
}


void cerrarCliente(int signum) {

    char buffer[1];
    buffer[0] = CLIENTE_DESCONECTA;
    write(socketGlobal, buffer, 1);

    restaurarTerminal();
    close(socketGlobal);

    exit(0);
}

void cerrarCliente() {

    char buffer[1];
    buffer[0] = CLIENTE_DESCONECTA;
    write(socketGlobal, buffer, 1);

    restaurarTerminal();
    close(socketGlobal);

    exit(0);
}


void configurarSeniales() {
    //signal(SIGINT, cerrarCliente);
    //signal(SIGTERM, cerrarCliente);
    signal(SIGINT, SIG_IGN);
    signal(SIGUSR1, cerrarClienteConRanking);
    signal(SIGUSR2, cerrarClienteConRanking);  
}

void cerrarClienteConRanking(int signum) {

    cout << "Cerrando partida..." << endl;

    cerrarCliente();
}

void restaurarTerminal() {
    if (configOriginalGuardado) {
        tcsetattr(STDIN_FILENO, TCSANOW, &configOriginal);
    }
}