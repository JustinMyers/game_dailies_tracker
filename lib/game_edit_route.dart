import 'package:flutter/widgets.dart';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'package:dailies_tracker/database_helper.dart';

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