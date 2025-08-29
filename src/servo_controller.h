#ifndef SERVO_CONTROLLER_H
#define SERVO_CONTROLLER_H

#include <string>
#include <memory>
#include <thread>
#include <atomic>
#include <functional>

// Forward declarations
namespace DJI {
namespace OSDK {
class Vehicle;
}
}

/**
 * @brief Controlador de servo motor para integração com PSDK DJI
 * 
 * Esta classe gerencia o controle de um servo motor através de PWM
 * e integra com o PSDK da DJI para criar botões no DJI Pilot 2
 */
class ServoController {
public:
    /**
     * @brief Construtor
     * @param vehicle Ponteiro para o veículo DJI
     * @param config_file Caminho para arquivo de configuração
     */
    ServoController(DJI::OSDK::Vehicle* vehicle, const std::string& config_file = "../config/config.json");
    
    /**
     * @brief Destrutor
     */
    ~ServoController();
    
    /**
     * @brief Inicializa o controlador
     * @return true se inicializado com sucesso
     */
    bool initialize();
    
    /**
     * @brief Registra o botão no DJI Pilot 2
     * @return true se registrado com sucesso
     */
    bool registerButton();
    
    /**
     * @brief Callback para quando o botão é pressionado
     * @param button_id ID do botão
     * @param is_pressed Estado do botão (true = pressionado)
     */
    void onButtonPressed(const std::string& button_id, bool is_pressed);
    
    /**
     * @brief Alterna a posição do servo
     */
    void toggleServo();
    
    /**
     * @brief Define a posição do servo
     * @param angle Ângulo em graus (0-180)
     */
    void setServoPosition(float angle);
    
    /**
     * @brief Obtém o status atual do servo
     * @return String com informações do status
     */
    std::string getStatus() const;
    
    /**
     * @brief Verifica se o servo está aberto
     * @return true se aberto, false se fechado
     */
    bool isServoOpen() const;
    
    /**
     * @brief Para o controlador e limpa recursos
     */
    void shutdown();

private:
    // Configurações do servo
    struct ServoConfig {
        int gpio_pin;
        int frequency;
        int min_pulse_width;
        int max_pulse_width;
        float position_closed;
        float position_open;
        float default_position;
    };
    
    // Configurações do PSDK
    struct PSDKConfig {
        std::string app_name;
        std::string app_version;
        std::string button_id;
        std::string button_name;
        std::string button_description;
    };
    
    // Configurações do sistema
    struct SystemConfig {
        std::string log_level;
        int update_rate;
    };
    
    // Configuração completa
    struct Config {
        ServoConfig servo;
        PSDKConfig psdk;
        SystemConfig system;
    };
    
    DJI::OSDK::Vehicle* vehicle_;
    Config config_;
    
    // Estado do servo
    std::atomic<float> current_position_;
    std::atomic<bool> is_open_;
    std::atomic<bool> is_initialized_;
    
    // Thread para controle do servo
    std::unique_ptr<std::thread> servo_thread_;
    std::atomic<bool> should_stop_;
    
    // Callback para atualização de status
    std::function<void(const std::string&)> status_callback_;
    
    /**
     * @brief Carrega configurações do arquivo JSON
     * @param config_file Caminho para arquivo de configuração
     * @return true se carregado com sucesso
     */
    bool loadConfig(const std::string& config_file);
    
    /**
     * @brief Configura GPIO para PWM
     * @return true se configurado com sucesso
     */
    bool setupGPIO();
    
    /**
     * @brief Converte ângulo para duty cycle do PWM
     * @param angle Ângulo em graus
     * @return Duty cycle em porcentagem
     */
    float angleToDutyCycle(float angle) const;
    
    /**
     * @brief Thread principal do controlador
     */
    void servoThread();
    
    /**
     * @brief Atualiza status no DJI Pilot 2
     */
    void updateStatus();
    
    /**
     * @brief Log de mensagens
     * @param level Nível do log
     * @param message Mensagem
     */
    void log(const std::string& level, const std::string& message) const;
};

#endif // SERVO_CONTROLLER_H
