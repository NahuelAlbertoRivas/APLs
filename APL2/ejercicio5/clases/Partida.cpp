#include "Partida.hpp"
#include <random>

#include <sstream>
#include <iomanip>

map<int, chrono::steady_clock::time_point> tiemposInicio;

Partida::Partida(int maximoJugadores, atomic<bool> &finalizadaFlag, const vector<string> &palabras) : partidaFinalizada(finalizadaFlag)
{
    cantidadJugadores = 0;

    this->palabrasDisponibles = palabras;

    random_device rd;
    mt19937 gen(rd());
    uniform_int_distribution<> distrib(0, palabrasDisponibles.size() - 1);

    if (maximoJugadores < 0)
    {
        this->maximoJugadores = 0;
    }
    else
    {
        this->maximoJugadores = maximoJugadores;
    }
}

bool Partida::hayLugar()
{
    lock_guard<mutex> lock(mtxHilos);
    return cantidadJugadores < maximoJugadores;
}

// no va!!
void Partida::agregarJugador(int id, int socket)
{
    lock_guard<mutex> lock(mtxHilos);
    if (cantidadJugadores >= maximoJugadores)
    {
        return;
    }
    hilosJugadores.emplace_back(&Partida::atenderJugador, this, id, socket);
}

bool Partida::eliminarJugador(Jugador &jugador)
{
    lock_guard<mutex> lockJugadores(mutexJugadores);
    lock_guard<mutex> lockHilos(mtxHilos);

    auto it = find_if(jugadores.begin(), jugadores.end(), [&](Jugador &j)
                      { return j.getId() == jugador.getId(); });

    if (it != jugadores.end())
    {
        jugadores.erase(it);
        cantidadJugadores--;
        return true;
    }

    return false;
}

Jugador &Partida::establecerConexion(int id, char *mensaje, int socket)
{
    string nickname = mensaje;

    {
        std::lock_guard<std::mutex> lock(mutexJugadores);
        jugadores.emplace_back(id, nickname, socket);
        jugadores.back().setConectado();
    }

    {
        std::lock_guard<std::mutex> lockHilos(mtxHilos);
        cantidadJugadores++;
    }

    char codigo = SERVIDOR_CONFIRMA_CONEXION;
    write(socket, &codigo, 1);

    return jugadores.back();
}

bool Partida::enviarPalabraCliente(Jugador &jugador, Palabra palabraOculta)
{
    string mensaje = "Frase: " + palabraOculta.getPalabra() + "\nTenes " + to_string(jugador.getPuntos()) + " puntos por acierto." + "\nTenes " + to_string(jugador.getIntentos()) + " intentos restantes.";
    jugador.enviarMensaje(SERVIDOR_ENVIA_PALABRA, mensaje);

    return true;
}

bool Partida::realizarJugada(Jugador &jugador, Palabra &palabraOculta, char letra)
{
    if (palabraOculta.revelarLetra(letra))
    {
        jugador.incrementarPuntos();
        return true;
    }
    return false;
}

char Partida::recibirLetra(char *letra)
{
    if (*letra == TIEMPO_EXPIRADO)
    {
        return *letra;
    }

    if (!isalpha(*letra))
    {
        return CARACTER_INVALIDO;
    }
    *letra = tolower(*letra);
    return *letra;
}

void Partida::atenderJugador(int id, int socket)
{
    char buffer[2000];
    int n;

    Jugador *jugador = nullptr;
    random_device rd;
    mt19937 gen(rd());
    uniform_int_distribution<> distrib(0, palabrasDisponibles.size() - 1);
    string palabraElegida = palabrasDisponibles[distrib(gen)];

    Palabra palabraOculta(palabraElegida);

    while ((n = read(socket, buffer, sizeof(buffer))) > 0)
    {
        char codigo = buffer[0];
        buffer[n] = 0;
        switch (codigo)
        {
        case CLIENTE_CONECTADO:
            jugador = &establecerConexion(id, &buffer[1], socket);

            if (jugador == nullptr)
            {
                cout << "Jugador no fue inicializado correctamente." << endl;
            }
            else
                cout << jugador->getNickname() << " " << " conectado." << endl;
            break;
        case CLIENTE_LISTO_PARA_EMPEZAR:
        {
            enviarPalabraCliente(*jugador, palabraOculta);

            {
                std::lock_guard<std::mutex> lock(mutexTiempos);
                tiemposInicio[jugador->getId()] = std::chrono::steady_clock::now();
            }
            break;
        }
        case CLIENTE_ENVIA_LETRA:
        {
            char letra = buffer[1];

            char res = recibirLetra(&letra);

            if (res == TIEMPO_EXPIRADO)
            {
                cout << jugador->getNickname() << " " << " se le agoto el tiempo." << endl;
            }
            else if (res == CARACTER_INVALIDO)
            {
                cout << jugador->getNickname() << " " << " envio una letra invalida." << endl;
            }
            else
            { // JUGADA VALIDA

                bool acierto = realizarJugada(*jugador, palabraOculta, letra);

                if (!acierto)
                {
                    jugador->decrementarIntentos();
                    if (jugador->getIntentos() <= 0)
                    {
                        finalizarPartidaJugador(*jugador, palabraOculta, false);
                        return;
                    }
                }

                if (palabraOculta.estaRevelada())
                {
                    //string mensaje = "Revelaste la frase: " + palabraOculta.getPalabra();
                    finalizarPartidaJugador(*jugador, palabraOculta, true);
                    return;
                }
                else
                {
                    enviarPalabraCliente(*jugador, palabraOculta);
                }
            }
            break;
        }
        case CLIENTE_DESCONECTA:
            finalizarPartidaJugador(*jugador, palabraOculta, false);
            break;
        }
    }

    if (n <= 0 && jugador != nullptr)
    {
        finalizarPartidaJugador(*jugador, palabraOculta, false);
        //eliminarJugador(*jugador);
    }
}

