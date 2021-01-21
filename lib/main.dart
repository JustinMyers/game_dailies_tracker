import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

void main() {
  runApp(DailiesTracker());
}

class DailiesTracker extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseCollection<Task>>(
              create: (_) => DatabaseCollection(model: Task())),
          ChangeNotifierProvider<DatabaseCollection<Game>>(
              create: (_) => DatabaseCollection(model: Game())),
        ],
        child: MyHomePage(title: 'Game Dailies Tracker'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
            title: Text(widget.title),
            bottom: TabBar(
              tabs: [Tab(child: Text('Tasks')), Tab(child: Text('Games'))],
            )),
        body: TabBarView(
          children: [
            Center(
                child: FutureBuilder(
                    future:
                        Provider.of<DatabaseCollection<Task>>(context).all(),
                    builder: (_, snapshot) {
                      if (snapshot.hasData) {
                        return ListView(
                            children: List.generate(
                                snapshot.data.length,
                                (index) => TaskListItem(
                                    record: snapshot.data[index])));
                      } else {
                        return CircularProgressIndicator();
                      }
                    })),
            Center(
                child: FutureBuilder(
                    future:
                        Provider.of<DatabaseCollection<Game>>(context).all(),
                    builder: (_, snapshot) {
                      if (snapshot.hasData) {
                        return ListView(
                            children: List.generate(
                                snapshot.data.length,
                                (index) => GameListItem(
                                    record: snapshot.data[index])));
                      } else {
                        return CircularProgressIndicator();
                      }
                    })),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () {
              if (DefaultTabController.of(context).index == 0) {
                DatabaseCollection collection =
                    Provider.of<DatabaseCollection<Task>>(context,
                        listen: false);
                DatabaseCollection gamesCollection =
                    Provider.of<DatabaseCollection<Game>>(context,
                        listen: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskEditRoute(
                      games: gamesCollection,
                      record: DatabaseRecord(
                          data: {'label': ''},
                          model: Task(),
                          collection: collection),
                    ),
                  ),
                );
              } else {
                DatabaseCollection collection =
                    Provider.of<DatabaseCollection<Game>>(context,
                        listen: false);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameEditRoute(
                      record: DatabaseRecord(
                          data: {'name': 'A New Game', 'characters': ''},
                          model: Game(),
                          collection: collection),
                    ),
                  ),
                );
              }
            },
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class TaskListItem extends StatelessWidget {
  final DatabaseRecord record;

  TaskListItem({this.record});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FlatButton(
            onPressed: () {
              record.data = Map<String, dynamic>.from(record.data)..addAll({'completedDateTime': DateTime.now().toString()});
              record.write(record.data);
            },
            child: Icon(
              Icons.check_circle,
              size: 24.0,
              semanticLabel: 'Mark ${record.data['label']} as completed',
            )),
        FlatButton(
            onPressed: () {
              DatabaseCollection gamesCollection =
                  Provider.of<DatabaseCollection<Game>>(context, listen: false);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        TaskEditRoute(record: record, games: gamesCollection)),
              );
            },
            child: Icon(
              Icons.edit,
              size: 24.0,
              semanticLabel: 'Edit ${record.data['label']}',
            )),
        FlatButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Confirm Task Deletion"),
                    content: Text(
                        "Delete task with label \"${record.data['label']}\"?"),
                    actions: [
                      FlatButton(
                        child: Text("Cancel"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text("Continue"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          record.delete(record.data);
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Icon(
              Icons.delete,
              size: 24.0,
              semanticLabel: 'Delete ${record.data['name']}',
            )),
        Flexible(
            child: Text("${record.data['id']} - ${record.data.toString()}")),
      ],
    );
  }
}

class GameListItem extends StatelessWidget {
  final DatabaseRecord record;

  GameListItem({this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            FlatButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GameEditRoute(record: record)),
                  );
                },
                child: Icon(
                  Icons.edit,
                  size: 24.0,
                  semanticLabel: 'Edit ${record.data['name']}',
                )),
            Text(record.data['name']),
            FlatButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Confirm Game Deletion"),
                        content: Text(
                            "Delete game with name \"${record.data['name']}\"?"),
                        actions: [
                          FlatButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          FlatButton(
                            child: Text("Continue"),
                            onPressed: () {
                              Navigator.of(context).pop();
                              record.delete(record.data);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Icon(
                  Icons.delete,
                  size: 24.0,
                  semanticLabel: 'Delete ${record.data['name']}',
                ))
          ],
        ),
        ...List.generate(Game.charactersList(record.data).length,
            (index) => Text(Game.charactersList(record.data)[index]))
      ],
    );
  }
}

class TaskEditRoute extends StatefulWidget {
  DatabaseRecord record;
  DatabaseCollection<Game> games;

  TaskEditRoute({Key key, @required this.record, @required this.games})
      : super(key: key);

  @override
  _TaskEditRouteState createState() => _TaskEditRouteState();
}

class _TaskEditRouteState extends State<TaskEditRoute> {
  final _labelTextController = TextEditingController();

  DatabaseRecord<Game> game;
  String characterName;
  TimeOfDay time;
  int day;

