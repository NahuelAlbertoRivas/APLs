
#ifndef PARTIDACLIENTE_HPP
#define PARTIDACLIENTE_HPP

#include "codigos.hpp"

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

using namespace std;

class PartidaCliente
{
public:
    mutex mtx;
    condition_variable cv;
    atomic<bool> hayNuevoCodigo;
    bool finalizada;
    bool rechazado;
    char codigo;
    char buffer[2000];
    int socket;

    PartidaCliente(int socket);

    void hiloEscuchaServidor();
    bool iniciarPartida(string nickname);
    bool enviarLetra();
    bool mostrarJugada();
    bool mostrarResultadoFinal();
    bool mostrarInicio();
};

#endif