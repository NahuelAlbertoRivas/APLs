#ifndef PALABRA_HPP
#define PALABRA_HPP


#include "Letra.hpp"
#include <vector>
#include <string>

using namespace std;

class Palabra {
private:
    vector<Letra> letras;
    int tam;

public:
    Palabra();
    Palabra(const string& palabra);
    int getTamano();
    string getPalabra();
    bool revelarLetra(char intento);
    void revelarPalabra();
    bool estaRevelada();
};

#endif