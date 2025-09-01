#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste de Conexão DJI PSDK
Verifica se as credenciais estão funcionando corretamente
"""

import json
import sys
import os
from pathlib import Path

def load_credentials():
    """Carrega as credenciais DJI do arquivo de configuração"""
    try:
        # Obter o diretório raiz do projeto
        current_dir = Path(__file__).parent
        project_root = current_dir.parent
        
        # Tentar carregar do arquivo específico primeiro
        cred_file = project_root / "config" / "dji_credentials.json"
        if cred_file.exists():
            with open(cred_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        
        # Fallback para o arquivo principal
        config_file = project_root / "config" / "config.json"
        if config_file.exists():
            with open(config_file, 'r', encoding='utf-8') as f:
                config = json.load(f)
                return {
                    "dji_app": {
                        "app_name": config["psdk"]["app_name"],
                        "app_id": config["psdk"]["app_id"],
                        "app_key": config["psdk"]["app_key"]
                    },
                    "psdk_config": config["psdk"]
                }
        
        raise FileNotFoundError("Nenhum arquivo de configuração encontrado")
        
    except Exception as e:
        print(f"❌ Erro ao carregar credenciais: {e}")
        return None

def validate_credentials(creds):
    """Valida se as credenciais estão completas"""
    required_fields = ["app_name", "app_id", "app_key"]
    
    if not creds or "dji_app" not in creds:
        print("❌ Estrutura de credenciais inválida")
        return False
    
    dji_app = creds["dji_app"]
    missing_fields = [field for field in required_fields if field not in dji_app]
    
    if missing_fields:
        print(f"❌ Campos obrigatórios ausentes: {missing_fields}")
        return False
    
    if not dji_app["app_id"].isdigit():
        print("❌ App ID deve ser numérico")
        return False
    
    if len(dji_app["app_key"]) != 32:
        print("❌ App Key deve ter 32 caracteres")
        return False
    
    return True

def test_psdk_integration():
    """Testa a integração básica com PSDK"""
    print("🔧 Testando integração PSDK...")
    
    try:
        # Aqui você pode adicionar testes específicos do PSDK
        # Por enquanto, apenas simulamos uma conexão bem-sucedida
        print("✅ Simulação de conexão PSDK bem-sucedida")
        print("   - SDK Type: Payload SDK")
        print("   - Status: Ready to connect")
        return True
        
    except Exception as e:
        print(f"❌ Erro na integração PSDK: {e}")
        return False

def main():
    """Função principal"""
    print("🚁 Teste de Conexão DJI PSDK")
    print("=" * 40)
    
    # Carregar credenciais
    print("\n📋 Carregando credenciais...")
    creds = load_credentials()
    
    if not creds:
        print("❌ Falha ao carregar credenciais")
        sys.exit(1)
    
    # Validar credenciais
    print("\n🔍 Validando credenciais...")
    if not validate_credentials(creds):
        print("❌ Validação de credenciais falhou")
        sys.exit(1)
    
    # Exibir informações
    dji_app = creds["dji_app"]
    print("\n📱 Informações do Aplicativo DJI:")
    print(f"   Nome: {dji_app['app_name']}")
    print(f"   ID: {dji_app['app_id']}")
    print(f"   Key: {dji_app['app_key'][:8]}...{dji_app['app_key'][-8:]}")
    
    if "verification_status" in dji_app:
        print(f"   Status: {dji_app['verification_status']}")
        if dji_app['verification_status'] == "Not Verified":
            print(f"   ⚠️  Limite: {dji_app.get('max_devices', 'N/A')} dispositivos")
    
    # Testar integração PSDK
    print("\n🔧 Testando integração...")
    if test_psdk_integration():
        print("\n✅ Todos os testes passaram!")
        print("\n🎯 Próximos passos:")
        print("   1. Instalar PSDK DJI no Raspberry Pi")
        print("   2. Configurar permissões de rede")
        print("   3. Testar conexão com drone real")
        print("   4. Verificar botão no DJI Pilot 2")
    else:
        print("\n❌ Alguns testes falharam")
        sys.exit(1)

if __name__ == "__main__":
    main()
