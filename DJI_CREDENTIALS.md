# 🔑 Credenciais DJI PSDK - lancamento_cabo

## 📱 Informações do Aplicativo

| Campo | Valor |
|-------|-------|
| **Nome do App** | `lancamento_cabo` |
| **App ID** | `169427` |
| **App Key** | `81e159bcf9efda885569fd05255eb67` |
| **App Basic License** | `KevEHH4XSa9t/EmNehARLeP4JTSTPTWD8gfvMkaZLuVN+MG7HpgY3TFL6TgFSr0nkp6/JPmO3wPPuBfdxFf4kdEfElbXIZ5HoiCfla7e0Yiq/Lv3NDhBEg5MwVhCCDbQ4Guk46YagrTU16hyTTcaKa5OEUQX6tjUUFqZIbeiPoWaL2DDGCd9HxyFEm0pAzIonOTHtYFbr2PP1Miehdg/AVzE4KWAco84Cm96CWN61Dv6SMTqjkA2H22I2TwpSe2uvVYZo2Cf7h8M86uhX6dK5ILkjdjFDzq1ScfRrDrFijlyAYWI0hto+EQCojnBivP0Bbnzu5SPFwrTukpTnZct3w==` |
| **Status** | `accepted` |
| **Verificação** | `Not Verified` |
| **Limite de Dispositivos** | `20` |

## ⚠️ Status de Verificação

**IMPORTANTE**: Seu aplicativo está com status **"Not Verified"**, o que significa:

- ✅ **Aceito** para desenvolvimento e testes
- ❌ **Limitado** a máximo de 20 dispositivos
- 🔒 **Não pode** ser distribuído em produção
- 📝 **Precisa** passar pela verificação DJI

## 🚀 Como Usar no Projeto

### 1. **Arquivo de Configuração Principal**
As credenciais já estão configuradas em `config/config.json`:

```json
{
  "psdk": {
    "app_name": "lancamento_cabo",
    "app_id": "169427",
    "app_key": "81e159bcf9efda885569fd05255eb67",
    "button_id": "servo_toggle",
    "button_name": "Controle Servo",
    "button_description": "Alterna posição do servo para lançamento de cabo"
  }
}
```

### 2. **Arquivo de Credenciais Específico**
Credenciais completas em `config/dji_credentials.json`:

```json
{
  "dji_app": {
    "app_name": "lancamento_cabo",
    "app_id": "169427",
    "app_key": "81e159bcf9efda885569fd05255eb67",
    "app_basic_license": "KevEHH4XSa9t/EmNehARLeP4JTSTPTWD8gfvMkaZLuVN+MG7HpgY3TFL6TgFSr0nkp6/JPmO3wPPuBfdxFf4kdEfElbXIZ5HoiCfla7e0Yiq/Lv3NDhBEg5MwVhCCDbQ4Guk46YagrTU16hyTTcaKa5OEUQX6tjUUFqZIbeiPoWaL2DDGCd9HxyFEm0pAzIonOTHtYFbr2PP1Miehdg/AVzE4KWAco84Cm96CWN61Dv6SMTqjkA2H22I2TwpSe2uvVYZo2Cf7h8M86uhX6dK5ILkjdjFDzq1ScfRrDrFijlyAYWI0hto+EQCojnBivP0Bbnzu5SPFwrTukpTnZct3w=="
  }
}
```

### 3. **Testar Credenciais**
Execute o script de teste:

```bash
cd python
python3 test_dji_connection.py
```

## 🔧 Integração com PSDK

### **Código C++ (src/main.cpp)**
```cpp
// Configurações DJI
const char* APP_NAME = "lancamento_cabo";
const char* APP_ID = "169427";
const char* APP_KEY = "81e159bcf9efda885569fd05255eb67";

// Inicializar PSDK
T_DjiReturnCode returnCode = DjiCore_Init(APP_NAME, APP_ID, APP_KEY);
if (returnCode != DJI_ERROR_SYSTEM_MODULE_CODE_SUCCESS) {
    // Tratar erro
}
```

### **Código Python (python/servo_pwm.py)**
```python
# Carregar configurações DJI
with open('../config/config.json', 'r') as f:
    config = json.load(f)
    
app_name = config['psdk']['app_name']
app_id = config['psdk']['app_id']
app_key = config['psdk']['app_key']
```

## 📋 Checklist de Implementação

### ✅ **Configuração Básica**
- [x] Credenciais configuradas em `config.json`
- [x] Arquivo de credenciais específico criado
- [x] Script de teste implementado
- [x] Documentação atualizada

### 🔄 **Próximos Passos**
- [ ] Instalar PSDK DJI no Raspberry Pi
- [ ] Implementar código C++ com credenciais
- [ ] Testar conexão com drone real
- [ ] Verificar botão no DJI Pilot 2
- [ ] Submeter aplicativo para verificação DJI

## 🚨 Limitações Atuais

### **Status "Not Verified"**
- **Máximo de 20 dispositivos** para testes
- **Não pode ser distribuído** em produção
- **Precisa passar** pela verificação DJI

### **Processo de Verificação**
1. **Desenvolver** e testar completamente
2. **Documentar** funcionalidades
3. **Submeter** para revisão DJI
4. **Aguardar** aprovação
5. **Receber** status "Verified"

## 🔐 Segurança

### **Proteção de Credenciais**
- ✅ **NÃO** commitar credenciais no Git
- ✅ **NÃO** compartilhar App Key publicamente
- ✅ **Usar** variáveis de ambiente em produção
- ✅ **Rotacionar** chaves regularmente

### **Exemplo de .env (Produção)**
```bash
DJI_APP_NAME=lancamento_cabo
DJI_APP_ID=169427
DJI_APP_KEY=81e159bcf9efda885569fd05255eb67
DJI_APP_LICENSE=KevEHH4XSa9t/EmNehARLeP4JTSTPTWD8gfvMkaZLuVN+MG7HpgY3TFL6TgFSr0nkp6/JPmO3wPPuBfdxFf4kdEfElbXIZ5HoiCfla7e0Yiq/Lv3NDhBEg5MwVhCCDbQ4Guk46YagrTU16hyTTcaKa5OEUQX6tjUUFqZIbeiPoWaL2DDGCd9HxyFEm0pAzIonOTHtYFbr2PP1Miehdg/AVzE4KWAco84Cm96CWN61Dv6SMTqjkA2H22I2TwpSe2uvVYZo2Cf7h8M86uhX6dK5ILkjdjFDzq1ScfRrDrFijlyAYWI0hto+EQCojnBivP0Bbnzu5SPFwrTukpTnZct3w==
```

## 📞 Suporte

### **Problemas com Credenciais**
1. Verificar se App ID e Key estão corretos
2. Confirmar se aplicativo está "accepted"
3. Verificar limite de dispositivos (20)
4. Contatar suporte DJI se necessário

### **Links Úteis**
- [DJI Developer Portal](https://developer.dji.com/)
- [PSDK Documentation](https://developer.dji.com/payload-sdk)
- [App Verification Process](https://developer.dji.com/verification)

---

**Última atualização**: Configuração completa das credenciais DJI para o projeto `lancamento_cabo`
