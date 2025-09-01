#ifndef LETRA_HPP
#define LETRA_HPP

class Letra {
private:
    char valor;
    bool revelado;

public:
    Letra(char valor);
    char getValor();
    bool comparar(char car);
    bool estaRevelado();
    void revelar();
    bool esEspacio();
};

#endif