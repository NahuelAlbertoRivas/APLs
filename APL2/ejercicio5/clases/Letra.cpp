#include "Letra.hpp"

Letra::Letra(char valor)
{
    this->valor = valor;
    this->revelado = false;
}

char Letra::getValor()
{
    return this->valor;
}

bool Letra::comparar(char car)
{
    return car == this->valor;
}

bool Letra::estaRevelado()
{
    return this->revelado;
}

void Letra::revelar()
{
    this->revelado = true;
}

bool Letra::esEspacio() {
    return this->valor == ' ';
}