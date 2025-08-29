#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Controlador de Servo via PWM para Raspberry Pi 4B
Integração com PSDK DJI
"""

import json
import time
import logging
import signal
import sys
from typing import Dict, Any
import RPi.GPIO as GPIO

class ServoController:
    """Controlador de servo motor via PWM"""
    
    def __init__(self, config_file: str = "../config/config.json"):
        """
        Inicializa o controlador de servo
        
        Args:
            config_file: Caminho para arquivo de configuração
        """
        self.config = self._load_config(config_file)
        self.gpio_pin = self.config['servo']['gpio_pin']
        self.frequency = self.config['servo']['frequency']
        self.min_pulse = self.config['servo']['min_pulse_width']
        self.max_pulse = self.config['servo']['max_pulse_width']
        self.position_closed = self.config['servo']['position_closed']
        self.position_open = self.config['servo']['position_open']
        
        # Estado atual do servo
        self.current_position = self.config['servo']['default_position']
        self.is_open = False
        
        # Configurar logging
        logging.basicConfig(
            level=getattr(logging, self.config['system']['log_level']),
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
        
        # Configurar GPIO
        self._setup_gpio()
        
        # Configurar handlers de sinal
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        self.logger.info("Controlador de servo inicializado")
    
    def _load_config(self, config_file: str) -> Dict[str, Any]:
        """Carrega configurações do arquivo JSON"""
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            self.logger.error(f"Arquivo de configuração não encontrado: {config_file}")
            sys.exit(1)
        except json.JSONDecodeError as e:
            self.logger.error(f"Erro ao decodificar JSON: {e}")
            sys.exit(1)
    
    def _setup_gpio(self):
        """Configura GPIO para PWM"""
        try:
            GPIO.setmode(GPIO.BCM)
            GPIO.setup(self.gpio_pin, GPIO.OUT)
            self.pwm = GPIO.PWM(self.gpio_pin, self.frequency)
            self.pwm.start(0)
            self.logger.info(f"GPIO {self.gpio_pin} configurado para PWM")
        except Exception as e:
            self.logger.error(f"Erro ao configurar GPIO: {e}")
            sys.exit(1)
    
    def _angle_to_duty_cycle(self, angle: float) -> float:
        """
        Converte ângulo para duty cycle do PWM
        
        Args:
            angle: Ângulo em graus (0-180)
            
        Returns:
            Duty cycle em porcentagem
        """
        # Converter ângulo para largura de pulso
        pulse_width = self.min_pulse + (angle / 180.0) * (self.max_pulse - self.min_pulse)
        
        # Converter para duty cycle
        duty_cycle = (pulse_width / 20000.0) * 100.0  # 20ms = 50Hz
        
        return max(0, min(100, duty_cycle))
    
    def set_position(self, angle: float):
        """
        Define a posição do servo
        
        Args:
            angle: Ângulo em graus (0-180)
        """
        try:
            angle = max(0, min(180, angle))
            duty_cycle = self._angle_to_duty_cycle(angle)
            
            self.pwm.ChangeDutyCycle(duty_cycle)
            self.current_position = angle
            
            self.logger.info(f"Servo movido para {angle}° (duty cycle: {duty_cycle:.2f}%)")
            
        except Exception as e:
            self.logger.error(f"Erro ao mover servo: {e}")
    
    def toggle_position(self):
        """Alterna entre posição aberta e fechada"""
        if self.is_open:
            self.set_position(self.position_closed)
            self.is_open = False
            self.logger.info("Servo fechado")
        else:
            self.set_position(self.position_open)
            self.is_open = True
            self.logger.info("Servo aberto")
    
    def get_status(self) -> Dict[str, Any]:
        """Retorna status atual do servo"""
        return {
            'current_position': self.current_position,
            'is_open': self.is_open,
            'gpio_pin': self.gpio_pin,
            'frequency': self.frequency
        }
    
    def _signal_handler(self, signum, frame):
        """Handler para sinais de interrupção"""
        self.logger.info("Recebido sinal de interrupção, limpando GPIO...")
        self.cleanup()
        sys.exit(0)
    
    def cleanup(self):
        """Limpa recursos GPIO"""
        try:
            self.pwm.stop()
            GPIO.cleanup()
            self.logger.info("GPIO limpo com sucesso")
        except Exception as e:
            self.logger.error(f"Erro ao limpar GPIO: {e}")

def main():
    """Função principal para teste"""
    controller = ServoController()
    
    try:
        print("Controlador de Servo - Teste")
        print("Pressione Ctrl+C para sair")
        
        while True:
            command = input("Digite 'toggle' para alternar posição ou 'status' para ver status: ").strip().lower()
            
            if command == 'toggle':
                controller.toggle_position()
            elif command == 'status':
                status = controller.get_status()
                print(f"Status: {status}")
            elif command == 'quit':
                break
            else:
                print("Comando inválido. Use 'toggle', 'status' ou 'quit'")
                
    except KeyboardInterrupt:
        print("\nInterrompido pelo usuário")
    finally:
        controller.cleanup()

if __name__ == "__main__":
    main()
