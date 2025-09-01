#include "../hdr/operacionesFifo.h"
#include <cstdlib>
#include <sys/types.h> // Required for pid_t
#include <filesystem>

//AGUIRRE, SEBASTIAN HERNAN - DE LA CRUZ, LEANDRO ARIEL - JUCHANI CALLAMULLO, JAVIER ANDRES - LOIOTILE, JUAN CRUZ - RIVAS, NAHUEL ALBERTO
namespace fs = std::filesystem;
using namespace std;

// Mostrar ayuda del programa
void mostrarAyuda() {
        cout << "Esta es la ayuda del script, asegurese de que este ingresando todos los parametros correctamente." << "\n";
        cout << "  -a / --archivo    Ruta del archivo de procesamiento (requerido)\n";
        cout << "  -h / --help          Muestra esta ayuda\n" << endl;
}

// Analizar y validar argumentos
void procesarParametros(int argc, char* argv[], string& rutaArch) {

    if(argc == 1){
            cerr << "Error: se deben ingresar parámetros " << endl;
            mostrarAyuda();
            exit (1);
    }

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];

        if (arg == "-a" || arg == "--archivo") {
            if (i + 1 < argc && argv[i + 1][0] != '-') {
                rutaArch = fs::absolute(argv[++i]).string();
            } else {
                cerr << "Error: falta el nombre del archivo después de " << arg << endl;
                exit (1);
            }
        } else if (arg == "-h" || arg == "--help") {
            mostrarAyuda();
            exit(0);
        } else {
            cerr << "Error: opción desconocida " << arg << endl;
            mostrarAyuda();
            exit (1);
        }
    }

    // Verificar si todos los parámetros fueron ingresados
   
    if (rutaArch.empty()) {
        cerr << "Error: debe especificar un archivo con la opción -a." << endl;
        exit (1);
    }

    // Todo bien

}


int main(int argc, char *argv[])
{
    string rutaArch;
    string colaImpr = "/tmp/cola_impresion";
    string pid = to_string(getpid());
    string lineaFifo;
    string fifoPriv = "/tmp/FIFO_" + pid;
    string resuFinal;

    procesarParametros(argc, argv, rutaArch);
    
    lineaFifo = pid + ":" + rutaArch;
    
    escribirFifo(colaImpr,lineaFifo);

    resuFinal = leerFifo(fifoPriv);
    cout << resuFinal << endl;

    borrarFifo(fifoPriv);

    return EXIT_SUCCESS;
}


