import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'app_faculdade.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    await ensureDemoUser();
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        senha TEXT NOT NULL,
        nome TEXT,
        provider TEXT DEFAULT 'local'
      )
    ''');

    await db.insert('usuarios', {
      'email': 'admin@teste.com',
      'senha': '123456',
      'nome': 'Administrador',
      'provider': 'local',
    });
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS usuarios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          senha TEXT NOT NULL,
          nome TEXT,
          provider TEXT DEFAULT 'local'
        )
      ''');
    }
  }

  static Future<void> ensureDemoUser() async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: ['admin@teste.com'],
    );

    if (result.isEmpty) {
      await db.insert('usuarios', {
        'email': 'admin@teste.com',
        'senha': '123456',
        'nome': 'Administrador',
        'provider': 'local',
      });
    }
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ? AND senha = ?',
      whereArgs: [email.trim().toLowerCase(), password],
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  static Future<int> registerUser({
    required String email,
    required String password,
    required String name,
    String provider = 'local',
  }) async {
    final db = await database;

    final exists = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );

    if (exists.isNotEmpty) {
      throw Exception('Usuário já cadastrado.');
    }

    return db.insert('usuarios', {
      'email': email.trim().toLowerCase(),
      'senha': password,
      'nome': name,
      'provider': provider,
    });
  }
}
