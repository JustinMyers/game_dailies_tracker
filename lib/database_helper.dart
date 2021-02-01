import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class Task extends DatabaseModel {
  Task() {
    tableName = 'tasks';
    dataStructure.addAll({
      "label": String,
      "game_id": int,
      'game': String,
      'character': String,
      'time': String,
      'day': int,
      'completedDateTime': String
    });
  }

  static TimeOfDay parseTimeOfDayString(timeOfDayString) {
    String _timeString = timeOfDayString.split('(')[1].split(')')[0];
    int hour = int.parse(_timeString.split(':')[0]);
    int minute = int.parse(_timeString.split(':')[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  static DateTime lastResetDateTime(DatabaseRecord<Task> record) {
    DateTime now = DateTime.now();
    TimeOfDay resetTimeOfDay = parseTimeOfDayString(record.data['time']);
    TimeOfDay nowTimeOfDay = TimeOfDay.fromDateTime(now);

    bool afterResetTime = resetTimeOfDay.hour < nowTimeOfDay.hour ||
        (resetTimeOfDay.hour == nowTimeOfDay.hour &&
            resetTimeOfDay.minute <= nowTimeOfDay.minute);

    int daysAgo;
    if (record.data['day'] == 0) {
      if (afterResetTime)
        daysAgo = 0;
      else
        daysAgo = 1;
    }
    else if (now.weekday == record.data['day']) {
      print('Yes, it is THURSDAY ******');
      if(afterResetTime)
        daysAgo = 0;
      else
        daysAgo = 7;
    } else {
      daysAgo = 7 - (now.weekday - record.data['day']).abs();
    }
    DateTime dayOfReset = now.subtract(Duration(days: daysAgo));
    DateTime actualResetDateTime = DateTime(dayOfReset.year, dayOfReset.month,
        dayOfReset.day, resetTimeOfDay.hour, resetTimeOfDay.minute);
    return actualResetDateTime;
  }

  static void toggleCompleted(DatabaseRecord<Task> record) {
    Map<String, dynamic> updateData = Map<String, dynamic>.from(record.data);

    if (record.data['completedDateTime'] == null) {
      updateData['completedDateTime'] = DateTime.now().toString();
    } else {
      updateData['completedDateTime'] = null;
    }
    record.write(updateData);
  }

  static bool isCompleted(DatabaseRecord<Task> record) {
    if (record.data['completedDateTime'] == null) return false;

    DateTime completedDateTime =
    DateTime.parse(record.data['completedDateTime']);

    return completedDateTime.isAfter(lastResetDateTime(record));
  }
}

class Game extends DatabaseModel {
  Game() {
    tableName = 'games';
    dataStructure.addAll({"name": String, "characters": String});
  }

  static List<String> charactersList(data) {
    return data['characters'].split(',');
  }
}

class DatabaseModel {
  String tableName;
  Map<String, Type> dataStructure = {"id": int};
  Map<String, Type> data = {};
}

class DatabaseRecord<T extends DatabaseModel> extends ChangeNotifier {
  DatabaseConnection _databaseConnection = DatabaseConnection();

  T model;
  Map<String, dynamic> data;
  DatabaseCollection collection;

  DatabaseRecord({this.model, this.data, this.collection}) {
    if (collection != null)
      addListener(() {
        collection.notifyListeners();
      });
  }

  bool operator ==(o) {
    return data.toString() == o.data.toString();
  }

  Future<void> write(Map<String, dynamic> _data) async {
    if (_data['id'] != null) {
      update(_data);
    } else {
      create(_data);
    }
  }

  Future<void> create(Map<String, dynamic> _createData) async {
    print('creating');

    _createData
        .removeWhere((key, value) => !model.dataStructure.keys.contains(key));

    final Database db = await _databaseConnection.database;

    int id = await db.insert(
      model.tableName,
      _createData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    data = _createData..addAll({'id': id});

    notifyListeners();
  }

  Future<void> update(Map<String, dynamic> _updateData) async {
    _updateData = Map<String, dynamic>.from(data)..addAll(_updateData);

    int id = _updateData.remove("id");

    // remove inappropriate data
    _updateData
        .removeWhere((key, value) => !model.dataStructure.keys.contains(key));

    final Database db = await _databaseConnection.database;
    await db.update(
      model.tableName,
      _updateData,
      where: "id = ?",
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    data = _updateData..addAll({'id': id});

    notifyListeners();
  }

  Future<void> delete(Map<String, dynamic> data) async {
    int id = data["id"];

    final Database db = await _databaseConnection.database;
    await db.delete(model.tableName, where: "id = ?", whereArgs: [id]);

    notifyListeners();
  }
}

class DatabaseCollection<T extends DatabaseModel> extends ChangeNotifier {
  DatabaseConnection _databaseConnection = DatabaseConnection();

  T model;
  List<DatabaseRecord<T>> records;

  DatabaseCollection({@required this.model});

  Future<List<DatabaseRecord<T>>> all() async {
    final Database db = await _databaseConnection.database;
    List<Map<String, dynamic>> results = await db.query(model.tableName);

    records = List.generate(results.length, (i) {
      return DatabaseRecord<T>(
          model: model, data: results[i], collection: this);
    });

    return records;
  }

  Future<void> add(Map<String, dynamic> data) async {
    // remove unnecessary data
    data.removeWhere((key, value) => !model.dataStructure.keys.contains(key));

    final Database db = await _databaseConnection.database;
    await db.insert(
      model.tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }
}

class DatabaseConnection {
  // https://stackoverflow.com/questions/12649573/how-do-you-build-a-singleton-in-dart
  static final DatabaseConnection _databaseConnection =
  DatabaseConnection._internal();

  factory DatabaseConnection() {
    return _databaseConnection;
  }

  DatabaseConnection._internal();

  // https://suragch.medium.com/simple-sqflite-database-example-in-flutter-e56a5aaa3f91
  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await openDatabase(
      join(await getDatabasesPath(), 'dailies_tracker.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE tasks(id INTEGER PRIMARY KEY, label TEXT, game_id INTEGER);",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 5) {
          db.execute(
            "CREATE TABLE games(id INTEGER PRIMARY KEY, name TEXT, characters TEXT)",
          );
        }
        if (oldVersion < 6) {
          db.execute(
            "ALTER TABLE tasks ADD COLUMN character TEXT",
          );
          db.execute(
            "ALTER TABLE tasks ADD COLUMN time TEXT",
          );
          db.execute(
            "ALTER TABLE tasks ADD COLUMN day INTEGER",
          );
          db.execute(
            "ALTER TABLE tasks ADD COLUMN game TEXT",
          );
        }
        if (oldVersion < 7) {
          db.execute(
            "ALTER TABLE tasks ADD COLUMN completedDateTime TEXT",
          );
        }
      },
      version: 7,
    );
    return _database;
  }
}