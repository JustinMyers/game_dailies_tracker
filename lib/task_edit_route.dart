import 'package:flutter/widgets.dart';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'package:dailies_tracker/database_helper.dart';


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

  void initState() {
    super.initState();
    _labelTextController.text = widget.record.data["label"];
    if (widget.record.data['id'] != null) {
      game = widget.games.records.firstWhere(
              (element) => element.data['name'] == widget.record.data['game']);
      characterName = widget.record.data['character'];
      day = widget.record.data['day'];
      time = Task.parseTimeOfDayString(widget.record.data['time']);
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