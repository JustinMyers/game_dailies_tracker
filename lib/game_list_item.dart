import 'package:flutter/widgets.dart';

import 'package:flutter/material.dart';

import 'package:dailies_tracker/database_helper.dart';
import 'package:dailies_tracker/game_edit_route.dart';

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