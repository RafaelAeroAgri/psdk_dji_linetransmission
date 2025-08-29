#include "servo_controller.h"
#include <iostream>
#include <fstream>
#include <chrono>
#include <thread>
#include <cmath>

// Incluir headers do PSDK DJI
#include "dji_vehicle.hpp"
#include "dji_platform_manager.hpp"
#include "dji_psdk_manager.hpp"
#include "dji_psdk_widget.hpp"

// Incluir headers para GPIO (Raspberry Pi)
#include <wiringPi.h>
#include <softPwm.h>

ServoController::ServoController(DJI::OSDK::Vehicle* vehicle, const std::string& config_file)
    : vehicle_(vehicle)
    , current_position_(0.0f)
    , is_open_(false)
    , is_initialized_(false)
    , should_stop_(false)
{
    if (!loadConfig(config_file)) {
        throw std::runtime_error("Falha ao carregar configurações");
    }
}

ServoController::~ServoController() {
    shutdown();
}

bool ServoController::loadConfig(const std::string& config_file) {
    try {
        std::ifstream file(config_file);
        if (!file.is_open()) {
            log("ERROR", "Não foi possível abrir arquivo de configuração: " + config_file);
            return false;
        }
        
        // Aqui você usaria uma biblioteca JSON como nlohmann/json
        // Por simplicidade, vou usar valores padrão
        config_.servo.gpio_pin = 18;
        config_.servo.frequency = 50;
        config_.servo.min_pulse_width = 500;
        config_.servo.max_pulse_width = 2500;
        config_.servo.position_closed = 0.0f;
        config_.servo.position_open = 180.0f;
        config_.servo.default_position = 0.0f;
        
        config_.psdk.app_name = "Servo Controller";
        config_.psdk.app_version = "1.0.0";
        config_.psdk.button_id = "servo_toggle";
        config_.psdk.button_name = "Controle Servo";
        config_.psdk.button_description = "Alterna posição do servo";
        
        config_.system.log_level = "INFO";
        config_.system.update_rate = 50;
        
        log("INFO", "Configurações carregadas com sucesso");
        return true;
        
    } catch (const std::exception& e) {
        log("ERROR", "Erro ao carregar configurações: " + std::string(e.what()));
        return false;
    }
}

bool ServoController::initialize() {
    if (is_initialized_) {
        log("WARNING", "Controlador já inicializado");
        return true;
    }
    
    // Inicializar WiringPi
    if (wiringPiSetupGpio() == -1) {
        log("ERROR", "Falha ao inicializar WiringPi");
        return false;
    }
    
    // Configurar GPIO
    if (!setupGPIO()) {
        log("ERROR", "Falha ao configurar GPIO");
        return false;
    }
    
    // Iniciar thread do servo
    should_stop_ = false;
    servo_thread_ = std::make_unique<std::thread>(&ServoController::servoThread, this);
    
    is_initialized_ = true;
    log("INFO", "Controlador de servo inicializado com sucesso");
    
    return true;
}

bool ServoController::setupGPIO() {
    try {
        // Configurar pino como saída
        pinMode(config_.servo.gpio_pin, OUTPUT);
        
        // Inicializar PWM software
        softPwmCreate(config_.servo.gpio_pin, 0, 100);
        
        // Definir posição inicial
        setServoPosition(config_.servo.default_position);
        
        log("INFO", "GPIO " + std::to_string(config_.servo.gpio_pin) + " configurado para PWM");
        return true;
        
    } catch (const std::exception& e) {
        log("ERROR", "Erro ao configurar GPIO: " + std::string(e.what()));
        return false;
    }
}

bool ServoController::registerButton() {
    if (!vehicle_ || !is_initialized_) {
        log("ERROR", "Veículo não disponível ou controlador não inicializado");
        return false;
    }
    
    try {
        // Registrar widget no PSDK
        auto psdk_manager = vehicle_->getPSDKManager();
        if (!psdk_manager) {
            log("ERROR", "PSDK Manager não disponível");
            return false;
        }
        
        // Criar widget de botão
        DJI::PSDK::WidgetConfig button_config;
        button_config.widgetType = DJI::PSDK::WidgetType::BUTTON;
        button_config.widgetID = config_.psdk.button_id;
        button_config.widgetName = config_.psdk.button_name;
        button_config.widgetDescription = config_.psdk.button_description;
        
        // Registrar callback
        psdk_manager->registerWidgetCallback(
            config_.psdk.button_id,
            [this](const std::string& widget_id, const DJI::PSDK::WidgetData& data) {
                this->onButtonPressed(widget_id, data.buttonData.isPressed);
            }
        );
        
        log("INFO", "Botão registrado no DJI Pilot 2: " + config_.psdk.button_name);
        return true;
        
    } catch (const std::exception& e) {
        log("ERROR", "Erro ao registrar botão: " + std::string(e.what()));
        return false;
    }
}

