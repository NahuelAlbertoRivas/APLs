#include <iostream>
#include <fstream>
#include <string.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

//AGUIRRE, SEBASTIAN HERNAN - DE LA CRUZ, LEANDRO ARIEL - JUCHANI CALLAMULLO, JAVIER ANDRES - LOIOTILE, JUAN CRUZ - RIVAS, NAHUEL ALBERTO

using namespace std;

int main(int argc, char *argv[])
{
    if (argc != 3) 
    {
        cout << "Falta parámetro" << endl;
        return EXIT_FAILURE;
    }

    mkfifo("/tmp/cola_impresion", 0666);

    ofstream fifo("/tmp/cola_impresion");
    fifo << string(argv[1]) + ":" + string(argv[2]) << ends;
    fifo.close();

    return EXIT_SUCCESS;
}