<<<<<<< HEAD
# music_sheet_pro
Um aplicativo para gerenciar partituras e tablaturas musicais
=======
# Documentação do MusicSheet Pro

## 1. Visão Geral do Projeto

### 1.1 Descrição

O MusicSheet Pro é um aplicativo multiplataforma desenvolvido em Flutter para gerenciar conteúdo musical (partituras, tablaturas e letras de músicas), projetado para substituir pastas físicas de material impresso. O aplicativo permite aos músicos organizar, visualizar e anotar seu conteúdo musical digitalmente, além de criar e gerenciar setlists para ensaios e apresentações ao vivo.

### 1.2 Objetivos Principais

- Substituir pastas físicas de conteúdo musical com uma solução digital intuitiva
- Oferecer visualização otimizada para diferentes tipos de conteúdo musical (partituras, tablaturas, letras)
- Possibilitar entrada direta de conteúdo no app, além de importação de arquivos
- Facilitar a organização e acesso ao material durante ensaios e apresentações
- Permitir anotações personalizadas no conteúdo musical
- Oferecer ferramentas auxiliares para músicos, como metrônomo
- Suportar múltiplas plataformas (Android, iOS, macOS)

### 1.3 Público-Alvo

- Músicos profissionais e amadores
- Bandas e grupos musicais
- Estudantes de música
- Educadores musicais

## 2. Arquitetura do Sistema

### 2.1 Abordagem Arquitetural

O MusicSheet Pro segue uma arquitetura Clean Architecture com o padrão Repository, garantindo:

- Separação clara entre camadas de UI, lógica de negócios e dados
- Testabilidade e manutenibilidade aprimoradas
- Flexibilidade para mudanças em requisitos e tecnologias

### 2.2 Camadas da Arquitetura

1. **Presentation Layer (UI)**
   - Screens e Widgets em Flutter
   - Visualizadores especializados para partituras, tablaturas e letras
   - Componentes de edição e entrada de conteúdo musical

2. **Domain Layer (Lógica de Negócios)**
   - Modelos de domínio (Music, MusicContent, Setlist)
   - Interfaces de repositórios
   - Casos de uso e regras de negócio

3. **Data Layer (Dados)**
   - Implementações de repositórios
   - Fontes de dados locais (SQLite via sqflite)
   - Converters para diferentes formatos de conteúdo musical

### 2.3 Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                       Presentation Layer                     │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Library    │  │  Content    │  │  Setlists           │  │
│  │  Screens    │  │  Viewers    │  │  Screens            │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Editors    │  │  Metronome  │  │  Common Components  │  │
│  │  Component  │  │  Component  │  │  (Dialogs, etc.)    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                         Domain Layer                        │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Music      │  │  Setlist    │  │  Annotation         │  │
│  │  Models     │  │  Models     │  │  Models             │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Repository │  │  Repository │  │  Repository         │  │
│  │  Interfaces │  │  Interfaces │  │  Interfaces         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                          Data Layer                         │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  SQLite     │  │  Content    │  │  Repository         │  │
│  │  Database   │  │  Converters │  │  Implementations    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 3. Modelos de Dados

### 3.1 Entidades Principais

#### 3.1.1 Music
Representa uma música ou composição musical.
```dart
class Music {
  final String id;
  final String title;
  final String artist;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  
  // Métodos de serialização/desserialização
}
```

#### 3.1.2 MusicContent
Representa o conteúdo associado a uma música (partitura, tablatura, letra).
```dart
enum ContentType { lyrics, tablature, sheetMusic, plainText }
enum ContentFormat { pdf, image, text, chordPro, musicXml }

class MusicContent {
  final String id;
  final String musicId;
  final ContentType type;
  final ContentFormat format;
  final String content; // Caminho do arquivo ou conteúdo direto (texto)
  final bool isFilePath; // Indica se content é um caminho de arquivo
  final int version;
  
  // Métodos de serialização/desserialização
}
```

#### 3.1.3 Setlist
Representa uma lista ordenada de músicas para uma apresentação ou ensaio.
```dart
class Setlist {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Métodos de serialização/desserialização
}
```

#### 3.1.4 Annotation
Representa uma anotação feita no conteúdo musical.
```dart
class Annotation {
  final String id;
  final String contentId;
  final String text;
  final int pageOrPosition; // Página/posição no conteúdo
  final double x;
  final double y;
  final String color;
  final DateTime createdAt;
  
  // Métodos de serialização/desserialização
}
```

### 3.2 Esquema do Banco de Dados

#### 3.2.1 Tabela musics
```sql
CREATE TABLE musics(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  tags TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  isFavorite INTEGER NOT NULL
)
```