void ServoController::onButtonPressed(const std::string& button_id, bool is_pressed) {
    if (button_id == config_.psdk.button_id && is_pressed) {
        log("INFO", "Botão pressionado - alternando servo");
        toggleServo();
    }
}

void ServoController::toggleServo() {
    if (!is_initialized_) {
        log("WARNING", "Controlador não inicializado");
        return;
    }
    
    if (is_open_) {
        setServoPosition(config_.servo.position_closed);
        is_open_ = false;
        log("INFO", "Servo fechado");
    } else {
        setServoPosition(config_.servo.position_open);
        is_open_ = true;
        log("INFO", "Servo aberto");
    }
    
    updateStatus();
}

void ServoController::setServoPosition(float angle) {
    if (!is_initialized_) {
        log("WARNING", "Controlador não inicializado");
        return;
    }
    
    try {
        // Limitar ângulo entre 0 e 180 graus
        angle = std::max(0.0f, std::min(180.0f, angle));
        
        // Converter para duty cycle
        float duty_cycle = angleToDutyCycle(angle);
        
        // Aplicar PWM
        softPwmWrite(config_.servo.gpio_pin, static_cast<int>(duty_cycle));
        
        current_position_ = angle;
        
        log("INFO", "Servo movido para " + std::to_string(angle) + "° (duty cycle: " + 
            std::to_string(duty_cycle) + "%)");
        
    } catch (const std::exception& e) {
        log("ERROR", "Erro ao mover servo: " + std::string(e.what()));
    }
}

float ServoController::angleToDutyCycle(float angle) const {
    // Converter ângulo para largura de pulso
    float pulse_width = config_.servo.min_pulse_width + 
                       (angle / 180.0f) * (config_.servo.max_pulse_width - config_.servo.min_pulse_width);
    
    // Converter para duty cycle (20ms = 50Hz)
    float duty_cycle = (pulse_width / 20000.0f) * 100.0f;
    
    return std::max(0.0f, std::min(100.0f, duty_cycle));
}

std::string ServoController::getStatus() const {
    std::string status = "Servo: ";
    status += is_open_ ? "ABERTO" : "FECHADO";
    status += " (Posição: " + std::to_string(current_position_) + "°)";
    status += " | GPIO: " + std::to_string(config_.servo.gpio_pin);
    status += " | Frequência: " + std::to_string(config_.servo.frequency) + "Hz";
    
    return status;
}

bool ServoController::isServoOpen() const {
    return is_open_;
}

void ServoController::servoThread() {
    log("INFO", "Thread do servo iniciada");
    
    while (!should_stop_) {
        // Atualizar status periodicamente
        updateStatus();
        
        // Aguardar próximo ciclo
        std::this_thread::sleep_for(
            std::chrono::milliseconds(1000 / config_.system.update_rate)
        );
    }
    
    log("INFO", "Thread do servo finalizada");
}

void ServoController::updateStatus() {
    if (!vehicle_) {
        return;
    }
    
    try {
        auto psdk_manager = vehicle_->getPSDKManager();
        if (psdk_manager) {
            // Atualizar status no DJI Pilot 2
            std::string status_text = getStatus();
            
            // Aqui você enviaria o status para o DJI Pilot 2
            // usando as APIs do PSDK
            log("DEBUG", "Status atualizado: " + status_text);
        }
    } catch (const std::exception& e) {
        log("ERROR", "Erro ao atualizar status: " + std::string(e.what()));
    }
}

void ServoController::shutdown() {
    if (!is_initialized_) {
        return;
    }
    
    log("INFO", "Desligando controlador de servo...");
    
    // Parar thread
    should_stop_ = true;
    if (servo_thread_ && servo_thread_->joinable()) {
        servo_thread_->join();
    }
    
    // Retornar servo para posição padrão
    setServoPosition(config_.servo.default_position);
    
    // Limpar GPIO
    softPwmStop(config_.servo.gpio_pin);
    digitalWrite(config_.servo.gpio_pin, LOW);
    
    is_initialized_ = false;
    log("INFO", "Controlador de servo desligado");
}

void ServoController::log(const std::string& level, const std::string& message) const {
    std::string timestamp = std::to_string(
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()
        ).count()
    );
    
    std::cout << "[" << timestamp << "] [" << level << "] " << message << std::endl;
}
