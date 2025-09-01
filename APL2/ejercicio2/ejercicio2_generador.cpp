#include "productor.h"
#include <iostream>
#include <fstream>
#include <random>
#include <filesystem>
#include <sstream>
#include <chrono>
#include <thread>

namespace fs = std::filesystem;

void hilo_productor(int id, int paquetes_por_hilo, const std::string& directorio) {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<> peso_dist(0.0, 300.0);
    std::uniform_int_distribution<> sucursal_dist(1, 50);

    for (int i = 0; i < paquetes_por_hilo; ++i) {
        int id_paquete = id * 10000 + i; // único por hilo
        float peso = peso_dist(gen);
        int destino = sucursal_dist(gen);

        std::ostringstream nombre_archivo;
        nombre_archivo << directorio << "/" << id_paquete << ".paq";

        std::ofstream archivo(nombre_archivo.str());
        archivo << id_paquete << ";" << peso << ";" << destino << std::endl;
        archivo.close();

        std::this_thread::sleep_for(std::chrono::milliseconds(50)); // Simula trabajo
    }
}
