import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';

import 'package:flutter/material.dart';

import 'package:dailies_tracker/database_helper.dart';
import 'package:dailies_tracker/task_list_item.dart';
import 'package:dailies_tracker/game_list_item.dart';
import 'package:dailies_tracker/task_edit_route.dart';
import 'package:dailies_tracker/game_edit_route.dart';

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
