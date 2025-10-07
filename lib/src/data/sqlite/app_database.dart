import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton wrapper around the SQLite [Database].
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _db;

  /// Returns the opened database, creating it if necessary.
  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'fitlog.db');
    _db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE exercise(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            category TEXT,
            main_muscle_group TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE workout_plan(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            frequency TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE plan_exercise(
            plan_id INTEGER,
            exercise_id INTEGER,
            suggested_sets INTEGER,
            suggested_reps INTEGER,
            estimated_weight REAL,
            rest_seconds INTEGER,
            image_path TEXT,
            position INTEGER,
            PRIMARY KEY(plan_id, exercise_id)
          );
        ''');
        await db.execute('''
          CREATE TABLE workout_session(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            plan_id INTEGER,
            fatigue_level TEXT,
            duration_minutes INTEGER,
            mood TEXT,
            notes TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE workout_log(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            plan_id INTEGER,
            exercise_id INTEGER,
            set_number INTEGER,
            reps INTEGER,
            weight REAL,
            rir INTEGER
          );
        ''');
      },
    );
    return _db!;
  }
}
