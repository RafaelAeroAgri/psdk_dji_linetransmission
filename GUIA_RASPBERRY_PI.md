# 🍓 Guia de Configuração Raspberry Pi 4B (Sem Desktop) - PSDK DJI

## 🎯 Visão Geral

Este guia te ajudará a configurar uma **Raspberry Pi 4B sem desktop** para executar automaticamente o **PSDK DJI Servo Controller** quando o drone for ligado.

### ✨ **O que será configurado:**

- ✅ **Sistema operacional** sem interface gráfica
- ✅ **PSDK DJI** instalado e configurado
- ✅ **Serviço systemd** para auto-start
- ✅ **Rede configurada** para comunicação com drone
- ✅ **GPIO configurado** para controle do servo
- ✅ **Botão automático** no DJI Pilot 2

## 🛠️ Requisitos

### 💻 **Hardware**
- **Raspberry Pi 4B** (2GB, 4GB ou 8GB RAM)
- **MicroSD** 16GB+ (classe 10 recomendado)
- **Servo Motor** (SG90, MG996R, ou similar)
- **Cabo USB-C** para alimentação
- **Drone DJI** compatível com PSDK

### 🔌 **Conexões**
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

## 🚀 Passo a Passo

### 1️⃣ **Preparar MicroSD**

#### **Opção A: Raspberry Pi Imager (Recomendado)**
1. Baixar [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Selecionar **"Raspberry Pi OS Lite"** (sem desktop)
3. Escolher microSD
4. Clicar em **"Write"**

#### **Opção B: Download Manual**
1. Baixar [Raspberry Pi OS Lite](https://www.raspberrypi.com/software/operating-systems/)
2. Usar [Balena Etcher](https://www.balena.io/etcher/) para gravar

### 2️⃣ **Configuração Inicial**

#### **Habilitar SSH e WiFi**
Após gravar a imagem, criar arquivo `wpa_supplicant.conf` na raiz do microSD:

```bash
# wpa_supplicant.conf
country=BR
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="SUA_REDE_WIFI"
    psk="SUA_SENHA_WIFI"
    key_mgmt=WPA-PSK
}
```

#### **Habilitar SSH**
Criar arquivo vazio `ssh` na raiz do microSD.

### 3️⃣ **Primeira Inicialização**

1. **Inserir microSD** na Raspberry Pi
2. **Conectar alimentação** USB-C
3. **Aguardar** 2-3 minutos para inicialização
4. **Verificar IP** no roteador ou usar:
   ```bash
   nmap -sn 192.168.1.0/24
   ```

### 4️⃣ **Conectar via SSH**

```bash
ssh pi@192.168.1.100
# Senha padrão: raspberry
```

### 5️⃣ **Configuração Básica**

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Configurar timezone
sudo raspi-config
# Localisation Options > Change Timezone > America/Sao_Paulo

# Expandir filesystem
sudo raspi-config
# Advanced Options > Expand Filesystem

# Alterar senha
passwd
```

### 6️⃣ **Configurar Rede Estática**

```bash
# Editar interfaces
sudo nano /etc/dhcpcd.conf

# Adicionar no final:
interface wlan0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8 8.8.4.4
```

### 7️⃣ **Transferir Projeto**

#### **Do seu computador:**
```bash
# Dar permissão ao script
chmod +x install_scripts/transfer_to_pi.sh

# Transferir (substitua pelo IP da sua Pi)
./install_scripts/transfer_to_pi.sh 192.168.1.100
```

#### **Ou manualmente via SCP:**
```bash
scp -r . pi@192.168.1.100:~/psdk_dji/
```

### 8️⃣ **Instalar PSDK DJI**

```bash
# Na Raspberry Pi
cd psdk_dji
sudo ./install_psdk_raspberry.sh
```

### 9️⃣ **Reiniciar e Testar**

```bash
sudo reboot

# Após reinicialização, conectar novamente
ssh pi@192.168.1.100

# Verificar status
sudo systemctl status psdk-servo

# Testar sistema
sudo /opt/psdk_servo_controller/test_psdk.sh
```

## 🔧 Configurações Avançadas

### **Configurar WiFi para Drone**

```bash
# Criar rede dedicada para drone
sudo nano /etc/network/interfaces.d/drone

# Adicionar:
auto wlan1
iface wlan1 inet static
    address 192.168.42.1
    netmask 255.255.255.0
    network 192.168.42.0
    broadcast 192.168.42.255
```

### **Configurar Hotspot**

```bash
# Instalar hostapd
sudo apt install hostapd dnsmasq

# Configurar hostapd
sudo nano /etc/hostapd/hostapd.conf

# Conteúdo:
interface=wlan1
driver=nl80211
ssid=PSDK_Drone_Controller
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=12345678
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
```

### **Configurar Firewall**

```bash
# Permitir porta PSDK DJI
sudo ufw allow 14550/udp

# Permitir SSH
sudo ufw allow 22/tcp

# Ativar firewall
sudo ufw enable
```

## 📊 Monitoramento

### **Verificar Status do Serviço**

```bash
# Status em tempo real
sudo systemctl status psdk-servo

# Logs em tempo real
sudo journalctl -u psdk-servo -f

# Últimos logs
sudo journalctl -u psdk-servo -n 50
```

### **Scripts de Monitoramento**

```bash
# Teste completo
sudo /opt/psdk_servo_controller/test_psdk.sh

# Monitoramento contínuo
sudo /opt/psdk_servo_controller/monitor.sh

# Verificar GPIO
gpio readall
```

## 🚨 Troubleshooting

### **Problemas Comuns**

#### **Serviço não inicia**
```bash
# Verificar logs
sudo journalctl -u psdk-servo -n 50

# Verificar dependências
sudo systemctl list-dependencies psdk-servo

# Reiniciar serviço
sudo systemctl restart psdk-servo
```

#### **GPIO não funciona**
```bash
# Verificar permissões
groups pi

# Adicionar ao grupo gpio
sudo usermod -a -G gpio pi

# Verificar regras udev
ls -la /etc/udev/rules.d/99-gpio.rules
```

#### **Rede não conecta**
```bash
# Verificar interfaces
ip addr show

# Verificar configuração WiFi
sudo iwconfig wlan0

# Reiniciar rede
sudo systemctl restart networking
```

#### **PSDK não conecta com drone**
```bash
# Verificar porta
sudo netstat -tulpn | grep 14550

# Verificar firewall
sudo ufw status

# Verificar logs PSDK
sudo journalctl -u psdk-servo -f
```

### **Logs de Debug**

```bash
# Habilitar debug
sudo systemctl stop psdk-servo
sudo /opt/psdk_servo_controller/build/psdk_servo_controller --debug

# Ver logs em tempo real
sudo journalctl -u psdk-servo -f --since "5 minutes ago"
```

## 🔄 Manutenção

### **Atualizações**

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Atualizar projeto
cd ~/psdk_dji
git pull origin main

# Reinstalar
sudo ./install_psdk_raspberry.sh
```

### **Backup**

```bash
# Backup da configuração
sudo cp -r /opt/psdk_servo_controller/config ~/backup_config

# Backup dos logs
sudo cp -r /opt/psdk_servo_controller/logs ~/backup_logs
```

### **Limpeza**

```bash
# Limpar logs antigos
sudo journalctl --vacuum-time=7d

# Limpar cache
sudo apt clean
sudo apt autoremove
```

## 📱 Teste com DJI Pilot 2

### **Verificar Botão**

1. **Ligar drone DJI**
2. **Conectar Raspberry Pi** (mesma rede)
3. **Abrir DJI Pilot 2**
4. **Verificar botão** "Controle Servo" na interface

### **Testar Funcionamento**

1. **Pressionar botão** no DJI Pilot 2
2. **Verificar movimento** do servo
3. **Verificar logs** na Raspberry Pi
4. **Confirmar resposta** em tempo real

## 🎯 Checklist Final

### ✅ **Configuração Básica**
- [ ] MicroSD com Raspberry Pi OS Lite
- [ ] SSH e WiFi configurados
- [ ] Rede estática configurada
- [ ] Sistema atualizado

### ✅ **Instalação PSDK**
- [ ] Projeto transferido para Pi
- [ ] Script de instalação executado
- [ ] Serviço systemd configurado
- [ ] GPIO configurado

### ✅ **Teste e Validação**
- [ ] Serviço inicia automaticamente
- [ ] GPIO responde corretamente
- [ ] PSDK conecta com drone
- [ ] Botão aparece no DJI Pilot 2

### ✅ **Produção**
- [ ] Sistema estável
- [ ] Logs configurados
- [ ] Monitoramento ativo
- [ ] Backup configurado

## 🚀 Próximos Passos

Após a configuração bem-sucedida:

1. **Testar** com drone real
2. **Ajustar** configurações conforme necessário
3. **Documentar** qualquer personalização
4. **Submeter** aplicativo para verificação DJI
5. **Expandir** funcionalidades

---

**🎉 Parabéns!** Sua Raspberry Pi 4B está configurada para controlar automaticamente o servo via PSDK DJI quando o drone for ligado! 🚁
