# Instruções para Criar Repositório no GitHub

## Passo a Passo

### 1. Criar Repositório no GitHub

1. Acesse [GitHub.com](https://github.com) e faça login
2. Clique no botão "+" no canto superior direito
3. Selecione "New repository"
4. Configure o repositório:
   - **Repository name**: `psdk_dji`
   - **Description**: `Controlador de Servo via PSDK DJI para Raspberry Pi 4B`
   - **Visibility**: Public ou Private (sua escolha)
   - **NÃO** marque "Add a README file" (já temos um)
   - **NÃO** marque "Add .gitignore" (já temos um)
   - **NÃO** marque "Choose a license" (já temos um)
5. Clique em "Create repository"

### 2. Atualizar URL do Remote

Após criar o repositório, substitua `seu-usuario` pela sua verdadeira conta do GitHub:

```bash
git remote set-url origin https://github.com/SEU-USUARIO-REAL/psdk_dji.git
```

### 3. Fazer Push

```bash
git push -u origin master
```

### 4. Verificar

Acesse seu repositório no GitHub para confirmar que todos os arquivos foram enviados.

## Estrutura do Repositório

Após o push, seu repositório deve conter:

```
psdk_dji/
├── .gitignore
├── CMakeLists.txt
├── GUIA_CONFIGURACAO.md
├── INSTRUCOES_GITHUB.md
├── LICENSE
├── README.md
├── requirements.txt
├── config/
│   └── config.json
├── install_scripts/
│   └── install.sh
├── python/
│   └── servo_pwm.py
└── src/
    ├── main.cpp
    ├── servo_controller.cpp
    └── servo_controller.h
```

## Próximos Passos

1. **Configurar GitHub Pages** (opcional):
   - Vá em Settings > Pages
   - Source: Deploy from a branch
   - Branch: master
   - Folder: / (root)

2. **Adicionar Topics** (recomendado):
   - Vá em Settings > General
   - Adicione topics: `raspberry-pi`, `dji`, `psdk`, `servo`, `c++`, `python`

3. **Configurar Issues e Projects** (opcional):
   - Habilite Issues em Settings > Features
   - Configure templates para Issues e Pull Requests

## Comandos Úteis

```bash
# Verificar status
git status

# Verificar remote
git remote -v

# Fazer push de alterações futuras
git add .
git commit -m "Descrição das alterações"
git push

# Criar nova branch
git checkout -b feature/nova-funcionalidade

# Fazer merge
git checkout master
git merge feature/nova-funcionalidade
```

## Suporte

Se encontrar problemas:
1. Verifique se o repositório foi criado corretamente
2. Confirme se a URL do remote está correta
3. Verifique se você tem permissões de push
4. Consulte a documentação do GitHub
