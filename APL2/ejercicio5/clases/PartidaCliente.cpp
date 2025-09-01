#include "PartidaCliente.hpp"
#include "codigos.hpp"

#include <iostream>
#include <unistd.h>
#include <string>
#include <cstring>
#include <termios.h>
#include <sys/select.h>
#include <cctype>

using namespace std;

PartidaCliente::PartidaCliente(int socket)
{
    this->socket = socket;
}

bool PartidaCliente::enviarLetra()
{
    constexpr int TIMEOUT_SEGUNDOS = 15;

    struct termios oldt, newt;
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);

    cout << "Es tu turno. Tenés " << TIMEOUT_SEGUNDOS << " segundos para ingresar una letra: ";
    fflush(stdout);

    fd_set read_fds;
    FD_ZERO(&read_fds);
    FD_SET(STDIN_FILENO, &read_fds);
    FD_SET(socket, &read_fds);
    int maxfd = max(STDIN_FILENO, socket) + 1;

    struct timeval timeout;
    timeout.tv_sec = TIMEOUT_SEGUNDOS;
    timeout.tv_usec = 0;

    
    int resultado = select(maxfd, &read_fds, nullptr, nullptr, &timeout);

    tcsetattr(STDIN_FILENO, TCSANOW, &oldt); // restaurar terminal

    if (resultado == -1)
    {
        perror("select");
        return false;
    }
    else if (resultado == 0)
    {
        
        cout << "\n⏰ Tiempo agotado. No ingresaste una letra." << endl << endl;

        char buffer[1] = { CLIENTE_DESCONECTA };
        write(socket, buffer, 1);

        return true;


    }
    else
    {
        if (FD_ISSET(socket, &read_fds))
        {
            char buffer[2000];
            int n = read(socket, buffer, sizeof(buffer));
            if (n <= 0)
            {
                cout << "\nSe perdio la conexion con el servidor.\nCerrando cliente." << endl;
                return false;
            }

            if (buffer[0] == SERVIDOR_FIN_FORZADO)
            {
                cout << "\nEl servidor cerro la partida: " << &buffer[1] << endl;
                return false;
            }

            return enviarLetra();
        }

        if (FD_ISSET(STDIN_FILENO, &read_fds))
        {
            char letra;
            read(STDIN_FILENO, &letra, 1);
            cout << endl;

            if (!isalpha(letra))
            {
                cout << "⚠️ Entrada invalida. Solo letras." << endl << endl;
                return enviarLetra();
            }

            letra = tolower(letra);
            char buffer[2] = { CLIENTE_ENVIA_LETRA, letra };
            write(socket, buffer, 2);
            return true;
        }
    }

    return false;
}

bool PartidaCliente::iniciarPartida(string nickname)
{
    char buffer[2000];
    buffer[0] = CLIENTE_CONECTADO;
    strcpy(&buffer[1], nickname.c_str());
    write(socket, buffer, sizeof(buffer));

    bool jugando = true;

    while (jugando)
    {
        char respuesta[2000];
        int n = read(socket, respuesta, sizeof(respuesta));
        if (n <= 0)
        {
            return false;
        }
        respuesta[n] = '\0';

        // VER si falta poner fin de cadena!!!

        char codigo = respuesta[0];

        switch (codigo)
        {
        case SERVIDOR_LLENO:
            cout << "El servidor esta lleno." << endl;
            return false;

        case SERVIDOR_CONFIRMA_CONEXION:
        {
            cout << "Conectado al servidor." << endl;
            cout << "Empezo la partida." << endl << endl;
            char listo = CLIENTE_LISTO_PARA_EMPEZAR;
            write(socket, &listo, 1);
            break;
        }

        case SERVIDOR_ENVIA_PALABRA:
        {
            cout << endl << endl;
            cout << &respuesta[1] << endl;
            if(!enviarLetra()) {
                jugando = false;
            }
            break;
        }

        case SERVIDOR_FIN_FORZADO:
        {
            cout << "\nEl servidor finalizo la partida: " << &respuesta[1] << endl;
            jugando = false;
            break;
        }

        case SERVIDOR_FIN_PARTIDA:
        {
            cout << "\n\n¡Partida finalizada! " << &respuesta[1] << endl;
            break;
        }

        case SERVIDOR_DESCONECTA_CLIENTE:
        {
            jugando = false;
            break;
        }

        default:
            cout << "\nCodigo desconocido del servidor: " << (int)codigo << endl;
            break;
        }
    }

    return true;
}