void Partida::esperarJugadores()
{
    for (auto &hilo : hilosJugadores)
    {
        if (hilo.joinable())
            hilo.join();
    }
}

void Partida::forzarFinalizarPartida()
{
    vector<int> idsAEliminar;

    {
        lock_guard<mutex> lock(mutexJugadores);
        for (Jugador &j : jugadores)
        {
            string mensaje = "Partida cancelada.\n\n" + obtenerRanking();
            j.cerrarConexionForzada(mensaje);
            idsAEliminar.push_back(j.getId());
        }
    }

    for (int id : idsAEliminar)
    {
        auto it = find_if(jugadores.begin(), jugadores.end(), [&](Jugador &j)
                          { return j.getId() == id; });

        if (it != jugadores.end())
        {
            eliminarJugador(*it);
        }
    }
}

void Partida::finalizarPartidaJugador(Jugador &jugador, Palabra &palabraOculta, bool jugadorGano)
{
    char codigo = SERVIDOR_FIN_PARTIDA;

    bool gano = palabraOculta.estaRevelada();

    double duracion = 0;

    {
        std::lock_guard<std::mutex> lock(mutexTiempos);
        auto it = tiemposInicio.find(jugador.getId());
        if (jugadorGano && it != tiemposInicio.end())
        {
            auto fin = std::chrono::steady_clock::now();
            duracion = std::chrono::duration_cast<std::chrono::milliseconds>(fin - it->second).count() / 1000.0;
            ranking.emplace_back(jugador.getNickname(), duracion);
            tiemposInicio.erase(it); // limpieza
        }
        else
        {
            duracion = -1;
        }
    }

    palabraOculta.revelarPalabra();

    string mensaje = "La frase: " + palabraOculta.getPalabra() + "\nObtuviste " + to_string(jugador.getPuntos()) + " puntos.";

    if (gano && duracion >= 0)
    {
        mensaje += "\nTardaste " + to_string(duracion) + " segundos.";
    }
    else
    {
        mensaje += "\nNo completaste la frase. ¡Perdiste!";
    }

    mensaje += "\n\n" + obtenerRanking();

    jugador.enviarMensaje(codigo, mensaje);
    sleep(1);
    desconectarJugador(jugador);
    eliminarJugador(jugador);
}

void Partida::desconectarJugador(Jugador &jugador)
{
    char codigo = SERVIDOR_DESCONECTA_CLIENTE;

    jugador.enviarCodigo(codigo);

    shutdown(jugador.getSocket(), SHUT_RDWR);
    close(jugador.getSocket());
}

string Partida::obtenerRanking()
{
    string resultado = "=== TOP 10 - RANKING POR TIEMPOS ===\nNickname / Tiempo\n";

    std::lock_guard<std::mutex> lock(mutexTiempos);

    if (ranking.empty())
    {
        resultado += "(vacío)\n";
        return resultado;
    }

    std::sort(ranking.begin(), ranking.end(), [](auto &a, auto &b)
              { return a.second < b.second; });

    int limite = std::min(10, static_cast<int>(ranking.size()));
    for (int i = 0; i < limite; ++i)
    {
        const auto &[nick, tiempo] = ranking[i];

        std::ostringstream tiempoFormateado;
        tiempoFormateado << std::fixed << std::setprecision(3) << tiempo;

        resultado += to_string(i + 1) + ". " + nick + " - " + tiempoFormateado.str() + " segs\n";
    }

    return resultado;
}