#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste Simples de Credenciais DJI
"""

import json
import os
from pathlib import Path

def main():
    print("Teste de Credenciais DJI")
    print("=" * 30)
    
    # Obter diretório raiz
    current_dir = Path(__file__).parent
    project_root = current_dir.parent
    
    print(f"Diretório atual: {current_dir}")
    print(f"Raiz do projeto: {project_root}")
    
    # Verificar arquivo de credenciais
    cred_file = project_root / "config" / "dji_credentials.json"
    print(f"Arquivo de credenciais: {cred_file}")
    print(f"Existe: {cred_file.exists()}")
    
    if cred_file.exists():
        try:
            with open(cred_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            print("\nCredenciais carregadas:")
            print(f"App Name: {data['dji_app']['app_name']}")
            print(f"App ID: {data['dji_app']['app_id']}")
            print(f"App Key: {data['dji_app']['app_key'][:8]}...")
            print(f"Status: {data['dji_app']['verification_status']}")
            
        except Exception as e:
            print(f"Erro ao carregar: {e}")
    else:
        print("Arquivo de credenciais não encontrado")

if __name__ == "__main__":
    main()
