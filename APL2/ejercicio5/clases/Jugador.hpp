#ifndef JUGADOR_HPP
#define JUGADOR_HPP

#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <thread>
#include <cctype>
#include <string>
#include <string.h>

using namespace std;

class Jugador{

private:
    int id;
    string nickname;
    int socket;
    int puntos;
    int intentos;
    bool conectado;
    bool jugando;

public:
    Jugador();
    Jugador(int id, const char* nickname, int socket);
    Jugador(int id, string nickname, int socket);
    
    int getId();
    string getNickname();
    void setNickname(string nickname);
    int getSocket();
    int getPuntos();
    int getIntentos();
    bool estaConectado();
    void setConectado();
    void setDesconectado();
    bool estaJugando();
    void setEstaJugando();
    void setEstaEsperando();
    void incrementarPuntos();
    void decrementarIntentos();
    bool enviarCodigo(char codigo);
    bool enviarMensaje(char codigo, string mensaje);
    bool enviarMensaje(char codigo, const char *mensaje);

    void cerrarConexionForzada(string mensaje);
};

#endif