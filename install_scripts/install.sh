#!/bin/bash

# Script de instalação para Controlador de Servo PSDK DJI
# Raspberry Pi 4B

set -e

echo "=== Instalação do Controlador de Servo PSDK DJI ==="
echo "Plataforma: Raspberry Pi 4B"
echo "=================================================="

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "ERRO: Este script deve ser executado como root (sudo)"
    exit 1
fi

# Verificar se é Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo; then
    echo "AVISO: Este script foi projetado para Raspberry Pi"
    read -p "Continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Atualizar sistema
echo "Atualizando sistema..."
apt-get update
apt-get upgrade -y

# Instalar dependências
echo "Instalando dependências..."
apt-get install -y \
    build-essential \
    cmake \
    git \
    wiringpi \
    python3 \
    python3-pip \
    python3-dev \
    libgpiod-dev

# Instalar biblioteca Python para GPIO
echo "Instalando biblioteca Python GPIO..."
pip3 install RPi.GPIO

# Criar diretório de instalação
INSTALL_DIR="/opt/psdk_servo_controller"
echo "Criando diretório de instalação: $INSTALL_DIR"
mkdir -p $INSTALL_DIR

# Copiar arquivos
echo "Copiando arquivos..."
cp -r ../src $INSTALL_DIR/
cp -r ../python $INSTALL_DIR/
cp -r ../config $INSTALL_DIR/
cp ../CMakeLists.txt $INSTALL_DIR/
cp ../README.md $INSTALL_DIR/

# Configurar permissões
echo "Configurando permissões..."
chmod +x $INSTALL_DIR/python/servo_pwm.py
chown -R root:root $INSTALL_DIR

# Criar diretório de build
BUILD_DIR="$INSTALL_DIR/build"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Compilar projeto
echo "Compilando projeto..."
cmake ..
make -j$(nproc)

# Criar serviço systemd
echo "Criando serviço systemd..."
cat > /etc/systemd/system/psdk-servo.service << EOF
[Unit]
Description=PSDK Servo Controller
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$BUILD_DIR/psdk_servo_controller
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd
systemctl daemon-reload

# Habilitar serviço
echo "Habilitando serviço..."
systemctl enable psdk-servo.service

# Configurar GPIO
echo "Configurando GPIO..."
# Adicionar usuário ao grupo gpio
usermod -a -G gpio $SUDO_USER

# Configurar overlay de GPIO no boot
if ! grep -q "dtoverlay=gpio-no-irq" /boot/config.txt; then
    echo "dtoverlay=gpio-no-irq" >> /boot/config.txt
fi

# Criar script de teste
echo "Criando script de teste..."
cat > /usr/local/bin/test-servo << 'EOF'
#!/bin/bash
echo "Testando controlador de servo..."
cd /opt/psdk_servo_controller/python
python3 servo_pwm.py
EOF

chmod +x /usr/local/bin/test-servo

# Criar script de status
echo "Criando script de status..."
cat > /usr/local/bin/servo-status << 'EOF'
#!/bin/bash
echo "=== Status do Controlador de Servo ==="
systemctl status psdk-servo.service
echo ""
echo "=== Logs do Serviço ==="
journalctl -u psdk-servo.service -n 20 --no-pager
EOF

chmod +x /usr/local/bin/servo-status

# Configurar logrotate
echo "Configurando logrotate..."
cat > /etc/logrotate.d/psdk-servo << EOF
/var/log/psdk-servo.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

echo ""
echo "=== Instalação Concluída! ==="
echo ""
echo "Comandos úteis:"
echo "  Iniciar serviço: sudo systemctl start psdk-servo"
echo "  Parar serviço:   sudo systemctl stop psdk-servo"
echo "  Ver status:      sudo servo-status"
echo "  Testar servo:    sudo test-servo"
echo "  Ver logs:        sudo journalctl -u psdk-servo -f"
echo ""
echo "Configurações:"
echo "  Arquivo de config: /opt/psdk_servo_controller/config/config.json"
echo "  Executável:       /opt/psdk_servo_controller/build/psdk_servo_controller"
echo ""
echo "O serviço será iniciado automaticamente na próxima inicialização."
echo "Para iniciar agora: sudo systemctl start psdk-servo"
echo ""
echo "IMPORTANTE: Configure o arquivo config.json conforme suas necessidades!"
echo "=================================================="
