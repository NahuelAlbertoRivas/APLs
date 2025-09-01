all: Ejercicio3_Cliente  Ejercicio3_Servidor 

Ejercicio3_Cliente: liboperacionesFifo.a
	g++ src/Ejercicio3_Cliente.cpp -L. -loperacionesFifo -o Ejercicio3_Cliente

Ejercicio3_Servidor: liboperacionesFifo.a
	g++ src/Ejercicio3_Servidor.cpp -L. -loperacionesFifo -o Ejercicio3_Servidor

operacionesFifo.o: src/operacionesFifo.cpp hdr/operacionesFifo.h
	g++ -c src/operacionesFifo.cpp -o operacionesFifo.o

liboperacionesFifo.a: operacionesFifo.o
	ar rcs liboperacionesFifo.a operacionesFifo.o

libs: liboperacionesFifo.a

clean:
	rm Ejercicio3_Cliente Ejercicio3_Servidor operacionesFifo.o liboperacionesFifo.a