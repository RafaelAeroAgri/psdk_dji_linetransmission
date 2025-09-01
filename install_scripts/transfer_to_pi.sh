#!/bin/bash
# -*- coding: utf-8 -*-
"""
Script de Transferência para Raspberry Pi
Transfere todos os arquivos necessários para a Pi via SCP
"""

# Configurações
PI_IP="192.168.1.100"  # Altere para o IP da sua Pi
PI_USER="pi"
PROJECT_DIR="psdk_dji"
REMOTE_DIR="/home/pi/${PROJECT_DIR}"

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🚁 Transferindo PSDK DJI para Raspberry Pi"
echo "=========================================="

# Verificar se o IP foi fornecido
if [ "$1" != "" ]; then
    PI_IP="$1"
fi

log_info "IP da Raspberry Pi: ${PI_IP}"
log_info "Usuário: ${PI_USER}"
log_info "Diretório remoto: ${REMOTE_DIR}"

# Verificar conectividade
log_info "🔍 Testando conectividade com a Raspberry Pi..."
if ! ping -c 1 ${PI_IP} > /dev/null 2>&1; then
    log_error "Não foi possível conectar com ${PI_IP}"
    log_error "Verifique se:"
    log_error "  1. A Raspberry Pi está ligada"
    log_error "  2. Está na mesma rede WiFi"
    log_error "  3. O IP está correto"
    exit 1
fi

log_success "Conectividade OK!"

# Criar diretório remoto
log_info "📁 Criando diretório remoto..."
ssh ${PI_USER}@${PI_IP} "mkdir -p ${REMOTE_DIR}"

# Transferir arquivos principais
log_info "📋 Transferindo arquivos principais..."
scp -r config/ ${PI_USER}@${PI_IP}:${REMOTE_DIR}/
scp -r python/ ${PI_USER}@${PI_IP}:${REMOTE_DIR}/
scp -r src/ ${PI_USER}@${PI_IP}:${REMOTE_DIR}/
scp CMakeLists.txt ${PI_USER}@${PI_IP}:${REMOTE_DIR}/
scp requirements.txt ${PI_USER}@${PI_IP}:${REMOTE_DIR}/
scp README.md ${PI_USER}@${PI_IP}:${REMOTE_DIR}/
scp DJI_CREDENTIALS.md ${PI_USER}@${PI_IP}:${REMOTE_DIR}/

# Transferir scripts de instalação
log_info "🔧 Transferindo scripts de instalação..."
scp install_scripts/install_psdk_raspberry.sh ${PI_USER}@${PI_IP}:${REMOTE_DIR}/

# Dar permissão de execução
log_info "🔐 Configurando permissões..."
ssh ${PI_USER}@${PI_IP} "chmod +x ${REMOTE_DIR}/install_psdk_raspberry.sh"

# Verificar arquivos transferidos
log_info "✅ Verificando arquivos transferidos..."
ssh ${PI_USER}@${PI_IP} "ls -la ${REMOTE_DIR}/"

log_success "🎉 Transferência concluída com sucesso!"
echo ""
log_info "🎯 Próximos passos na Raspberry Pi:"
echo "   1. Conectar via SSH: ssh ${PI_USER}@${PI_IP}"
echo "   2. Navegar para o projeto: cd ${PROJECT_DIR}"
echo "   3. Executar instalação: sudo ./install_psdk_raspberry.sh"
echo "   4. Reiniciar: sudo reboot"
echo ""
log_info "💡 Dica: Após a instalação, o sistema iniciará automaticamente no boot"
