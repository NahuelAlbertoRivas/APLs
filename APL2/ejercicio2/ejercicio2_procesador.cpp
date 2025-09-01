#include "procesador.h"
#include "productor.h"

#include <iostream>
#include <filesystem>
#include <fstream>
#include <vector>
#include <thread>
#include <mutex>
#include <unordered_map>
#include <getopt.h>
#include <cstring>
#include <chrono>

namespace fs = std::filesystem;
using namespace std;

mutex mtx;
unordered_map<int, float> acumulador_pesos;
int paquetes_procesados = 0;

void mostrar_ayuda() {
    cout << "Uso: ./ejercicio2 -d <directorio> -g <generadores> -c <procesadores> -p <paquetes>\n";
    cout << "  -d --directorio     Ruta al directorio de procesamiento\n"
         << "  -g --generadores    Cantidad de hilos generadores\n"
         << "  -c --procesadores   Cantidad de hilos procesadores\n"
         << "  -p --paquetes       Cantidad total de paquetes\n"
         << "  -h --help           Muestra esta ayuda\n";
}

void limpiar_directorio(const string& dir) {
    fs::remove_all(dir);
    fs::create_directories(dir + "/procesados");
}

void hilo_consumidor(const string& directorio, int id) {
    string path = directorio;

    while (true) {
        vector<fs::path> archivos;

        for (const auto& entry : fs::directory_iterator(path)) {
            if (entry.path().extension() == ".paq") {
                archivos.push_back(entry.path());
            }
        }

        if (archivos.empty()) {
            std::this_thread::sleep_for(chrono::milliseconds(100));
            continue;
        }

        for (const auto& archivo : archivos) {
            ifstream in(archivo);
            if (!in.is_open()) continue;

            string linea;
            getline(in, linea);
            in.close();

            int id_paq, destino;
            float peso;
            sscanf(linea.c_str(), "%d;%f;%d", &id_paq, &peso, &destino);

            {
                lock_guard<mutex> lock(mtx);
                acumulador_pesos[destino] += peso;
                paquetes_procesados++;
            }

            fs::rename(archivo, path + "/procesados/" + archivo.filename().string());
        }

        std::this_thread::sleep_for(chrono::milliseconds(100));
    }
}

int main(int argc, char* argv[]) {
    string directorio;
    int generadores = 0, procesadores = 0, paquetes = 0;

    const char* const short_opts = "d:g:c:p:h";
    const option long_opts[] = {
        {"directorio", required_argument, nullptr, 'd'},
        {"generadores", required_argument, nullptr, 'g'},
        {"procesadores", required_argument, nullptr, 'c'},
        {"paquetes", required_argument, nullptr, 'p'},
        {"help", no_argument, nullptr, 'h'},
        {nullptr, 0, nullptr, 0}
    };

    int opt;
    while ((opt = getopt_long(argc, argv, short_opts, long_opts, nullptr)) != -1) {
        switch (opt) {
            case 'd': directorio = optarg; break;
            case 'g': generadores = atoi(optarg); break;
            case 'c': procesadores = atoi(optarg); break;
            case 'p': paquetes = atoi(optarg); break;
            case 'h': mostrar_ayuda(); return 0;
            default: mostrar_ayuda(); return 1;
        }
    }

    if (directorio.empty() || generadores <= 0 || procesadores <= 0 || paquetes <= 0) {
        cerr << "Error: Parámetros inválidos.\n";
        mostrar_ayuda();
        return 1;
    }

    limpiar_directorio(directorio);

    int por_hilo = paquetes / generadores;
    int resto = paquetes % generadores;

    vector<thread> threads_prod;
    for (int i = 0; i < generadores; ++i) {
        int cantidad = por_hilo + (i < resto ? 1 : 0);
        threads_prod.emplace_back(hilo_productor, i, cantidad, directorio);
    }

    vector<thread> threads_cons;
    for (int i = 0; i < procesadores; ++i) {
        threads_cons.emplace_back(hilo_consumidor, directorio, i);
    }

    for (auto& t : threads_prod) t.join();

    this_thread::sleep_for(chrono::seconds(3)); // esperar que procesadores procesen

    // No hay mecanismo de corte aún: en un diseño real deberías señalizar terminación
    cout << "\nResumen de procesamiento:\n";
    cout << "Total paquetes procesados: " << paquetes_procesados << "\n";
    for (const auto& [destino, peso] : acumulador_pesos) {
        cout << "Sucursal " << destino << ": " << peso << " kg\n";
    }

    exit(0);
}
