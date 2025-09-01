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

    mkfifo(argv[1], 0666);

    ofstream fifo(argv[1]);
    
    fifo << string(argv[2]) << ends;

    fifo.close();

    return EXIT_SUCCESS;
}