#include <iostream>
#include <memory>
#include <signal.h>
#include <unistd.h>

// Headers do PSDK DJI
#include "dji_vehicle.hpp"
#include "dji_platform_manager.hpp"
#include "dji_psdk_manager.hpp"

// Header do controlador de servo
#include "servo_controller.h"

// Variáveis globais para controle de shutdown
std::unique_ptr<DJI::OSDK::Vehicle> vehicle;
std::unique_ptr<ServoController> servo_controller;
bool should_exit = false;

/**
 * @brief Handler para sinais de interrupção
 */
void signalHandler(int signum) {
    std::cout << "\nRecebido sinal de interrupção (" << signum << "), desligando..." << std::endl;
    should_exit = true;
}

/**
 * @brief Função principal do payload PSDK
 */
int main(int argc, char* argv[]) {
    std::cout << "=== Controlador de Servo PSDK DJI ===" << std::endl;
    std::cout << "Versão: 1.0.0" << std::endl;
    std::cout << "Plataforma: Raspberry Pi 4B" << std::endl;
    std::cout << "=====================================" << std::endl;
    
    // Configurar handlers de sinal
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);
    
    try {
        // Inicializar plataforma DJI
        std::cout << "Inicializando plataforma DJI..." << std::endl;
        
        // Configurar plataforma (Linux/Raspberry Pi)
        DJI::OSDK::PlatformManager::getInstance().initPlatform();
        
        // Criar instância do veículo
        vehicle = std::make_unique<DJI::OSDK::Vehicle>();
        
        // Aguardar conexão com o drone
        std::cout << "Aguardando conexão com o drone..." << std::endl;
        while (!vehicle->getFwVersion() && !should_exit) {
            std::cout << "Tentando conectar..." << std::endl;
            sleep(1);
        }
        
        if (should_exit) {
            std::cout << "Conexão cancelada pelo usuário" << std::endl;
            return 0;
        }
        
        std::cout << "Conectado ao drone!" << std::endl;
        
        // Verificar se PSDK está disponível
        if (!vehicle->getPSDKManager()) {
            std::cout << "ERRO: PSDK não está disponível neste drone" << std::endl;
            return 1;
        }
        
        // Criar controlador de servo
        std::cout << "Inicializando controlador de servo..." << std::endl;
        servo_controller = std::make_unique<ServoController>(vehicle.get());
        
        // Inicializar controlador
        if (!servo_controller->initialize()) {
            std::cout << "ERRO: Falha ao inicializar controlador de servo" << std::endl;
            return 1;
        }
        
        // Registrar botão no DJI Pilot 2
        std::cout << "Registrando botão no DJI Pilot 2..." << std::endl;
        if (!servo_controller->registerButton()) {
            std::cout << "ERRO: Falha ao registrar botão" << std::endl;
            return 1;
        }
        
        std::cout << "=== Sistema inicializado com sucesso! ===" << std::endl;
        std::cout << "O botão 'Controle Servo' agora está disponível no DJI Pilot 2" << std::endl;
        std::cout << "Pressione Ctrl+C para sair" << std::endl;
        std::cout << "=========================================" << std::endl;
        
        // Loop principal
        while (!should_exit) {
            // Verificar status do servo periodicamente
            std::string status = servo_controller->getStatus();
            std::cout << "\rStatus: " << status << "    " << std::flush;
            
            // Aguardar um pouco
            sleep(2);
        }
        
    } catch (const std::exception& e) {
        std::cout << "ERRO: " << e.what() << std::endl;
        return 1;
    }
    
    // Cleanup
    std::cout << "\nDesligando sistema..." << std::endl;
    
    if (servo_controller) {
        servo_controller->shutdown();
    }
    
    if (vehicle) {
        // Cleanup do veículo DJI
        vehicle.reset();
    }
    
    std::cout << "Sistema desligado com sucesso!" << std::endl;
    return 0;
}
