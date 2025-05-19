import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'musicsheetpro.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Tabela de músicas
    await db.execute('''
      CREATE TABLE musics(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        tags TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isFavorite INTEGER NOT NULL
      )
    ''');

    // Tabela de conteúdos musicais
    await db.execute('''
      CREATE TABLE music_contents(
        id TEXT PRIMARY KEY,
        musicId TEXT NOT NULL,
        type INTEGER NOT NULL,
        contentPath TEXT NOT NULL,
        contentText TEXT,
        version INTEGER NOT NULL,
        FOREIGN KEY (musicId) REFERENCES musics (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de setlists
    await db.execute('''
      CREATE TABLE setlists(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Tabela de relação setlist-música (many-to-many)
    await db.execute('''
      CREATE TABLE setlist_music(
        setlistId TEXT NOT NULL,
        musicId TEXT NOT NULL,
        orderIndex INTEGER NOT NULL,
        PRIMARY KEY (setlistId, musicId),
        FOREIGN KEY (setlistId) REFERENCES setlists (id) ON DELETE CASCADE,
        FOREIGN KEY (musicId) REFERENCES musics (id) ON DELETE CASCADE
      )
    ''');
    // Tabela de anotações
    await db.execute('''
      CREATE TABLE annotations(
        id TEXT PRIMARY KEY,
        contentId TEXT NOT NULL,
        pageNumber INTEGER NOT NULL,
        xPosition REAL NOT NULL,
        yPosition REAL NOT NULL,
        text TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (contentId) REFERENCES music_contents (id) ON DELETE CASCADE
      )
    ''');
  }
}
