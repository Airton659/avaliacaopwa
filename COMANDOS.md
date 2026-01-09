# 📝 Comandos Essenciais - SAD

## ⚡ Comandos Mais Usados

### Instalação e Configuração

```bash
# Instalar dependências
flutter pub get

# Configurar Firebase
flutterfire configure

# Verificar configuração
flutter doctor
```

### Desenvolvimento

```bash
# Executar em modo desenvolvimento (Chrome)
flutter run -d chrome

# Executar em modo desenvolvimento (Edge)
flutter run -d edge

# Executar com hot reload
flutter run -d chrome --hot

# Limpar build
flutter clean

# Atualizar dependências
flutter pub upgrade
```

### Build e Deploy

```bash
# Build para web (produção)
flutter build web --release

# Build com otimizações
flutter build web --release --web-renderer canvaskit

# Inicializar Firebase Hosting
firebase init hosting

# Deploy para Firebase
firebase deploy --only hosting

# Deploy completo (hosting + functions se houver)
firebase deploy
```

### Análise e Testes

```bash
# Analisar código
flutter analyze

# Corrigir formatação
dart format lib/

# Verificar dependências desatualizadas
flutter pub outdated

# Executar testes
flutter test
```

### Firebase

```bash
# Login no Firebase
firebase login

# Logout do Firebase
firebase logout

# Listar projetos
firebase projects:list

# Selecionar projeto
firebase use <project-id>

# Ver status
firebase projects:list
```

### Git (Controle de Versão)

```bash
# Inicializar repositório
git init

# Adicionar arquivos
git add .

# Commit
git commit -m "Implementação inicial do SAD"

# Ver status
git status

# Ver histórico
git log --oneline
```

---

## 🔧 Comandos de Manutenção

### Limpar Cache

```bash
# Limpar cache do Flutter
flutter clean

# Limpar cache do pub
flutter pub cache clean

# Limpar tudo e reinstalar
flutter clean && flutter pub get
```

### Atualizar Flutter

```bash
# Atualizar Flutter
flutter upgrade

# Verificar versão
flutter --version

# Mudar para canal estável
flutter channel stable
```

### Firestore (via Firebase CLI)

```bash
# Backup do Firestore
firebase firestore:export gs://[BUCKET_NAME]/[FOLDER]

# Restore do Firestore
firebase firestore:import gs://[BUCKET_NAME]/[FOLDER]
```

---

## 🐛 Debug e Troubleshooting

### Problemas Comuns

```bash
# Erro de permissão
flutter clean
flutter pub get

# Erro no Firestore
flutterfire configure --force

# Porta em uso
# Chrome: Feche todas as instâncias
taskkill /F /IM chrome.exe

# Verificar o que está rodando
flutter devices

# Matar processo específico
flutter clean
```

### Logs

```bash
# Ver logs em tempo real
flutter logs

# Ver logs do Chrome
# Abra DevTools (F12) no Chrome

# Ver logs do Firebase
firebase functions:log
```

---

## 📦 Gerenciamento de Pacotes

### Adicionar Pacote

```bash
# Adicionar pacote
flutter pub add nome_do_pacote

# Exemplo:
flutter pub add shared_preferences

# Remover pacote
flutter pub remove nome_do_pacote
```

### Atualizar Pacotes

```bash
# Atualizar todos
flutter pub upgrade

# Atualizar um específico
flutter pub upgrade nome_do_pacote

# Ver quais podem ser atualizados
flutter pub outdated
```

---

## 🌐 Web Específico

### Executar Web

```bash
# Chrome
flutter run -d chrome

# Edge
flutter run -d edge

# Com renderer específico
flutter run -d chrome --web-renderer html
flutter run -d chrome --web-renderer canvaskit

# Porta específica
flutter run -d chrome --web-port=8080
```

### Build Web

```bash
# Build básico
flutter build web

# Build otimizado
flutter build web --release

# Build com renderer HTML
flutter build web --web-renderer html

# Build com renderer CanvasKit
flutter build web --web-renderer canvaskit
```

---

## 🚀 Produção

### Checklist de Deploy

```bash
# 1. Limpar
flutter clean

# 2. Atualizar dependências
flutter pub get

# 3. Analisar código
flutter analyze

# 4. Build
flutter build web --release

# 5. Testar local
cd build/web
python -m http.server 8000
# Acesse: http://localhost:8000

# 6. Deploy
firebase deploy --only hosting
```

---

## 📱 Flutter DevTools

```bash
# Abrir DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Durante execução
# Pressione 'Shift + 2' no terminal
```

---

## 🔍 Comandos de Informação

```bash
# Versão do Flutter
flutter --version

# Configuração do Flutter
flutter config

# Informações do dispositivo
flutter devices

# Informações do projeto
flutter pub deps

# Árvore de dependências
flutter pub deps --tree
```

---

## 💾 Backup e Restore

### Backup do Código

```bash
# Git
git add .
git commit -m "Backup $(date +%Y-%m-%d)"
git push

# Arquivo ZIP
tar -czf sad_backup_$(date +%Y%m%d).tar.gz lib/ pubspec.yaml
```

### Backup do Firestore

```bash
# Via Firebase CLI
firebase firestore:export gs://seu-bucket/backups/$(date +%Y%m%d)

# Via Console
# Firebase Console > Firestore > Importar/Exportar
```

---

## 🎨 Personalização

### Modificar Assets

```bash
# Adicionar assets ao pubspec.yaml
# Depois executar:
flutter clean
flutter pub get
```

### Ícones e Splash Screen

```bash
# Instalar ferramenta
flutter pub add flutter_launcher_icons

# Gerar ícones
flutter pub run flutter_launcher_icons:main
```

---

## 📊 Performance

### Análise de Performance

```bash
# Profile mode
flutter run --profile

# Com timeline trace
flutter run --trace-startup
```

### Bundle Size

```bash
# Analisar tamanho
flutter build web --release --analyze-size

# Ver tamanho final
du -sh build/web
```

---

## 🔐 Segurança

### Regras do Firestore

```bash
# Deploy apenas regras
firebase deploy --only firestore:rules

# Testar regras localmente
firebase emulators:start --only firestore
```

---

## 📚 Documentação

### Gerar Documentação

```bash
# Documentação do código
dart doc .

# Abre no navegador
open doc/api/index.html
```

---

## ⌨️ Atalhos Durante Execução

```
r     - Hot reload
R     - Hot restart
h     - Help
d     - DevTools
c     - Limpar console
q     - Quit
```

---

## 🆘 Emergência

### Sistema Quebrado?

```bash
# Reset completo
flutter clean
rm -rf pubspec.lock
flutter pub get
flutter pub upgrade
flutter run -d chrome
```

### Firebase não funciona?

```bash
# Reconfigurar
flutterfire configure --force

# Verificar instalação
firebase --version
dart pub global list
```

---

**Dica:** Salve este arquivo para consulta rápida!

**Desenvolvido para:** Empresa de Desenvolvimento de Itabira
**Versão:** 1.0.0
