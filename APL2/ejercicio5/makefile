# Compilador y flags
CXX = g++
CXXFLAGS = -Wall -std=c++17

# Carpetas
SRC_DIR = .
CLASES_DIR = ./clases
OBJ_DIR = ./obj

# Archivos fuente
SRCS = $(SRC_DIR)/servidor.cpp \
       $(SRC_DIR)/cliente.cpp \
       $(CLASES_DIR)/Letra.cpp \
       $(CLASES_DIR)/Palabra.cpp \
       $(CLASES_DIR)/Partida.cpp \
       $(CLASES_DIR)/PartidaCliente.cpp \
       $(CLASES_DIR)/Jugador.cpp

# Archivos objeto generados automáticamente desde SRCS
OBJS = $(SRCS:%.cpp=$(OBJ_DIR)/%.o)

# Ejecutables
TARGET_SERVIDOR = servidor
TARGET_CLIENTE = cliente

# Regla por defecto
all: $(TARGET_SERVIDOR) $(TARGET_CLIENTE)

# Regla genérica para compilar archivos .cpp a .o en obj/
$(OBJ_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Objetos por ejecutable
OBJS_SERVIDOR = $(OBJ_DIR)/servidor.o \
                $(OBJ_DIR)/clases/Letra.o \
                $(OBJ_DIR)/clases/Palabra.o \
                $(OBJ_DIR)/clases/Partida.o \
                $(OBJ_DIR)/clases/Jugador.o

OBJS_CLIENTE = $(OBJ_DIR)/cliente.o \
               $(OBJ_DIR)/clases/PartidaCliente.o

# Compilar ejecutables
$(TARGET_SERVIDOR): $(OBJS_SERVIDOR)
	$(CXX) $(CXXFLAGS) $^ -o $@

$(TARGET_CLIENTE): $(OBJS_CLIENTE)
	$(CXX) $(CXXFLAGS) $^ -o $@

# Limpiar objetos y ejecutables
clean:
	rm -rf $(OBJ_DIR) $(TARGET_SERVIDOR) $(TARGET_CLIENTE)