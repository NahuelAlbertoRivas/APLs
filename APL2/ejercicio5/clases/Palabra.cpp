#include "Palabra.hpp"

Palabra::Palabra()
{
    this->tam = 0;
}

Palabra::Palabra(const string &palabra)
{
    this->tam = palabra.length();
    for (char c : palabra)
    {
        Letra letra(c);
        if(letra.esEspacio()){
            letra.revelar();
        }
        letras.push_back(letra);
    }
}

int Palabra::getTamano()
{
    return tam;
}

string Palabra::getPalabra()
{
    string resultado;
    for (Letra &letra : letras)
    {
        if (letra.estaRevelado())
        {
            resultado += letra.getValor();
        }
        else
        {
            resultado += "_";
        }
    }
    return resultado;
}

bool Palabra::revelarLetra(char intento)
{
    bool resultado = false;
    for (Letra &letra : letras)
    {
        if (letra.comparar(intento))
        {
            if (!letra.estaRevelado())
            {
                letra.revelar();
                resultado = true;
            }
        }
    }
    return resultado;
}

void Palabra::revelarPalabra()
{
    for (Letra &letra : letras)
    {
        letra.revelar();
    }
}


bool Palabra::estaRevelada()
{
    for (Letra &letra : letras)
    {
        if (!letra.estaRevelado())
        {
            return false;
        }
    }
    return true;
}