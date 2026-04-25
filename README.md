# SAD · Sistema de Avaliação de Desempenho

Sistema interno de avaliação de desempenho para a Itaurb, construído como PWA com Flutter/Web e backend em Firebase.

---

## Visão Geral

A plataforma permite que funcionários e gestores conduzam ciclos completos de avaliação de desempenho:

- **Autoavaliação** — cada funcionário responde seu próprio formulário de avaliação
- **Avaliação pelo gestor** — o gestor avalia cada membro de sua equipe
- **Comissão avaliadora** — validação e homologação dos resultados pelo presidente da comissão
- **Assinatura digital segura** — assinaturas capturadas com geolocalização, hash SHA-256 e metadados do dispositivo
- **Geração de PDFs** — emissão dos Anexos I ao XI diretamente pelo app
- **Central de ciclos** — gerenciamento dos ciclos avaliativos e encerramento de período
- **Central de impressão** — impressão em lote das avaliações com filtros por situação
- **Integração Google Sheets** — exportação de dados para planilhas via API

---

## Stack

| Camada | Tecnologia |
|---|---|
| Frontend/App | Flutter/Dart · Provider |
| Backend | Firebase Cloud Firestore · Firebase Storage |
| Autenticação | Login por matrícula + senha (hash SHA-256) |
| PDF | pdf · printing |
| Assinatura Digital | signature · geolocator · image\_picker · crypto |
| Google Sheets | googleapis · googleapis\_auth |
| Hospedagem | Firebase Hosting (`avaliacao-itaurb`) |

---

## Estrutura do Projeto

```
avaliacaopwa/
├── lib/
│   ├── main.dart                        # Entry point + inicialização Firebase
│   ├── firebase_options.dart            # Configuração do projeto Firebase
│   ├── models/                          # Entidades de domínio
│   │   ├── employee.dart
│   │   ├── evaluation.dart
│   │   ├── question.dart
│   │   └── ...
│   ├── providers/                       # Estado global (Provider)
│   │   ├── employee_provider.dart
│   │   └── evaluation_provider.dart
│   ├── screens/                         # Telas da aplicação
│   │   ├── login_matricula_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── dashboard_gestor_screen.dart
│   │   ├── autoavaliacao_screen.dart
│   │   ├── avaliacao_gestor_screen.dart
│   │   ├── gerenciar_comissao_screen.dart
│   │   ├── central_ciclos_screen.dart
│   │   ├── central_impressao_screen.dart
│   │   ├── assinatura_segura_screen.dart
│   │   ├── gestao_equipes_screen.dart
│   │   └── tabs/
│   ├── services/                        # Integração com serviços externos
│   │   ├── firebase_service.dart
│   │   ├── pdf_service.dart
│   │   └── google_sheets_service.dart
│   ├── utils/                           # Helpers e utilitários
│   └── widgets/                         # Componentes reutilizáveis
├── web/                                 # Assets da PWA (manifest, ícones)
├── assets/
│   ├── images/                          # Logo
│   └── sounds/                          # Efeitos sonoros
├── pubspec.yaml
└── firebase.json                        # Config Firebase Hosting
```

---

## Como Executar

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.8.1)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Acesso ao projeto Firebase `sad-edi`

### Desenvolvimento local

```bash
# Instalar dependências
flutter pub get

# Rodar no Chrome (PWA)
flutter run -d chrome

# Rodar com hot reload em modo web
flutter run -d web-server --web-port 8080
```

A aplicação estará disponível em `http://localhost:8080`.

### Build de produção

```bash
flutter build web --release
```

O build gerado fica em `build/web/`.

---

## Deploy

O deploy é feito via Firebase CLI para o site `avaliacao-itaurb`:

```bash
flutter build web --release
firebase deploy --only hosting
```

A aplicação estará disponível em:
```
https://avaliacao-itaurb.web.app
```

---

## Licença

Uso interno — Itaurb. Todos os direitos reservados.
