import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import '../models/dns_config.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    // Initialize FFI for Windows
    if (Platform.isWindows || Platform.isLinux) {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory for Windows and Linux
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'dns_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dns_configs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        primaryDns TEXT NOT NULL,
        alternateDns TEXT,
        isActive INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertDnsConfig(DnsConfig config) async {
    final db = await database;
    return await db.insert('dns_configs', config.toMap());
  }

  Future<List<DnsConfig>> getDnsConfigs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dns_configs');
    return List.generate(maps.length, (i) {
      return DnsConfig.fromMap(maps[i]);
    });
  }

  Future<DnsConfig?> getDnsConfig(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dns_configs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DnsConfig.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateDnsConfig(DnsConfig config) async {
    final db = await database;
    return await db.update(
      'dns_configs',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  Future<int> deleteDnsConfig(int id) async {
    final db = await database;
    return await db.delete(
      'dns_configs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deactivateAllConfigs() async {
    final db = await database;
    await db.update(
      'dns_configs',
      {'isActive': 0},
      where: null,
    );
  }
} 