#### 3.2.2 Tabela music_contents
```sql
CREATE TABLE music_contents(
  id TEXT PRIMARY KEY,
  musicId TEXT NOT NULL,
  type INTEGER NOT NULL,
  format INTEGER NOT NULL,
  content TEXT NOT NULL,
  isFilePath INTEGER NOT NULL,
  version INTEGER NOT NULL,
  FOREIGN KEY (musicId) REFERENCES musics (id) ON DELETE CASCADE
)
```

#### 3.2.3 Tabela setlists
```sql
CREATE TABLE setlists(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
)
```

#### 3.2.4 Tabela setlist_music
```sql
CREATE TABLE setlist_music(
  setlistId TEXT NOT NULL,
  musicId TEXT NOT NULL,
  orderIndex INTEGER NOT NULL,
  PRIMARY KEY (setlistId, musicId),
  FOREIGN KEY (setlistId) REFERENCES setlists (id) ON DELETE CASCADE,
  FOREIGN KEY (musicId) REFERENCES musics (id) ON DELETE CASCADE
)
```

#### 3.2.5 Tabela annotations
```sql
CREATE TABLE annotations(
  id TEXT PRIMARY KEY,
  contentId TEXT NOT NULL,
  text TEXT NOT NULL,
  pageOrPosition INTEGER NOT NULL,
  x REAL NOT NULL,
  y REAL NOT NULL,
  color TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  FOREIGN KEY (contentId) REFERENCES music_contents (id) ON DELETE CASCADE
)
```

## 4. Funcionalidades Principais

### 4.1 Gerenciamento de Biblioteca Musical

- Adicionar, editar e excluir músicas
- Organizar por título, artista ou tags
- Marcar músicas como favoritas
- Pesquisar no catálogo musical

### 4.2 Criação e Importação de Conteúdo Musical

- **Entrada Direta de Conteúdo**:
  - Editor de texto para letras de músicas
  - Editor de acordes para cifras e tablaturas simples
  - Suporte para formato ChordPro (letras com acordes)

- **Importação de Arquivos**:
  - Suporte para PDFs de partituras e tablaturas
  - Importação de imagens (JPG, PNG) de partituras escaneadas
  - Importação de formatos específicos (MusicXML, Guitar Pro, etc.)
  - Conversão automática para formato otimizado para visualização

### 4.3 Visualização Otimizada de Conteúdo

- **Visualizador de Partituras**:
  - Renderização otimizada para tela do dispositivo
  - Controles de zoom e navegação
  - Ajuste automático de orientação (retrato/paisagem)

- **Visualizador de Tablaturas**:
  - Formatação especial para facilitar leitura
  - Destaque para seções e compassos

- **Visualizador de Letras/Cifras**:
  - Formatação clara com acordes alinhados
  - Opção de autoscroll durante apresentação
  - Ajuste de tamanho de fonte e espaçamento

### 4.4 Anotações no Conteúdo Musical

- Adicionar anotações em locais específicos
- Personalizar cor e tamanho das anotações
- Visualizar e gerenciar anotações existentes
- Filtrar anotações por tipo ou seção

### 4.5 Gerenciamento de Setlists

- Criar e editar setlists para ensaios e apresentações
- Adicionar músicas às setlists
- Reordenar músicas com drag-and-drop
- Exportar e compartilhar setlists

### 4.6 Modo Apresentação

- Interface otimizada para uso durante performances
- Navegação fácil entre músicas de uma setlist
- Manter a tela ativa durante o uso
- Rolagem automática configurável para letras e cifras

### 4.7 Ferramentas Auxiliares

- Metrônomo integrado com controles de BPM e compasso
- Afinador para instrumentos
- Biblioteca de acordes para referência rápida

## 5. Interface do Usuário

### 5.1 Estrutura de Navegação

O aplicativo utiliza uma navegação baseada em abas na tela principal, com navegação de pilha (stack) para telas detalhadas:

1. **Aba Biblioteca**: Lista de músicas e pesquisa
2. **Aba Setlists**: Gerenciamento de setlists
3. **Aba Ferramentas**: Metrônomo, afinador e outras ferramentas

As telas detalhadas incluem:
- **Visualizadores Especializados**: Para partituras, tablaturas e letras
- **Editores de Conteúdo**: Para criar e editar conteúdo musical
- **Modo Apresentação**: Para performances ao vivo
- **Editor de Música/Setlist**: Para adicionar/editar itens

### 5.2 Temas e Estilo Visual

