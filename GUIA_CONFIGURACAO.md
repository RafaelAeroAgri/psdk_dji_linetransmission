# Guia de Configuração - Controlador de Servo PSDK DJI

## Visão Geral

Este projeto permite controlar um servo motor através de um botão no DJI Pilot 2 usando o PSDK (Payload SDK) da DJI em uma Raspberry Pi 4B.

## Requisitos de Hardware

### Raspberry Pi 4B
- **Modelo**: Raspberry Pi 4B (2GB, 4GB ou 8GB RAM)
- **Sistema Operacional**: Raspberry Pi OS (Bullseye ou mais recente)
- **Armazenamento**: MicroSD de pelo menos 16GB (classe 10 recomendado)

### Drone DJI
- **Modelo**: DJI Mavic 3 Enterprise, Matrice 300 RTK, ou similar
- **Firmware**: Versão mais recente
- **DJI Pilot 2**: Versão mais recente

### Servo Motor
- **Tipo**: Servo padrão (SG90, MG996R, etc.)
- **Voltagem**: 5V
- **Corrente**: Máximo 1A
- **Ângulo**: 0-180 graus

### Conexões
- **Alimentação**: 5V do Raspberry Pi ou fonte externa
- **Sinal**: GPIO 18 (configurável)
- **GND**: Terra comum

## Instalação

### 1. Preparar Raspberry Pi

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
sudo apt install -y git curl wget
```

### 2. Clonar Projeto

```bash
cd /home/pi
git clone https://github.com/seu-usuario/psdk_dji.git
cd psdk_dji
```

### 3. Executar Instalação

```bash
# Dar permissão de execução
chmod +x install_scripts/install.sh

# Executar script de instalação
sudo ./install_scripts/install.sh
```

### 4. Instalar PSDK DJI

**IMPORTANTE**: Você precisa ter acesso ao PSDK DJI através do programa de desenvolvedores da DJI.

```bash
# Baixar PSDK DJI (substitua pela versão correta)
wget https://developer.dji.com/downloads/payload-sdk

# Instalar PSDK
sudo dpkg -i dji-psdk-*.deb
```

## Configuração

### 1. Configurar Servo

Edite o arquivo `/opt/psdk_servo_controller/config/config.json`:

```json
{
  "servo": {
    "gpio_pin": 18,           // Pino GPIO (18 é o padrão)
    "frequency": 50,          // Frequência PWM (50Hz para servos)
    "min_pulse_width": 500,   // Largura mínima de pulso (microssegundos)
    "max_pulse_width": 2500,  // Largura máxima de pulso (microssegundos)
    "position_closed": 0,     // Posição fechada (graus)
    "position_open": 180,     // Posição aberta (graus)
    "default_position": 0     // Posição inicial (graus)
  }
}
```

### 2. Configurar Conexões

#### Diagrama de Conexão
```
Servo Motor          Raspberry Pi 4B
┌─────────────┐      ┌─────────────┐
│    VCC      │──────│     5V      │
│             │      │             │
│   Signal    │──────│   GPIO 18   │
│             │      │             │
│    GND      │──────│    GND      │
└─────────────┘      └─────────────┘
```

#### Pinout do Raspberry Pi 4B
```
GPIO 18 = Pino 12 (físico)
5V      = Pino 2 ou 4
GND     = Pino 6, 9, 14, 20, 25, 30, 34 ou 39
```

### 3. Testar Servo

```bash
# Testar controle básico do servo
sudo test-servo

# Verificar status do serviço
sudo servo-status
```

## Uso

### 1. Iniciar Sistema

```bash
# Iniciar serviço
sudo systemctl start psdk-servo

# Verificar se está rodando
sudo systemctl status psdk-servo
```

### 2. Conectar ao Drone

1. **Ligar drone DJI**
2. **Conectar Raspberry Pi ao drone** (via cabo USB ou rede)
3. **Abrir DJI Pilot 2**
4. **Verificar conexão** - o botão "Controle Servo" deve aparecer

### 3. Usar Botão

- **Primeira vez**: Pressione o botão para abrir o servo
- **Segunda vez**: Pressione novamente para fechar o servo
- **Status**: O status é exibido em tempo real

## Troubleshooting

### Problemas Comuns

#### 1. Servo não responde
```bash
# Verificar conexões
gpio readall

# Testar PWM
sudo python3 /opt/psdk_servo_controller/python/servo_pwm.py
```

#### 2. PSDK não conecta
```bash
# Verificar logs
sudo journalctl -u psdk-servo -f

# Verificar permissões
ls -la /dev/ttyUSB*
sudo usermod -a -G dialout $USER
```

#### 3. Botão não aparece no DJI Pilot 2
- Verificar se o drone suporta PSDK
- Verificar firmware do drone
- Verificar versão do DJI Pilot 2

#### 4. Erro de compilação
```bash
# Reinstalar dependências
sudo apt install -y build-essential cmake wiringpi

# Limpar build
cd /opt/psdk_servo_controller/build
make clean
cmake ..
make
```

### Logs e Debug

```bash
# Ver logs em tempo real
sudo journalctl -u psdk-servo -f

# Ver últimos 50 logs
sudo journalctl -u psdk-servo -n 50

# Ver logs de erro
sudo journalctl -u psdk-servo -p err
```

## Personalização

### 1. Mudar Pino GPIO

Edite `config/config.json`:
```json
{
  "servo": {
    "gpio_pin": 12  // Novo pino
  }
}
```

### 2. Ajustar Posições do Servo

```json
{
  "servo": {
    "position_closed": 45,   // Posição fechada personalizada
    "position_open": 135     // Posição aberta personalizada
  }
}
```

### 3. Adicionar Múltiplos Servos

Crie múltiplas instâncias do controlador ou modifique o código para suportar múltiplos servos.

## Segurança

### 1. Permissões
- O serviço roda como root para acesso ao GPIO
- Arquivos de configuração são protegidos
- Logs são rotacionados automaticamente

### 2. Hardware
- Use fonte de alimentação adequada para o servo
- Proteja contra curto-circuito
- Use capacitores de desacoplamento se necessário

### 3. Software
- Atualize regularmente o sistema
- Monitore logs para problemas
- Faça backup das configurações

## Manutenção

### 1. Atualizações
```bash
# Atualizar código
cd /opt/psdk_servo_controller
git pull

# Recompilar
cd build
make clean && make

# Reiniciar serviço
sudo systemctl restart psdk-servo
```

### 2. Backup
```bash
# Fazer backup das configurações
sudo cp /opt/psdk_servo_controller/config/config.json ~/backup_config.json
```

### 3. Limpeza
```bash
# Limpar logs antigos
sudo journalctl --vacuum-time=7d
```

## Suporte

Para problemas ou dúvidas:
1. Verificar logs do sistema
2. Consultar documentação do PSDK DJI
3. Verificar compatibilidade do hardware
4. Contatar suporte técnico se necessário

## Licença

Este projeto está sob licença MIT. Veja o arquivo LICENSE para detalhes.
