# Controle de Servo via PSDK DJI - Raspberry Pi 4B

Este projeto permite controlar um servo motor através de um botão no DJI Pilot 2 usando o PSDK (Payload SDK) da DJI em uma Raspberry Pi 4B.

## Funcionalidades

- Botão personalizado no DJI Pilot 2
- Controle de servo motor via PWM GPIO
- Alternância entre posições (aberto/fechado)
- Integração completa com PSDK

## Estrutura do Projeto

```
psdk_dji/
├── src/
│   ├── main.cpp              # Código principal do PSDK
│   ├── servo_controller.cpp  # Controle do servo
│   └── servo_controller.h    # Header do controlador
├── python/
│   └── servo_pwm.py          # Script Python para controle PWM
├── config/
│   └── config.json           # Configurações do projeto
├── build/                    # Arquivos de compilação
├── CMakeLists.txt            # Configuração CMake
└── README.md                 # Este arquivo
```

## Requisitos

- Raspberry Pi 4B
- PSDK DJI
- Servo motor compatível com 5V
- DJI Mavic 3 Enterprise ou similar
- DJI Pilot 2

## Configuração

1. Instale as dependências do PSDK
2. Configure o GPIO para PWM
3. Compile o projeto
4. Execute no payload da DJI

## Uso

O botão aparecerá no DJI Pilot 2. Ao pressionar:
- Primeira vez: Abre o servo (posição definida)
- Segunda vez: Fecha o servo (posição original)
