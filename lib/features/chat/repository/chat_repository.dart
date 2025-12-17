import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/message.dart';

class ChatRepository {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'chats.db');
    return await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE messages(
          id TEXT PRIMARY KEY,
          characterId TEXT,
          text TEXT,
          isUser INTEGER,
          timestamp INTEGER
        )
      ''');
    });
  }

  static Future<void> saveMessage(String characterId, Message msg) async {
    final dbClient = await db;
    await dbClient.insert(
      'messages',
      {'characterId': characterId, ...msg.toMap()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Message>> getHistory(String characterId) async {
    final dbClient = await db;
    final maps = await dbClient.query(
      'messages',
      where: 'characterId = ?',
      whereArgs: [characterId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => Message.fromMap(m)).toList();
  }

  static Future<void> clearHistory(String characterId) async {
    final dbClient = await db;
    await dbClient.delete('messages', where: 'characterId = ?', whereArgs: [characterId]);
  }
}