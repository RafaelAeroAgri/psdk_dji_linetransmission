cmake_minimum_required(VERSION 3.10)
project(psdk_servo_controller)

# Configurar C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Configurar compilador
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -O2")

# Encontrar bibliotecas necessárias
find_package(PkgConfig REQUIRED)

# WiringPi (para GPIO da Raspberry Pi)
find_library(WIRINGPI_LIBRARY wiringPi)
if(NOT WIRINGPI_LIBRARY)
    message(FATAL_ERROR "WiringPi não encontrado. Instale com: sudo apt-get install wiringpi")
endif()

# PSDK DJI (assumindo que está instalado em /usr/local)
set(DJI_PSDK_INCLUDE_DIR "/usr/local/include/dji-psdk")
set(DJI_PSDK_LIBRARY_DIR "/usr/local/lib")

if(NOT EXISTS ${DJI_PSDK_INCLUDE_DIR})
    message(FATAL_ERROR "PSDK DJI não encontrado em ${DJI_PSDK_INCLUDE_DIR}")
endif()

# Incluir diretórios
include_directories(
    ${CMAKE_SOURCE_DIR}/src
    ${DJI_PSDK_INCLUDE_DIR}
    /usr/local/include
)

# Arquivos fonte
set(SOURCES
    src/main.cpp
    src/servo_controller.cpp
)

# Criar executável
add_executable(psdk_servo_controller ${SOURCES})

# Linkar bibliotecas
target_link_libraries(psdk_servo_controller
    ${WIRINGPI_LIBRARY}
    pthread
    rt
    dl
)

# Linkar bibliotecas do PSDK DJI
target_link_directories(psdk_servo_controller PRIVATE ${DJI_PSDK_LIBRARY_DIR})

# Configurações específicas para Raspberry Pi
if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
    target_compile_definitions(psdk_servo_controller PRIVATE RASPBERRY_PI)
    message(STATUS "Compilando para Raspberry Pi")
endif()

# Instalar
install(TARGETS psdk_servo_controller
    RUNTIME DESTINATION bin
)

# Copiar arquivos de configuração
install(FILES config/config.json
    DESTINATION /etc/psdk_servo_controller
)

# Script de instalação
install(SCRIPT install_scripts/install.sh
    DESTINATION /usr/local/bin
)

# Configurar permissões
install(CODE "execute_process(COMMAND chmod +x /usr/local/bin/install.sh)")

# Mensagem de sucesso
message(STATUS "Configuração CMake concluída")
message(STATUS "Para compilar: make")
message(STATUS "Para instalar: sudo make install")
