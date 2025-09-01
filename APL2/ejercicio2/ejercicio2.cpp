/*
            GRUPO 2
    INTEGRANTES

    AGUIRRE, SEBASTIAN HERNAN
    DE LA CRUZ, LEANDRO ARIEL
    JUCHANI CALLAMULLO, JAVIER ANDRES
    LOIOTILE, JUAN CRUZ
    RIVAS, NAHUEL ALBERTO

*/



#include <iostream>
#include <filesystem>
#include <cstdlib>
#include <fstream>
#include <random>
#include <map>
#include <string>
#include <cstdio> 
#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>


namespace fs = std::filesystem;
using namespace std;





struct ResumenSucursal {
    int cantidadPaquetes = 0;
    float pesoTotal = 0;
};

queue<string> buffer;
const size_t TAM_BUFFER = 10;
mutex mtxBuffer, mtxResumen;
condition_variable cvBufferLleno, cvBufferVacio;
bool produccionFinalizada = false;
map<int, ResumenSucursal> resumenGlobal;

// Mostrar ayuda del programa
void mostrarAyuda() {
    cout << "Uso: ./Ejercicio2 -d <directorio> -g <generadores> -c <consumidores> -p <paquetes>\n";
    cout << "Opciones:\n";
    cout << "  -d / --directorio    Ruta del directorio de procesamiento (requerido)\n";
    cout << "  -g / --generadores   Número de hilos generadores (entero positivo, requerido)\n";
    cout << "  -c / --consumidores  Número de hilos consumidores (entero positivo, requerido)\n";
    cout << "  -p / --paquetes      Cantidad de paquetes a generar (entero positivo, requerido)\n";
    cout << "  -h / --help          Muestra esta ayuda\n";
}

// Analizar y validar argumentos
bool parsearArgumentos(int argc, char* argv[], string& directorio,
                       int& generadores, int& consumidores, int& paquetes) {
    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];

        if (arg == "-d" || arg == "--directorio") {
            if (i + 1 < argc && argv[i + 1][0] != '-') {
                directorio = fs::absolute(argv[++i]).string();
            } else {
                cerr << "Error: falta el nombre del directorio después de " << arg << endl;
                return false;
            }
        } else if (arg == "-g" || arg == "--generadores") {
            if (i + 1 < argc && argv[i + 1][0] != '-') {
                generadores = stoi(argv[++i]);
            } else {
                cerr << "Error: falta el número de generadores después de " << arg << endl;
                return false;
            }
        } else if (arg == "-c" || arg == "--consumidores") {
            if (i + 1 < argc && argv[i + 1][0] != '-') {
                consumidores = stoi(argv[++i]);
            } else {
                cerr << "Error: falta el número de consumidores después de " << arg << endl;
                return false;
            }
        } else if (arg == "-p" || arg == "--paquetes") {
            if (i + 1 < argc && argv[i + 1][0] != '-') {
                paquetes = stoi(argv[++i]);
            } else {
                cerr << "Error: falta el número de paquetes después de " << arg << endl;
                return false;
            }
        } else if (arg == "-h" || arg == "--help") {
            mostrarAyuda();
            return false;
        } else {
            cerr << "Error: opción desconocida " << arg << endl;
            mostrarAyuda();
            return false;
        }
    }

    // Verificar si todos los parámetros fueron ingresados
   
    if (directorio.empty()) {
        cerr << "Error: debe especificar un directorio con la opción -d." << endl;
        return false;
    }
    if (generadores <= 0) {
        cerr << "Error: el número de generadores debe ser mayor que cero." << endl;
        return false;
    }

    if (consumidores <= 0) {
        cerr << "Error: el número de consumidores debe ser mayor que cero." << endl;
        return false;
    }

     if (paquetes <= 0) {
        cerr << "Error: el número de paquetes debe ser mayor que cero." << endl;
        return false;
    }

    if (paquetes > 1000) {
        cerr << "Error: el número de paquetes debe ser menor que mil." << endl;
        return false;
    }


    return true;  // Todo bien

}


bool limpiarDirectorio(const string& directorio) {
    try {
        // Borra todo el contenido del directorio, incluyendo subdirectorios y archivos
        if (fs::exists(directorio)) {
            fs::remove_all(directorio);
        }

        // Crear directorio base
        fs::create_directories(directorio);

        // Crear subdirectorio "procesados"
        fs::create_directories(directorio + "/procesados");

        return true;
    } catch (const exception& e) {
        cerr << "Error al limpiar el directorio: " << e.what() << endl;
        return false;
    }
}