  TimeOfDay parseTimeOfDayString(timeOfDayString) {
    String _timeString = timeOfDayString.split('(')[1].split(')')[0];
    int hour = int.parse(_timeString.split(':')[0]);
    int minute = int.parse(_timeString.split(':')[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  void initState() {
    super.initState();
    _labelTextController.text = widget.record.data["label"];
    if (widget.record.data['id'] != null) {
      game = widget.games.records.firstWhere(
          (element) => element.data['name'] == widget.record.data['game']);
      characterName = widget.record.data['character'];
      day = widget.record.data['day'];
      time = parseTimeOfDayString(widget.record.data['time']);
    }
  }

  void dispose() {
    _labelTextController.dispose();
    super.dispose();
  }

  // Completed on (datetime)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
              "${widget.record.data['id'] == null ? 'Create a new task' : 'Edit ${widget.record.data['label']}'}"),
        ),
        body: Column(
          children: [
            Row(
              children: [
                Text("label"),
                Expanded(
                  child: TextFormField(
                    controller: _labelTextController,
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            FutureBuilder(
              future: widget.games.all(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return DropdownButton<DatabaseRecord<Game>>(
                    hint: Text('Choose a Game'),
                    value: game,
                    iconSize: 12,
                    elevation: 16,
                    onChanged: (DatabaseRecord<Game> newValue) {
                      setState(() {
                        game = newValue;
                        characterName = null;
                      });
                    },
                    items: snapshot.data
                        .map<DropdownMenuItem<DatabaseRecord<Game>>>(
                            (DatabaseRecord<Game> game) {
                      return DropdownMenuItem<DatabaseRecord<Game>>(
                        value: game,
                        child: Text(game.data['name']),
                      );
                    }).toList(),
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            if (game != null &&
                (game.data['characters'] != null &&
                    game.data['characters'] != ''))
              DropdownButton<String>(
                hint: Text('Choose a Character'),
                value: characterName,
                iconSize: 12,
                elevation: 16,
                onChanged: (String newValue) {
                  setState(() {
                    characterName = newValue;
                  });
                },
                items: game.data['characters']
                    .split(',')
                    .map<DropdownMenuItem<String>>((String character) {
                  return DropdownMenuItem<String>(
                    value: character,
                    child: Text(character),
                  );
                }).toList(),
              ),
            DropdownButton<int>(
              hint: Text('Choose a Day'),
              value: day,
              iconSize: 12,
              elevation: 16,
              onChanged: (int newValue) {
                setState(() {
                  day = newValue;
                });
              },
              items: [0, 1, 2, 3, 4, 5, 6, 7]
                  .map<DropdownMenuItem<int>>((int day) {
                return DropdownMenuItem<int>(
                  value: day,
                  child: Text([
                    'Daily',
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday'
                  ][day]),
                );
              }).toList(),
            ),
            Builder(
              builder: (context) => FlatButton(
                  onPressed: () async {
                    TimeOfDay _time = await showTimePicker(
                        initialTime: time ?? TimeOfDay(hour: 0, minute: 0),
                        context: context);
                    setState(() {
                      time = _time;
                    });
                  },
                  child: Text(
                      time == null ? 'Select Time' : time.format(context))),
            ),
            Builder(
              builder: (context) => FlatButton(
                onPressed: () {
                  widget.record.write({
                    'id': widget.record.data['id'],
                    'label': _labelTextController.text,
                    'game': game.data['name'],
                    'character': characterName,
                    'day': day,
                    'time': time.toString()
                  });
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            )
          ],
        ));
  }
}

class GameEditRoute extends StatefulWidget {
  final DatabaseRecord record;

  GameEditRoute({Key key, @required this.record}) : super(key: key);

  @override
  _GameEditRouteState createState() => _GameEditRouteState();
}

class _GameEditRouteState extends State<GameEditRoute> {
  final _nameTextController = TextEditingController();
  final _characterTextController = TextEditingController();

  void initState() {
    super.initState();
    _nameTextController.text = widget.record.data["name"];
    _characterTextController.text =
        widget.record.data['characters'].split(',').join('\n');
  }

  void dispose() {
    _nameTextController.dispose();
    _characterTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
              "${widget.record.data['id'] == null ? 'Create' : 'Edit'} ${widget.record.data['name']}"),
        ),
        body: Column(
          children: [
            Row(
              children: [
                Text("Name"),
                Expanded(
                  child: TextFormField(
                    controller: _nameTextController,
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            Text('Enter character names, one per line'),
            TextFormField(
              controller: _characterTextController,
              decoration: InputDecoration(border: OutlineInputBorder()),
              minLines: 10,
              maxLines: 10,
            ),
            Builder(
              builder: (context) => FlatButton(
                onPressed: () {
                  widget.record.write({
                    'id': widget.record.data['id'],
                    'name': _nameTextController.text,
                    'characters':
                        _characterTextController.text.split('\n').join(',')
                  });
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            )
          ],
        ));
  }
}

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
}

class Game extends DatabaseModel {
  Game() {
    tableName = 'games';
    dataStructure.addAll({"name": String, "characters": String});
  }

  static List<String> charactersList(data) {
    return data['characters'].split(',');
  }

  static 
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
