#!/bin/bash
# -*- coding: utf-8 -*-
"""
Script de Instalação PSDK DJI para Raspberry Pi 4B (Sem Desktop)
Instala automaticamente o sistema de controle de servo via PSDK
"""

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configurações
PROJECT_NAME="psdk_servo_controller"
INSTALL_DIR="/opt/${PROJECT_NAME}"
SERVICE_NAME="psdk-servo"
USER_NAME="pi"

log_info "🚁 Instalando PSDK DJI Servo Controller na Raspberry Pi 4B"
log_info "=========================================================="

# Verificar se é Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo; then
    log_error "Este script deve ser executado em uma Raspberry Pi"
    exit 1
fi

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    log_error "Execute este script como root (sudo)"
    exit 1
fi

# Atualizar sistema
log_info "📦 Atualizando sistema..."
apt update && apt upgrade -y

# Instalar dependências essenciais
log_info "🔧 Instalando dependências..."
apt install -y \
    git \
    cmake \
    build-essential \
    wiringpi \
    python3 \
    python3-pip \
    python3-dev \
    python3-gpiozero \
    libssl-dev \
    libusb-1.0-0-dev \
    pkg-config \
    udev \
    systemd \
    network-manager

# Criar diretório de instalação
log_info "📁 Criando diretório de instalação..."
mkdir -p ${INSTALL_DIR}
mkdir -p ${INSTALL_DIR}/config
mkdir -p ${INSTALL_DIR}/python
mkdir -p ${INSTALL_DIR}/src
mkdir -p ${INSTALL_DIR}/logs

# Copiar arquivos do projeto
log_info "📋 Copiando arquivos do projeto..."
cp -r config/* ${INSTALL_DIR}/config/
cp -r python/* ${INSTALL_DIR}/python/
cp -r src/* ${INSTALL_DIR}/src/
cp CMakeLists.txt ${INSTALL_DIR}/
cp requirements.txt ${INSTALL_DIR}/

# Definir permissões
log_info "🔐 Configurando permissões..."
chown -R ${USER_NAME}:${USER_NAME} ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/python/*.py

# Instalar dependências Python
log_info "🐍 Instalando dependências Python..."
cd ${INSTALL_DIR}
pip3 install -r requirements.txt

# Compilar código C++
log_info "🔨 Compilando código C++..."
mkdir -p build
cd build
cmake ..
make -j4

# Criar arquivo de serviço systemd
log_info "⚙️ Configurando serviço systemd..."
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=PSDK DJI Servo Controller
After=network.target
Wants=network.target

[Service]
Type=simple
User=${USER_NAME}
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/build/psdk_servo_controller
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd e habilitar serviço
log_info "🔄 Configurando serviço..."
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}

# Configurar GPIO
log_info "🔌 Configurando GPIO..."
usermod -a -G gpio ${USER_NAME}

# Criar regras udev para GPIO
cat > /etc/udev/rules.d/99-gpio.rules << EOF
SUBSYSTEM=="gpio", GROUP="gpio", MODE="0660"
EOF

# Configurar rede para PSDK
log_info "🌐 Configurando rede para PSDK..."
cat > /etc/network/interfaces.d/psdk << EOF
# Configuração PSDK DJI
auto wlan0
iface wlan0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
EOF

# Configurar firewall
log_info "🔥 Configurando firewall..."
ufw allow 14550/udp  # Porta PSDK DJI
ufw allow 22/tcp      # SSH
ufw --force enable

# Criar script de teste
log_info "🧪 Criando script de teste..."
cat > ${INSTALL_DIR}/test_psdk.sh << 'EOF'
#!/bin/bash
echo "🧪 Testando PSDK DJI Servo Controller"
echo "====================================="

# Verificar serviço
echo "📊 Status do serviço:"
systemctl status psdk-servo --no-pager

# Verificar GPIO
echo -e "\n🔌 Status do GPIO:"
gpio readall

# Verificar configuração
echo -e "\n⚙️ Configuração DJI:"
cat /opt/psdk_servo_controller/config/dji_credentials.json | python3 -m json.tool

# Verificar logs
echo -e "\n📝 Últimos logs:"
journalctl -u psdk-servo -n 20 --no-pager
EOF

chmod +x ${INSTALL_DIR}/test_psdk.sh

# Criar script de monitoramento
log_info "📊 Criando script de monitoramento..."
cat > ${INSTALL_DIR}/monitor.sh << 'EOF'
#!/bin/bash
echo "📊 Monitoramento PSDK DJI em tempo real"
echo "Pressione Ctrl+C para sair"
echo "======================================"

# Monitorar logs em tempo real
journalctl -u psdk-servo -f
EOF

chmod +x ${INSTALL_DIR}/monitor.sh

# Configurar auto-start no boot
log_info "🚀 Configurando auto-start..."
cat > /etc/systemd/system/psdk-autostart.service << EOF
[Unit]
Description=PSDK DJI Auto-start
After=network.target
Before=psdk-servo.service

[Service]
Type=oneshot
User=${USER_NAME}
WorkingDirectory=${INSTALL_DIR}
ExecStart=/bin/bash -c 'sleep 10 && systemctl start psdk-servo'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable psdk-autostart.service

# Configurar watchdog para reiniciar em caso de falha
log_info "🔄 Configurando watchdog..."
cat > /etc/systemd/system/psdk-watchdog.service << EOF
[Unit]
Description=PSDK DJI Watchdog
After=psdk-servo.service

[Service]
Type=oneshot
User=${USER_NAME}
WorkingDirectory=${INSTALL_DIR}
ExecStart=/bin/bash -c 'while true; do if ! systemctl is-active --quiet psdk-servo; then systemctl restart psdk-servo; fi; sleep 30; done'

[Install]
WantedBy=multi-user.target
EOF

systemctl enable psdk-watchdog.service

# Configurar logrotate
log_info "📝 Configurando rotação de logs..."
cat > /etc/logrotate.d/psdk-servo << EOF
${INSTALL_DIR}/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ${USER_NAME} ${USER_NAME}
}
EOF

# Finalizar instalação
log_success "✅ Instalação concluída com sucesso!"
log_info "🎯 Próximos passos:"
log_info "   1. Reiniciar a Raspberry Pi: sudo reboot"
log_info "   2. Verificar status: sudo systemctl status psdk-servo"
log_info "   3. Testar sistema: sudo /opt/psdk_servo_controller/test_psdk.sh"
log_info "   4. Monitorar logs: sudo /opt/psdk_servo_controller/monitor.sh"

# Mostrar informações do sistema
echo ""
log_info "📊 Informações do sistema:"
echo "   Diretório de instalação: ${INSTALL_DIR}"
echo "   Serviço: ${SERVICE_NAME}"
echo "   Usuário: ${USER_NAME}"
echo "   Status: $(systemctl is-enabled ${SERVICE_NAME})"

log_success "🚁 PSDK DJI Servo Controller instalado e configurado!"
log_info "💡 Dica: O sistema iniciará automaticamente na próxima inicialização"