- Suporte a temas claro e escuro
- Paleta de cores primária: Material Purple (#6200EE)
- Paleta de cores secundária: Material Teal (#03DAC5)
- Tipografia baseada em Material Design com fonte Roboto
- Utilização de ícones intuitivos para músicos

### 5.3 Exemplos de Telas Principais

1. **Tela da Biblioteca**
   - Lista de músicas com filtros e busca
   - Acesso rápido a favoritos
   - Indicadores de tipo de conteúdo disponível

2. **Tela de Criação/Edição de Conteúdo**
   - Opções para diferentes tipos de conteúdo
   - Editor de texto com formatação para letras e cifras
   - Interface para importação de arquivos

3. **Tela de Visualização de Conteúdo**
   - Controles adaptados ao tipo de conteúdo
   - Ferramentas de anotação
   - Modo de tela cheia

4. **Tela de Gerenciamento de Setlists**
   - Lista de setlists existentes
   - Interface de drag-and-drop para ordenação
   - Botão para iniciar o Modo Apresentação

## 6. Visualizadores Especializados

### 6.1 Visualizador de Partituras

- Renderização de alta qualidade para partituras em formato PDF e imagem
- Controles de zoom e navegação otimizados para leitura musical
- Suporte para anotações em locais específicos da partitura
- Ajuste automático de orientação para melhor visualização

### 6.2 Visualizador de Tablaturas

- Formatação especializada para tablaturas de guitarra, baixo, etc.
- Destaque para diferentes elementos (acordes, notas, técnicas)
- Opção de visualização simplificada para leitura rápida
- Suporte para formatos comuns de tablatura

### 6.3 Visualizador de Letras e Cifras

- Formatação clara com alinhamento de acordes sobre as letras
- Opções de estilo (tamanho de fonte, espaçamento, destaque)
- Rolagem automática configurável para apresentações
- Suporte para formato ChordPro e outros formatos de cifra

### 6.4 Características Comuns

- Anotações personalizáveis em todos os tipos de conteúdo
- Modo noturno para uso em ambientes com pouca luz
- Controles de navegação consistentes entre os visualizadores
- Opções de compartilhamento e exportação

## 7. Edição e Criação de Conteúdo

### 7.1 Editor de Letras e Cifras

- Interface intuitiva para entrada de texto
- Formatação automática de acordes sobre as letras
- Sugestão de acordes comuns durante a digitação
- Visualização em tempo real do resultado

### 7.2 Editor de Tablaturas Simples

- Interface para criar tablaturas básicas
- Suporte para diferentes afinações e instrumentos
- Ferramentas para adicionar técnicas comuns (slides, bends, etc.)
- Exportação para formato otimizado de visualização

### 7.3 Importação e Conversão

- Suporte para importação de diferentes formatos:
  - PDFs de partituras e tablaturas
  - Imagens (JPG, PNG) de material escaneado
  - Formatos de texto para letras e cifras
  - Formatos especializados como MusicXML, Guitar Pro, etc.
- Conversão automática para formato otimizado quando possível
- Processamento de OCR para extrair texto de imagens (opcional)

## 8. Armazenamento e Gerenciamento de Conteúdo

### 8.1 Estratégias de Armazenamento

- **Conteúdo Baseado em Texto**:
  - Armazenado diretamente no banco de dados
  - Formato otimizado para edição e visualização

- **Conteúdo Baseado em Arquivos**:
  - Armazenado no diretório do aplicativo
  - Indexado no banco de dados para rápido acesso
  - Otimizado para visualização quando possível

### 8.2 Estrutura de Armazenamento

```
AppDocumentsDirectory/
├── sheet_music/
│   ├── [UUID1].pdf
│   ├── [UUID2].png
│   └── ...
├── tablatures/
│   ├── [UUID3].gp
│   ├── [UUID4].xml
│   └── ...
└── cached/
    ├── [UUID5].json
    └── ...
```

### 8.3 Converters e Parsers

- Conversores para diferentes formatos de conteúdo musical
- Parsers para formatos especializados (ChordPro, MusicXML, etc.)
- Geradores de visualização otimizada a partir dos dados originais

## 9. Desafios Técnicos e Soluções

### 9.1 Visualização Otimizada de Diferentes Formatos

**Desafio**: Criar visualizadores especializados para diferentes tipos de conteúdo musical.

**Solução**:
- Implementação de renderers customizados para cada tipo de conteúdo
- Uso de bibliotecas especializadas quando disponíveis
- Estratégias de caching para melhorar performance
- Interface unificada para diferentes tipos de visualizadores

### 9.2 Entrada e Edição de Conteúdo

**Desafio**: Permitir criação e edição de diversos tipos de conteúdo musical diretamente no app.

**Solução**:
- Editores especializados para cada tipo de conteúdo
- Validação em tempo real do conteúdo
- Armazenamento intermediário para evitar perda de dados
- Previsualização durante edição

### 9.3 Conversão entre Formatos

**Desafio**: Converter conteúdo entre diferentes formatos mantendo fidelidade.

**Solução**:
- Implementação de conversores específicos para cada par de formatos
- Uso de formatos intermediários para conversões complexas
- Fallback para visualização original quando conversão não é possível
- Feedback claro ao usuário sobre limitações de conversão

### 9.4 Persistência e Indexação

**Desafio**: Armazenar e indexar eficientemente diferentes tipos de conteúdo.

**Solução**:
- Esquema de banco de dados flexível
- Armazenamento híbrido (BD + sistema de arquivos)
- Indexação de metadados para busca rápida
- Estratégias de caching para conteúdo frequentemente acessado

## 10. Tecnologias e Dependências

### 10.1 Framework e Linguagem

- **Flutter**: Framework multiplataforma para desenvolvimento de UI
- **Dart**: Linguagem de programação

### 10.2 Principais Dependências

#### 10.2.1 Persistência e Dados
- **sqflite**: Acesso a banco de dados SQLite
- **path_provider**: Acesso a diretórios do sistema
- **shared_preferences**: Armazenamento de configurações simples

#### 10.2.2 Visualização de Conteúdo
- **syncfusion_flutter_pdfviewer**: Visualização de PDFs
- **flutter_markdown**: Renderização de conteúdo em Markdown
- **extended_text**: Texto avançado com formatação personalizada
- **photo_view**: Visualização de imagens com zoom

#### 10.2.3 Edição de Conteúdo
- **flutter_quill**: Editor de texto rico
- **chord_editor**: (Biblioteca customizada) Editor de cifras e acordes

#### 10.2.4 Gerenciamento de Estado e Dependências
- **provider**: Gerenciamento de estado
- **get_it**: Injeção de dependências

#### 10.2.5 Importação e Exportação
- **file_picker**: Seleção de arquivos
- **permission_handler**: Gerenciamento de permissões
- **image_picker**: Seleção de imagens

#### 10.2.6 Utilitários
- **uuid**: Geração de identificadores únicos
- **intl**: Internacionalização e formatação
- **wakelock**: Controle de suspensão de tela
- **audioplayers**: Reprodução de áudio para o metrônomo

## 11. Fluxos de Usuário

### 11.1 Fluxo de Adição de Nova Música

1. Usuário acessa a tela "Adicionar Música"
2. Insere metadados (título, artista, tags)
3. Escolhe o tipo de conteúdo a adicionar:
   - Letras (entrada direta via editor)
   - Cifras/Tablaturas (entrada via editor especializado)
   - Partitura/Tablatura (importação de arquivo)
4. Sistema salva os metadados e o conteúdo
5. Usuário é redirecionado para a visualização da música

### 11.2 Fluxo de Visualização de Conteúdo

1. Usuário seleciona uma música na biblioteca
2. Sistema detecta o tipo de conteúdo associado à música
3. Sistema carrega o visualizador apropriado:
   - Visualizador de partituras para PDFs/imagens
   - Visualizador de tablaturas para tablaturas
   - Visualizador de letras/cifras para texto
4. Usuário interage com o conteúdo (zoom, navegação, anotações)

### 11.3 Fluxo de Uso em Apresentação

1. Usuário seleciona uma setlist
2. Inicia o "Modo Apresentação"
3. Sistema otimiza a visualização para performance:
   - Tela sempre ativa
   - Controles simplificados
   - Rolagem automática (quando aplicável)
4. Usuário navega entre músicas com gestos ou botões
5. O conteúdo é apresentado no visualizador otimizado para cada tipo

## 12. Expansão Futura e Melhorias

### 12.1 Funcionalidades Planejadas

1. **Editor Avançado de Tablaturas**:
   - Interface completa para criação de tablaturas complexas
   - Suporte a notação para múltiplos instrumentos

2. **Transposição de Acordes**:
   - Alterar tom de músicas automaticamente
   - Suporte a diferentes notações de acordes

3. **Reconhecimento de Música**:
   - Identificação de músicas a partir de gravações ou humming
   - Busca automática de letras e acordes

4. **Sincronização em Nuvem**:
   - Backup de dados em serviços de armazenamento
   - Sincronização entre dispositivos

5. **Integração com Serviços de Música**:
   - Conexão com plataformas como Spotify, Apple Music
   - Importação automática de letras e informações de álbuns

### 12.2 Melhorias Técnicas Futuras

1. **Otimização de Renderização**:
   - Melhoria na visualização de conteúdos complexos
   - Suporte a formatos adicionais

2. **Migração para Arquitetura MVVM/BLoC**:
   - Adoção completa de padrões recomendados para Flutter
   - Melhoria na separação de lógica de UI e negócios

3. **Reconhecimento Óptico de Música (OMR)**:
   - Conversão de imagens de partituras para formato editável
   - Melhorias na importação de material escaneado

4. **Processamento Avançado de Áudio**:
   - Análise de ritmo para metrônomo automático
   - Detecção de acordes a partir de áudio
>>>>>>> dfdae23 (Update README.md)
