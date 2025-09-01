#include "../hdr/operacionesFifo.h"

//AGUIRRE, SEBASTIAN HERNAN - DE LA CRUZ, LEANDRO ARIEL - JUCHANI CALLAMULLO, JAVIER ANDRES - LOIOTILE, JUAN CRUZ - RIVAS, NAHUEL ALBERTO

using namespace std;

int escribirFifo(string nombreFifo, string data)
{
    mkfifo(nombreFifo.c_str(), 0666);

    ofstream fifo(nombreFifo);
    
    fifo << data << ends;

    fifo.close();

    return EXIT_SUCCESS;
}
    
string leerFifo(string nombreFifo)
{
    string buffer;

    mkfifo(nombreFifo.c_str(), 0666);

    ifstream fifo(nombreFifo);

    getline(fifo, buffer);

    fifo.clear();
    fifo.close();

    return buffer;
}

int borrarFifo(string nombreFifo)
{
    unlink(nombreFifo.c_str());

    return EXIT_SUCCESS;
}
    