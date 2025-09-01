#include "Jugador.hpp"

#include "codigos.hpp"

Jugador::Jugador(int id, const char *nickname, int socket)
{
    this->id = id;
    this->nickname = nickname;
    this->socket = socket;
    this->conectado = true;
    this->puntos = 0;
    this->intentos = 3;
    this->jugando = false;
}

Jugador::Jugador(int id, string nickname, int socket)
{
    this->id = id;
    this->nickname = nickname;
    this->socket = socket;
    this->conectado = true;
    this->puntos = 0;
    this->intentos = 3;
    this->jugando = false;
}

Jugador::Jugador()
{
    this->id = 0;
    this->nickname = "Sin nombre";
    this->socket = -1;
    this->conectado = false;
    this->puntos = 0;
    this->intentos = 3;
    this->jugando = false;
}

int Jugador::getId()
{
    return this->id;
}

void Jugador::setConectado()
{
    conectado = true;
}
void Jugador::setDesconectado()
{
    conectado = false;
}

bool Jugador::estaJugando()
{
    return this->jugando;
}

void Jugador::setEstaJugando()
{
    jugando = true;
}

void Jugador::setEstaEsperando()
{
    jugando = false;
}

string Jugador::getNickname()
{
    return nickname;
}

int Jugador::getSocket()
{
    return this->socket;
}

int Jugador::getPuntos()
{
    return this->puntos;
}

int Jugador::getIntentos() {
    return this->intentos;
}

void Jugador::setNickname(string nickname)
{
    this->nickname = nickname;
}

void Jugador::incrementarPuntos()
{
    puntos++;
}

void Jugador::decrementarIntentos() {

    if(this->intentos > 0) {
        this->intentos--;
    }
}

bool Jugador::estaConectado()
{
    return conectado;
}

bool Jugador::enviarCodigo(char codigo)
{
    if (write(socket, &codigo, 1) <= 0)
    {
        return false;
    }
    return true;
}

bool Jugador::enviarMensaje(char codigo, string mensaje)
{
    char buffer[2000];
    buffer[0] = codigo;
    strncpy(&buffer[1], mensaje.c_str(), sizeof(buffer) - 2);
    if (write(socket, buffer, strlen(mensaje.c_str()) + 2) <= 0)
    {
        return false;
    }
    return true;
}

bool Jugador::enviarMensaje(char codigo, const char *mensaje)
{
    char buffer[2000];
    buffer[0] = codigo;
    strncpy(&buffer[1], mensaje, sizeof(buffer) - 2);
    if (write(socket, buffer, strlen(mensaje) + 2) <= 0)
    {
        return false;
    }
    return true;
}

void Jugador::cerrarConexionForzada(string mensaje)
{
    char codigo = SERVIDOR_FIN_FORZADO;
    this->enviarMensaje(codigo, mensaje);
    usleep(200000);
    shutdown(socket, SHUT_RDWR);
    close(socket);
}