// Genera un número flotante aleatorio entre min y max
float randomFloat(float min, float max) {
    static random_device rd;
    static mt19937 gen(rd());
    uniform_real_distribution<float> dis(min, max);
    return dis(gen);
}

// Genera un número entero aleatorio entre min y max
int randomInt(int min, int max) {
    static random_device rd;
    static mt19937 gen(rd());
    uniform_int_distribution<> dis(min, max);
    return dis(gen);
}



void generadorThread(const string& directorio, int desdeID, int hastaID) {
    for (int i = desdeID; i <= hastaID; i++) {
        // generar datos aleatorios
        float peso = randomFloat(0.0, 300.0);
        int destino = randomInt(1, 50);
        string nombreArchivo = to_string(i) + ".paq";
        string pathArchivo = directorio + "/" + nombreArchivo;

        // crear el archivo con esos datos
        ofstream archivo(pathArchivo);
        if (archivo) {
            archivo << i << ";" << peso << ";" << destino << endl;
            archivo.close();
        } else {
            cerr << "Error creando archivo: " << pathArchivo << endl;
            continue;
        }

        // esperar a que haya espacio en el buffer
        unique_lock<mutex> lock(mtxBuffer);
        cvBufferLleno.wait(lock, [] { return buffer.size() < TAM_BUFFER; }); // wait libera el lock mientras espera, y lo vuelve a tomar cuando la condición se cumple.

        // agregar el nombre del archivo al buffer
        buffer.push(nombreArchivo);
       

        // liberar el lock y notificar a un consumidor que hay un nuevo paquete disponible
        lock.unlock();
        cvBufferVacio.notify_one();
    }
}

void consumidorThread(const string& directorio) {
    fs::path procesadosPath = fs::path(directorio) / "procesados";

    while (true) {
        string nombreArchivo;
        {
            unique_lock<mutex> lock(mtxBuffer);
            cvBufferVacio.wait(lock, [] {
                return !buffer.empty() || produccionFinalizada;
            });

            if (buffer.empty() && produccionFinalizada) break;

            nombreArchivo = buffer.front();
            buffer.pop();
            lock.unlock();
            cvBufferLleno.notify_one();
        }

        fs::path pathArchivo = fs::path(directorio) / nombreArchivo;
        ifstream archivo(pathArchivo);
        if (!archivo) {
            cerr << "Error abriendo archivo: " << pathArchivo << endl;
            continue;
        }
       

        string linea;
        if (getline(archivo, linea)) {
            int id, destino;
            float peso;
            if (sscanf(linea.c_str(), "%d;%f;%d", &id, &peso, &destino) == 3) {
                lock_guard<mutex> lockResumen(mtxResumen);
                resumenGlobal[destino].cantidadPaquetes += 1;
                resumenGlobal[destino].pesoTotal += peso;
            }
        }

        archivo.close();
        fs::rename(pathArchivo, procesadosPath / pathArchivo.filename());
    }
}





int main(int argc, char* argv[]) {
      string directorio;
    int generadores = 0, consumidores = 0, paquetes = 0;

    if (!parsearArgumentos(argc, argv, directorio, generadores, consumidores, paquetes)) {
        return 1;
    }

    if (!limpiarDirectorio(directorio)) return 1;

    vector<thread> hilosGeneradores;
    vector<thread> hilosConsumidores;

    // CONSUMIDORES
    for (int i = 0; i < consumidores; ++i) {
        hilosConsumidores.emplace_back(consumidorThread, directorio);
    }

    int paquetesPorGenerador = paquetes / generadores;
    int resto = paquetes % generadores;  // paquetes sobrantes para repartir uno a uno
    int idInicio = 1;

    // GENERADORES
    for (int i = 0; i < generadores; ++i) {
    int cantidad = paquetesPorGenerador;
    if (resto > 0) {
        cantidad += 1;  // reparto un paquete extra si queda resto
        resto--;
    }
    int idFin = idInicio + cantidad - 1;

    hilosGeneradores.emplace_back(generadorThread, directorio, idInicio, idFin);

    idInicio = idFin + 1;
    }


    for (auto& t : hilosGeneradores) t.join();

    {
        lock_guard<mutex> lock(mtxBuffer);
        produccionFinalizada = true;
    }
    cvBufferVacio.notify_all();

    for (auto& t : hilosConsumidores) t.join();

    cout << "\nResumen por sucursal destino:\n";
    cout << "Sucursal\tCantidad\tPeso Total (kg)\n";
    for (const auto& [sucursal, datos] : resumenGlobal) {
        cout << sucursal << "\t\t" << datos.cantidadPaquetes << "\t\t" << datos.pesoTotal << "\n";
    }

    return 0;
}
