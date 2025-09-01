#include "../hdr/operacionesFifo.h"
#include <sys/types.h> // Required for pid_t
#include <ctime>
#include <csignal>   // Para signal(), SIGTERM, SIGINT, etc.

//AGUIRRE, SEBASTIAN HERNAN - DE LA CRUZ, LEANDRO ARIEL - JUCHANI CALLAMULLO, JAVIER ANDRES - LOIOTILE, JUAN CRUZ - RIVAS, NAHUEL ALBERTO

using namespace std;

void signalHandler(int signum) {
    std::cout << "\nSeñal (" << signum << ") recibida. Iniciando cierre de Servidor" << std::endl;
    borrarFifo("/tmp/cola_impresion");
    exit(0);
}

// Mostrar ayuda del programa
void mostrarAyuda() {
        cout << "Esta es la ayuda del script, asegurese de que este ingresando todos los parametros correctamente." << "\n";
        cout << "  -i / --impresiones    Cantidad de archivos a imprimir (Requerido). Valor entero positivo.\n";
        cout << "  -h / --help          Muestra esta ayuda\n" << endl;
}

bool esEnteroValidoStoi(const std::string& str, int& valorEntero) {
    try {
        // Usamos un size_t para almacenar el índice del primer carácter no convertido.
        // Esto nos permite verificar si toda la cadena fue consumida.
        size_t pos = 0;
        valorEntero = std::stoi(str, &pos);

        // Si pos no es igual a la longitud de la cadena, significa que
        // hubo caracteres no numéricos después del número.
        // Por ejemplo, "123abc" convertiría "123" y pos sería 3.
        if (pos != str.length()) {
            std::cerr << "Error de argumento inválido. Se debe ingresar un entero positivo "<< std::endl;
            return false; // Contiene caracteres no numéricos
        }

        return true; // Conversión exitosa y toda la cadena es un entero
    } catch (const std::invalid_argument& e) {
        // La cadena no pudo ser convertida a un número (ej. "abc")
        std::cerr << "Error de argumento inválido. Se debe ingresar un entero positivo "<< std::endl;
        return false;
    } catch (const std::out_of_range& e) {
        // El número está fuera del rango representable por un int
        std::cerr << "Error de rango. Se debe ingresar un entero positivo" << std::endl;
        return false;
    }
}

// Analizar y validar argumentos
void procesarParametros(int argc, char *argv[], int& cantImp) {

    if(argc == 1){
        cerr << "Error: se deben ingresar parámetros " << endl;
        mostrarAyuda();
        exit (1);
    }

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];

        if (arg == "-i" || arg == "--impresiones") {
            if (i + 1 < argc && argv[i + 1][0] != '-') {
                if(!esEnteroValidoStoi(argv[++i],cantImp))
                    exit (1);
            } else {
                cerr << "Error: falta la cantidad de impresiones después de " << arg << endl;
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

    // Validamos la cantidad de impresiones
   
    if (cantImp <= 0) {
        cerr << "Por favor, especificar una cantidad de impresiones Entera mayor a 0." << endl;
        exit (1);
    }

    // Todo bien

}

int main(int argc, char *argv[])
{
    // Registrar los manejadores de señales
    // Captura SIGTERM (la señal de terminación por defecto)
    std::signal(SIGTERM, signalHandler);
    // Opcional: También puedes capturar SIGINT (Ctrl+C en la terminal)
    std::signal(SIGINT, signalHandler);
    // Opcional: Capturar SIGHUP (cuando la terminal que inició el proceso se cierra)
    std::signal(SIGHUP, signalHandler);

    int cantImp;
    string buffer;

    procesarParametros(argc, argv, cantImp);

    //ofstream archImpr("/tmp/impresiones.log", ios::app | ios::trunc); //si no existe crea el archivo, y si existe lo vacía
    ofstream archImpr("/tmp/impresiones.log", ios::trunc);

    if (!archImpr.is_open()) 
    {
        cerr << "Error al abrir impresiones" << endl;
        archImpr.close();
        exit (1);
    }

    //procesa la cantidad de impresiones indicada
    for (int i = 0; i < cantImp; i++)
    {
        //lee de la cola de impresion
        string lineaFifo = leerFifo("/tmp/cola_impresion");

        //obtiene el pid y el archivo correspondiente
        string pid = lineaFifo.substr(0,lineaFifo.find(":"));
        string path = lineaFifo.substr(lineaFifo.find(":")+1);

        //arma el nombre del fifo privado
        string fifoPriv = "/tmp/FIFO_" + pid;

        //obtiene la fecha actual y le da el formato especificado
        time_t timestamp = time(NULL);
        struct tm datetime = *localtime(&timestamp);

        char tiempo[50];
        char fecha[50];

        strftime(fecha, 50, "%d/%m/%y", &datetime);
        strftime(tiempo, 50, "%H:%M:%S", &datetime);

        //intenta abrir archivo indicado en cola, realiza validaciones
        ifstream archOrig(path);

        if (!archOrig.is_open()) 
        {
            escribirFifo(fifoPriv,"Error al abrir archivo indicado.");
            archImpr << "PID " + pid + " Error al abrir archivo indicado " + path + " el día " + fecha + " a las " + tiempo << "\n";
        }

        // peek() retorna EOF si no hay más caracteres o si está al final del archivo.
        // Combinado con eof() se asegura que no haya caracteres y que no haya errores de lectura.
        else if (archOrig.peek() == std::ifstream::traits_type::eof() && archOrig.eof()) {
           escribirFifo(fifoPriv,"Error, el archivo indicado está vacío."); // El archivo está vacío
           archImpr << "PID " + pid + " Error, el archivo indicado está vacío " + path + " el día " + fecha + " a las " + tiempo << "\n";
        } 

        else
        {
            //el archivo está ok, lo imprime y escribe el log
            archImpr << "PID " + pid + " imprimió el archivo " + path + " el día " + fecha + " a las " + tiempo << "\n";
            
            archImpr << archOrig.rdbuf() << endl;
            
            escribirFifo(fifoPriv,"OK");
        }

        archOrig.close();
        
    }

    archImpr.close();

    borrarFifo("/tmp/cola_impresion");

    return EXIT_SUCCESS;
}
