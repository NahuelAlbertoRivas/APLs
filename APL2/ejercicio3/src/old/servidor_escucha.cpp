#include <iostream>
#include <fstream>
#include <string.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

//AGUIRRE, SEBASTIAN HERNAN - DE LA CRUZ, LEANDRO ARIEL - JUCHANI CALLAMULLO, JAVIER ANDRES - LOIOTILE, JUAN CRUZ - RIVAS, NAHUEL ALBERTO

using namespace std;

int main()
{
    string buffer;


    mkfifo("/tmp/cola_impresion", 0666);

    ifstream fifo("/tmp/cola_impresion");

    getline(fifo, buffer);

    fifo.clear();
    fifo.close();

    cout << buffer << endl;

    return EXIT_SUCCESS;
}