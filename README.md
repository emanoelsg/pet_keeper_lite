# PetKeeper Lite

Um aplicativo Flutter para gerenciar pets em família, com sincronização em tempo real e notificações push.

## 🚀 Funcionalidades

- **Autenticação**: Login com email/senha e Google Sign-In
- **Gerenciamento de Pets**: CRUD completo de pets com fotos
- **Tarefas e Vacinas**: Agendamento e acompanhamento de cuidados
- **Compartilhamento Familiar**: Código de família para compartilhar pets
- **Notificações Push**: Avisos sobre tarefas e vacinas
- **Sincronização em Tempo Real**: Atualizações automáticas via Firestore
- **Upload de Fotos**: Armazenamento seguro no Firebase Storage

## 🏗️ Arquitetura

O projeto segue os princípios de **Clean Code** e **Feature-based Architecture**:

```
lib/
├── core/                    # Componentes compartilhados
│   ├── constants/          # Cores, estilos de texto
│   ├── utils/              # Validadores e utilitários
│   └── routes/             # Configuração de rotas
├── features/               # Funcionalidades organizadas por domínio
│   ├── auth/               # Autenticação
│   │   ├── models/         # Modelos de dados
│   │   ├── services/       # Serviços Firebase
│   │   ├── providers/      # Gerenciamento de estado (Riverpod)
│   │   └── screens/        # Telas de UI
│   ├── pets/               # Gerenciamento de pets
│   ├── pet_tasks/          # Tarefas e vacinas
│   └── family/             # Configurações familiares
└── main.dart               # Ponto de entrada da aplicação
```

## 🛠️ Tecnologias

- **Flutter**: Framework de desenvolvimento
- **Firebase**: Backend como serviço
  - Authentication (email/senha + Google)
  - Firestore (banco de dados)
  - Storage (upload de fotos)
  - Cloud Functions (notificações push)
  - Cloud Messaging (FCM)
- **Riverpod**: Gerenciamento de estado
- **Go Router**: Navegação
- **Image Picker**: Seleção de imagens

## 📱 Instalação e Configuração

### 1. Pré-requisitos

- Flutter SDK (versão 3.9.2 ou superior)
- Dart SDK
- Node.js (versão 20) para Cloud Functions
- Conta Firebase

### 2. Configuração do Firebase

1. **Criar projeto Firebase**:
   - Acesse [Firebase Console](https://console.firebase.google.com/)
   - Crie um novo projeto
   - Ative Authentication, Firestore, Storage e Cloud Functions

2. **Configurar Authentication**:
   - Vá em Authentication > Sign-in method
   - Ative Email/Password e Google Sign-In
   - Configure o Google Sign-In com seu projeto

3. **Configurar Firestore**:
   - Vá em Firestore Database
   - Crie o banco de dados
   - Configure as regras de segurança (use o arquivo `firestore.rules`)

4. **Configurar Storage**:
   - Vá em Storage
   - Configure as regras de segurança (use o arquivo `storage.rules`)

5. **Configurar Cloud Functions**:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

### 3. Configuração do Flutter

1. **Instalar dependências**:
   ```bash
   flutter pub get
   ```

2. **Configurar Firebase para Flutter**:
   - Execute `flutterfire configure` para gerar `firebase_options.dart`
   - Ou configure manualmente os arquivos de configuração

3. **Executar o aplicativo**:
   ```bash
   flutter run
   ```

## 🔧 Configuração de Desenvolvimento

### Firebase Emulators (Desenvolvimento Local)

Para desenvolvimento local com emuladores Firebase:

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login no Firebase
firebase login

# Inicializar emuladores
firebase emulators:start
```

### Estrutura de Dados

#### Coleções Firestore:

- **users/{uid}**: Dados do usuário
- **families/{familyCode}**: Dados da família
- **pets/{petId}**: Dados dos pets
- **pet_tasks/{taskId}**: Tarefas e vacinas

#### Storage:
- **pet_photos/{petId}.jpg**: Fotos dos pets

## 📋 Funcionalidades Implementadas

### ✅ Concluído

- [x] Estrutura de pastas e arquitetura
- [x] Modelos de dados (User, Family, Pet, PetTask)
- [x] Serviços Firebase (Auth, Firestore, Storage, Functions)
- [x] Providers Riverpod para gerenciamento de estado
- [x] Telas de autenticação (Login/Registro)
- [x] Navegação com Go Router
- [x] Configuração Firebase (regras, functions)
- [x] Validação de formulários
- [x] Tema e estilos personalizados

### 🚧 Em Desenvolvimento

- [ ] Telas de pets (lista, detalhes, CRUD)
- [ ] Telas de tarefas/vacinas
- [ ] Upload e exibição de fotos
- [ ] Notificações push
- [ ] Configurações de família

## 🎨 Design System

### Cores
- **Primária**: Verde (#2E7D32)
- **Secundária**: Laranja (#FF9800)
- **Fundo**: Cinza claro (#F5F5F5)
- **Superfície**: Branco (#FFFFFF)

### Tipografia
- **Títulos**: Roboto Bold
- **Corpo**: Roboto Regular
- **Botões**: Roboto Medium

## 🔒 Segurança

- Regras Firestore configuradas para isolamento por família
- Validação de dados no cliente e servidor
- Autenticação obrigatória para todas as operações
- Upload de fotos com validação de tipo e tamanho

## 📱 Próximos Passos

1. **Implementar telas de pets**:
   - Lista de pets com cards
   - Formulário de adição/edição
   - Detalhes do pet com foto

2. **Implementar telas de tarefas**:
   - Lista de tarefas por pet
   - Formulário de adição/edição
   - Marcação de conclusão

3. **Implementar notificações**:
   - Configuração de FCM
   - Notificações locais
   - Integração com Cloud Functions

4. **Implementar configurações**:
   - Perfil do usuário
   - Configurações da família
   - Gerenciamento de membros

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 📞 Suporte

Para suporte, entre em contato através de:
- Email: suporte@petkeeper.com
- Issues no GitHub

---

**PetKeeper Lite** - Cuidando dos seus pets com amor e tecnologia! 🐾