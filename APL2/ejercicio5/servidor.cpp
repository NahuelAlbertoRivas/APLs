#include "clases/Partida.hpp"

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <fstream>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <thread>
#include <iostream>
#include <atomic>
#include <csignal>

#include "clases/codigos.hpp"

void configurarSeniales();

using namespace std;

Partida *partida = nullptr;

atomic<int> id{0};
int socketEscucha;

atomic<bool> cerrarNormal(false);
atomic<bool> cerrarInmediato(false);

atomic<bool> partidaFinalizada(false);

void manejarSenal(int senal)
{
    if (senal == SIGUSR1)
    {
        cerrarNormal = true;
        cout << "Recibida señal SIGUSR1. Esperando que terminen los jugadores activos..." << endl;
    }
    else if (senal == SIGUSR2)
    {
        cerrarInmediato = true;
        cout << "Recibida señal SIGUSR2. Forzando fin de partida..." << endl;
    }

    partidaFinalizada = true;

    shutdown(socketEscucha, SHUT_RDWR);
    close(socketEscucha);
}

void aceptarClientes()
{
    int id = 1;

    while (!partidaFinalizada.load())
    {
        int socketComunicacionLocal = accept(socketEscucha, (struct sockaddr *)NULL, NULL);
        if (socketComunicacionLocal < 0)
        {
            if (cerrarNormal || cerrarInmediato || partidaFinalizada)
            {
                break;
            }
            perror("Error en accept");
            continue;
        }

        if (cerrarNormal)
        {
            char codigo = SERVIDOR_LLENO;
            send(socketComunicacionLocal, &codigo, 1, 0);
            close(socketComunicacionLocal);
            continue;
        }

        if (!partida->hayLugar())
        {
            char codigo = SERVIDOR_LLENO;
            send(socketComunicacionLocal, &codigo, 1, 0);
            close(socketComunicacionLocal);
            continue;
        }

        partida->agregarJugador(id++, socketComunicacionLocal);
    }

    if (cerrarInmediato)
    {
        partida->forzarFinalizarPartida(); // Forzar cierre de todos los jugadores
    }
    else if (cerrarNormal)
    {
        partida->esperarJugadores(); // Espera a que terminen naturalmente
    }

    cout << "Servidor finalizado." << endl;
}

int main(int argc, char *argv[])
{

    configurarSeniales();

    int puerto = 0;
    int maxUsuarios = 0;
    string archivoPalabras;
    int cantidadIntentos = 0;

    for (int i = 1; i < argc; ++i)
    {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0)
        {
            cout << "Uso: ./servidor -p <puerto> -u <max_usuarios> -a <archivo_palabras> -c <cantidad_intentos>\n";
            cout << "     o nombres largos:\n";
            cout << "     ./servidor --puerto <puerto> --usuarios <max_usuarios> --archivo <archivo_palabras> --cantidad <cantidad_intentos>\n";
            cout << "\nOpciones:\n";
            cout << "  -p, --puerto      Puerto donde escuchar conexiones\n";
            cout << "  -u, --usuarios    Numero maximo de usuarios\n";
            cout << "  -a, --archivo     Ruta al archivo de palabras\n";
            cout << "  -c, --cantidad    Cantidad de intentos por partida.\n";
            cout << "  -h, --help        Mostrar ayuda\n";

            return EXIT_SUCCESS;
        }
    }

    for (int i = 1; i < argc; ++i)
    {
        if ((strcmp(argv[i], "-p") == 0 || strcmp(argv[i], "--puerto") == 0) && i + 1 < argc)
        {
            puerto = atoi(argv[++i]);
        }
        else if ((strcmp(argv[i], "-u") == 0 || strcmp(argv[i], "--usuarios") == 0) && i + 1 < argc)
        {
            maxUsuarios = atoi(argv[++i]);
        }
        else if ((strcmp(argv[i], "-a") == 0 || strcmp(argv[i], "--archivo") == 0) && i + 1 < argc)
        {
            archivoPalabras = argv[++i];
        }
        else if ((strcmp(argv[i], "-c") == 0 || strcmp(argv[i], "--cantidad") == 0) && i + 1 < argc)
        {
            cantidadIntentos = atoi(argv[++i]);
        }
        else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0)
        {
            continue;
        }
        else
        {
            cerr << "Parametro invalido o faltante." << endl;
            cerr << "Usa -h o --help para ver el uso correcto.\n";
            return EXIT_FAILURE;
        }
    }

    if (maxUsuarios <= 0)
    {
        cerr << "Numero maximo de usuario debe ser mayor a 0." << endl;
        return EXIT_FAILURE;
    }

    if (cantidadIntentos <= 0)
    {
        cerr << "Cantidad de intentos debe ser mayor a 0." << endl;
        return EXIT_FAILURE;
    }

    vector<string> palabras;
    ifstream archivo(archivoPalabras);
    if (!archivo)
    {
        cerr << "No se pudo abrir el archivo de palabras: " << archivoPalabras << endl;
        return EXIT_FAILURE;
    }

    string palabra;
    while (getline(archivo, palabra))
    {
        if (!palabra.empty())
            palabras.push_back(palabra);
    }

    if (palabras.empty())
    {
        cerr << "El archivo de palabras está vacio." << endl;
        return EXIT_FAILURE;
    }

    archivo.close();

    partida = new Partida(maxUsuarios, partidaFinalizada, palabras);

    struct sockaddr_in serverConfig;
    memset(&serverConfig, '0', sizeof(serverConfig));

    serverConfig.sin_family = AF_INET;
    serverConfig.sin_addr.s_addr = htonl(INADDR_ANY);
    serverConfig.sin_port = htons(puerto);

    socketEscucha = socket(AF_INET, SOCK_STREAM, 0);

    // permite reutilizar inmediatamente despues de cerrar
    int opt = 1;
    if (setsockopt(socketEscucha, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0)
    {
        perror("Error en setsockopt");
        return EXIT_FAILURE;
    }

    if (bind(socketEscucha, (struct sockaddr *)&serverConfig, sizeof(serverConfig)) < 0)
    {
        perror("Error en bind");
        return EXIT_FAILURE;
    }

    socklen_t len = sizeof(serverConfig);
    if (getsockname(socketEscucha, (struct sockaddr *)&serverConfig, &len) == -1)
    {
        perror("getsockname");
    }
    else
    {
        char ipStr[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &(serverConfig.sin_addr), ipStr, sizeof(ipStr));
        cout << "Servidor Iniciado en " << ipStr << ":" << puerto << "." << endl;
    }

    listen(socketEscucha, 10);

    thread hiloAceptador(aceptarClientes);

    while (!partidaFinalizada.load())
    {
        this_thread::sleep_for(chrono::milliseconds(100));
    }

    shutdown(socketEscucha, SHUT_RDWR);
    close(socketEscucha);

    hiloAceptador.join();

    return EXIT_SUCCESS;
}

void configurarSeniales()
{
    signal(SIGUSR1, manejarSenal);
    signal(SIGUSR2, manejarSenal);
    signal(SIGPIPE, SIG_IGN);
    signal(SIGINT, SIG_IGN);
}