# MusicSheet Pro

A comprehensive cross-platform Flutter application for managing musical content including sheet music, tablatures, and song lyrics. Designed to replace physical music folders with a modern digital solution for musicians, bands, and music educators.

## 🎵 Overview

MusicSheet Pro is a digital music content management system that allows musicians to organize, view, annotate, and perform with their musical materials. The app supports multiple content types and provides specialized viewers optimized for different musical formats.

### Key Features

- **Multi-format Support**: Handle sheet music (PDF), tablatures, lyrics, and chord charts
- **Content Creation**: Built-in editors for lyrics, chords, and simple tablatures
- **File Import**: Support for PDF, images, and various musical formats
- **Smart Organization**: Tag-based library system with search and filtering
- **Setlist Management**: Create and manage performance setlists
- **Performance Mode**: Optimized interface for live performances
- **Annotations**: Add notes and markings to your musical content
- **Cross-platform**: Available on Android, iOS, macOS, Windows, Linux, and Web

## 🏗️ Architecture

The project follows Clean Architecture principles with the Repository pattern:

```
lib/
├── app/                    # App configuration and routing
├── core/                   # Core models and services
│   ├── models/            # Data models (Music, Setlist, Annotation)
│   └── services/          # Service locator and dependency injection
├── data/                  # Data layer implementation
│   ├── datasources/       # Database and file system access
│   └── repositories/      # Repository implementations
├── domain/                # Business logic layer
│   └── repositories/      # Repository interfaces
└── presentation/          # UI layer
    ├── home/             # Main navigation
    ├── library/          # Music library management
    ├── lyrics/           # Lyric editor
    ├── setlists/         # Setlist management
    └── viewer/           # Content viewers
```

## 🗄️ Data Models

### Core Entities

- **Music**: Represents a song or musical composition
- **MusicContent**: Associated content (sheet music, lyrics, tabs)
- **Setlist**: Ordered collection of songs for performances
- **Annotation**: User notes and markings on musical content

### Database Schema

The app uses SQLite with the following main tables:
- `musics` - Song metadata and information
- `music_contents` - Associated musical content
- `setlists` - Performance setlists
- `setlist_music` - Many-to-many relationship for setlist songs
- `annotations` - User annotations on content

## 🎛️ Technology Stack

### Framework & Language
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language

### Dependencies

#### Core Functionality
- `provider` - State management
- `get_it` - Dependency injection
- `sqflite` - SQLite database
- `path_provider` - File system access
- `shared_preferences` - Simple data persistence

#### Content Handling
- `syncfusion_flutter_pdfviewer` - PDF viewing and annotation
- `file_picker` - File selection and import
- `permission_handler` - System permissions

#### UI & UX
- `google_fonts` - Typography
- `flutter_svg` - Vector graphics
- `cupertino_icons` - iOS-style icons

#### Utilities
- `uuid` - Unique identifier generation
- `intl` - Internationalization
- `url_launcher` - External URL handling
- `wakelock_plus` - Screen wake management for performances

## 📱 Platform Support

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 11+)
- ✅ **macOS** (10.14+)
- ✅ **Windows**
- ✅ **Linux**
- ✅ **Web**

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Platform-specific requirements:
  - Android: Android Studio & SDK
  - iOS/macOS: Xcode
  - Windows: Visual Studio with C++ support
  - Linux: Standard development tools

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd music_sheet_pro
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Platform-specific Setup

#### Android
- Minimum SDK: API 21 (Android 5.0)
- Permissions configured for file access and storage

#### iOS
- Deployment target: iOS 11.0
- File access permissions configured in Info.plist

#### macOS
- Deployment target: macOS 10.14
- Sandbox entitlements for file access
- CocoaPods integration for native dependencies

## 🎼 Usage

### Adding Music Content

1. **From Library Screen**: Tap the "+" button
2. **Enter Details**: Add title, artist, and tags
3. **Add Content**: 
   - Import PDF files for sheet music
   - Use the lyric editor for songs with chords
   - Import images of handwritten music
   - Create simple tablatures

### Creating Setlists

1. Navigate to **Setlists** tab
2. Create a new setlist with name and description
3. Add songs by searching your library
4. Reorder songs with drag-and-drop
5. Use **Performance Mode** for live shows

### Viewing Content

The app automatically selects the appropriate viewer:
- **PDF Viewer**: For imported sheet music with zoom and annotation
- **Lyric Viewer**: For chord charts with auto-scroll
- **Image Viewer**: For scanned or photographed music

## 🔧 Development

### Project Structure

The codebase follows Flutter best practices:
- Separation of concerns with clean architecture
- Provider for state management
- Repository pattern for data access
- Service locator for dependency injection

### Building for Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release

# Web
flutter build web --release
```

## 📋 Features in Detail

### Content Management
- Import PDFs, images, and text files
- Built-in editors for lyrics and chord charts
- Tag-based organization system
- Search and filter capabilities
- Favorites and recently accessed items

### Performance Tools
- Setlist creation and management
- Performance mode with optimized controls
- Auto-scroll for lyrics and chord charts
- Screen wake-lock during performances
- Quick navigation between songs

### Annotation System
- Add text notes to any content
- Drawing tools for sheet music markup
- Color-coded annotations
- Position-specific comments
- Export annotated content

## 🔮 Future Enhancements

### Planned Features
- Advanced tablature editor
- Chord transposition tools
- Music recognition and import
- Cloud synchronization
- Collaboration features
- Audio playback integration
- Metronome and tuner tools

### Technical Improvements
- Offline-first architecture
- Advanced search with fuzzy matching
- Custom themes and personalization
- Backup and restore functionality
- Integration with music streaming services

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Follow Flutter/Dart style guidelines
4. Add tests for new functionality
5. Submit a pull request

### Development Guidelines
- Follow the existing architecture patterns
- Use meaningful commit messages
- Update documentation for new features
- Test on multiple platforms when possible

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support, feature requests, or bug reports:
- Create an issue on GitHub
- Check the documentation for common solutions
- Review the FAQ section

## 📞 Contact

- **Developer**: ai.faz
- **Package ID**: ai.faz.musicSheetPro
- **Copyright**: © 2025 ai.faz. All rights reserved.

---

**MusicSheet Pro** - Transforming how musicians organize and perform with their musical content. 🎼