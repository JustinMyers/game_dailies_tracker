import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';

import 'package:flutter/material.dart';

import 'package:dailies_tracker/database_helper.dart';
import 'package:dailies_tracker/task_edit_route.dart';

class TaskListItem extends StatelessWidget {
  final DatabaseRecord record;

  TaskListItem({this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(Task.isCompleted(record) ? 'DONE' : 'NOT DONE'),
        Row(
          children: [
            FlatButton(
                onPressed: () {
                  Task.toggleCompleted(record);
                },
                child: Icon(
                  Icons.check_circle,
                  size: 24.0,
                  semanticLabel: 'Mark ${record.data['label']} as completed',
                )),
            FlatButton(
                onPressed: () {
                  DatabaseCollection gamesCollection =
                  Provider.of<DatabaseCollection<Game>>(context,
                      listen: false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TaskEditRoute(
                            record: record, games: gamesCollection)),
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
                child:
                Text("${record.data['id']} - ${record.data.toString()}")),
          ],
        ),
      ],
    );
  }
}