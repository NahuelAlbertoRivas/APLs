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
    if (argc != 2) 
    {
        cout << "Falta parámetro" << endl;
        return EXIT_FAILURE;
    }

    string buffer;

    mkfifo(argv[1], 0666);

    ifstream fifo(argv[1]);

    getline(fifo, buffer);

    fifo.clear();
    fifo.close();


    cout << buffer << endl;

    return EXIT_SUCCESS;
}