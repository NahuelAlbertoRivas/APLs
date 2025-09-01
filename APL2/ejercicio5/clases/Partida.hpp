#ifndef PARTIDA_HPP
#define PARTIDA_HPP



#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <thread>
#include <iostream>
#include <vector>
#include <list>
#include <atomic>
#include <algorithm>
#include <mutex>
#include <condition_variable>

#include "Palabra.hpp"
#include "Jugador.hpp"
#include "codigos.hpp"

#include <map>
#include <chrono>

using namespace std;

class Partida
{
private:
    atomic<int> cantidadJugadores{0};
    int maximoJugadores;
    vector<string> palabrasDisponibles;

    atomic<bool>& partidaFinalizada;

    list<Jugador> jugadores;

    mutex mutexJugadores;
    mutex mtxHilos;

    vector<thread> hilosJugadores;

    vector<pair<string, double>> ranking; // nickname y segundos
    mutex mutexTiempos;

public:
    Partida(int maximoJugadores, atomic<bool>& finalizadaFlag, const vector<string>& palabras);
    bool hayLugar();
    void agregarJugador(int id, int socket);
    bool eliminarJugador(Jugador &jugador);
    
    void atenderJugador(int id, int socket);
    void cerrarPartida();

    Jugador &establecerConexion(int id, char *mensaje, int socket);
    void esperarJugadores();
    void forzarFinalizarPartida();
    bool enviarPalabraCliente(Jugador &jugador, Palabra palabraOculta);
    bool realizarJugada(Jugador &jugador, Palabra &palabraOculta , char letra);
    char recibirLetra(char *letra);
    void finalizarPartidaJugador(Jugador &jugador, Palabra &palabraOculta, bool jugadorGano);
    void desconectarJugador(Jugador &jugador);
    string obtenerRanking();
};


#endif
