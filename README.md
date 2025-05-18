# MusicSheet Pro

<p align="center">
  <img src="https://via.placeholder.com/200x200.png?text=MSP" alt="MusicSheet Pro Logo"/>
</p>

<p align="center">
  Um aplicativo multiplataforma para gerenciar conteúdo musical (partituras, tablaturas e letras de músicas).
</p>

## 📋 Sobre o Projeto

MusicSheet Pro é uma solução digital completa para músicos, desenvolvida para substituir pastas físicas de partituras, tablaturas e letras de músicas. O aplicativo permite criar, importar, visualizar e gerenciar todo seu conteúdo musical de forma otimizada, além de oferecer ferramentas úteis como metrônomo e gerenciamento de setlists para apresentações.

Desenvolvido em Flutter, o aplicativo está disponível para Android, iOS e macOS.

## ✨ Funcionalidades

### 🎵 Gerenciamento de Biblioteca Musical

- Organize seu catálogo de músicas por título, artista ou tags personalizadas
- Marque suas músicas favoritas para acesso rápido
- Busca avançada em todo seu repertório

### 📝 Criação e Importação de Conteúdo

- **Entrada direta no app:**
  - Editor de letras e cifras com formatação automática
  - Editor de tablaturas simples para vários instrumentos
  - Suporte ao formato ChordPro (letras com acordes)

- **Importação de múltiplos formatos:**
  - PDFs de partituras e tablaturas
  - Imagens (JPG, PNG) de material escaneado
  - Formatos especializados (MusicXML, Guitar Pro, etc.)

### 👁️ Visualização Otimizada

- **Visualizador de partituras** com controles de zoom e anotações
- **Visualizador de tablaturas** com formatação especializada
- **Visualizador de letras/cifras** com rolagem automática e ajuste de fonte

### 📒 Anotações e Marcações

- Adicione anotações em qualquer ponto do conteúdo musical
- Personalize cores e estilos das anotações
- Organize e filtre suas anotações facilmente

### 📋 Gerenciamento de Setlists

- Crie setlists para ensaios e apresentações
- Organize a ordem das músicas com interface drag-and-drop
- Modo apresentação otimizado para performances ao vivo

### 🎸 Ferramentas Auxiliares

- Metrônomo integrado com controles de BPM e compasso
- Afinador para instrumentos diversos
- Biblioteca de referência para acordes

## 🔧 Tecnologias

- **Framework:** Flutter
- **Linguagem:** Dart
- **Banco de dados:** SQLite (via sqflite)
- **Gerenciamento de estado:** Provider
- **Injeção de dependências:** Get_it

## 🏗️ Arquitetura

O projeto segue uma arquitetura Clean Architecture com o padrão Repository, organizado em três camadas principais:

- **Presentation Layer:** UI e componentes visuais
- **Domain Layer:** Modelos de domínio e lógica de negócios
- **Data Layer:** Persistência e acesso a dados

## 📱 Screenshots

<p align="center">
  <img src="https://via.placeholder.com/200x400.png?text=Screen+1" alt="Tela da Biblioteca" width="200"/>
  <img src="https://via.placeholder.com/200x400.png?text=Screen+2" alt="Visualizador de Partituras" width="200"/>
  <img src="https://via.placeholder.com/200x400.png?text=Screen+3" alt="Editor de Conteúdo" width="200"/>
  <img src="https://via.placeholder.com/200x400.png?text=Screen+4" alt="Modo Apresentação" width="200"/>
</p>

## 🚀 Começando

### Pré-requisitos

- Flutter SDK (versão 3.0.0 ou superior)
- Dart SDK (versão 2.17.0 ou superior)
- Android Studio ou VS Code com plugins Flutter/Dart
- Git

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/your-username/music-sheet-pro.git
```

2. Navegue até o diretório do projeto:
```bash
cd music-sheet-pro
```

3. Instale as dependências:
```bash
flutter pub get
```

4. Execute o aplicativo:
```bash
flutter run
```

## 🗂️ Estrutura do Projeto

```
lib/
├── app/                  # Configuração do aplicativo
│   ├── app.dart
│   ├── routes.dart
│   └── theme.dart
├── core/                 # Modelos core e utilitários
│   ├── models/
│   ├── services/
│   └── utils/
├── data/                 # Camada de dados
│   ├── datasources/
│   ├── repositories/
│   └── converters/
├── domain/               # Camada de domínio
│   ├── repositories/
│   └── usecases/
├── presentation/         # Camada de apresentação
│   ├── common/           # Widgets compartilhados
│   ├── library/          # Telas da biblioteca
│   ├── editors/          # Editores de conteúdo
│   ├── viewers/          # Visualizadores especializados
│   ├── setlists/         # Gerenciamento de setlists
│   └── tools/            # Ferramentas auxiliares
└── main.dart             # Ponto de entrada do aplicativo
```

## 📝 Roadmap

- [ ] **v1.0.0:** Funcionalidades básicas (biblioteca, visualizadores, setlists)
- [ ] **v1.1.0:** Editores avançados de conteúdo
- [ ] **v1.2.0:** Anotações e marcações
- [ ] **v1.3.0:** Modo apresentação e metrônomo
- [ ] **v2.0.0:** Transposição de acordes e recursos avançados
- [ ] **v2.1.0:** Sincronização em nuvem
- [ ] **v2.2.0:** Colaboração entre usuários

## 🤝 Contribuindo

Contribuições são bem-vindas! Se você gostaria de contribuir com este projeto:

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/amazing-feature`)
3. Faça commit de suas mudanças (`git commit -m 'Add some amazing feature'`)
4. Faça push para a branch (`git push origin feature/amazing-feature`)
5. Abra um Pull Request

Por favor, leia o [CONTRIBUTING.md](CONTRIBUTING.md) para detalhes sobre nosso código de conduta e o processo de submissão de pull requests.

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE.md](LICENSE.md) para detalhes.

## 👥 Autores

- **Seu Nome** - *Desenvolvedor principal* - [GitHub](https://github.com/your-username)

## 🙏 Agradecimentos

- Todos os músicos que testaram o aplicativo
- A comunidade Flutter por suas excelentes bibliotecas
- Ícones por [Feather Icons](https://feathericons.com/)

---

<p align="center">
  Desenvolvido com ❤️ para músicos de todos os níveis
</p>
