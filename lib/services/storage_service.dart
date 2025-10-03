import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/calendar_event.dart';

class StorageService {
  static final StorageService instance = StorageService._init();
  static Database? _database;

  StorageService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('calendar.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        endDate TEXT,
        startTime TEXT,
        endTime TEXT,
        isAllDay INTEGER NOT NULL,
        location TEXT,
        notes TEXT,
        categories TEXT,
        color INTEGER NOT NULL,
        alerts TEXT,
        repeatRule TEXT,
        invitees TEXT,
        calendarId TEXT
      )
    ''');
  }

  Future<void> init() async {
    await database;
  }

  Future<void> saveEvent(CalendarEvent event) async {
    final db = await database;
    await db.insert(
      'events',
      event.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final db = await database;
    await db.update(
      'events',
      event.toJson(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> deleteEvent(String id) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CalendarEvent>> getEvents() async {
    final db = await database;
    final maps = await db.query('events');

    return maps.map((map) {
      // Parse alerts JSON string
      if (map['alerts'] is String) {
        map = Map<String, dynamic>.from(map);
        map['alerts'] = [];
      }
      return CalendarEvent.fromJson(map);
    }).toList();
  }

  Future<CalendarEvent?> getEvent(String id) async {
    final db = await database;
    final maps = await db.query('events', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;

    final map = Map<String, dynamic>.from(maps.first);
    if (map['alerts'] is String) {
      map['alerts'] = [];
    }

    return CalendarEvent.fromJson(map);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
