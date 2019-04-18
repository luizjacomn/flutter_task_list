import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

final _blue = Colors.blue;
final _darkGray = Colors.blueGrey[800];
final _white = Colors.white;
final _yellow = Colors.yellow;
final _red = Colors.red;
final _labelSize = 15.0;
final _textSize = 20.0;
final _addIcon = Icons.add;
final _doneIcon = Icons.check;
final _todoIcon = Icons.error;
final _trashIcon = Icons.delete;
final _sortIcon = Icons.sort_by_alpha;

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _taskController = TextEditingController();
  final titleKey = 'title';
  final doneKey = 'done';

  List _todoList = [];
  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  void _addTask() {
    setState(() {
      Map<String, dynamic> newTask = Map();
      newTask[titleKey] = _taskController.text;
      newTask[doneKey] = false;

      if (!_todoList
          .map((t) => t[titleKey])
          .toList()
          .contains(_taskController.text)) {
        _todoList.add(newTask);
        _saveData();

        _taskController.clear();
      }
    });
  }

  void _sortTasks() {
    setState(() {
      _todoList.sort((task1, task2) {
        if (task1[doneKey] && !task2[doneKey])
          return 1;
        else if (!task1[doneKey] && task2[doneKey])
          return -1;
        else
          return 0;
      });

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      appBar: AppBar(
        title: Text(
          'Lista de tarefas',
          style: TextStyle(color: _white),
        ),
        backgroundColor: _blue,
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(_sortIcon),
            onPressed: _sortTasks,
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 10.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: _darkGray, fontSize: _textSize),
                    decoration: InputDecoration(
                        labelText: 'Nova tarefa',
                        labelStyle:
                            TextStyle(color: _blue, fontSize: _labelSize)),
                  ),
                ),
                RaisedButton(
                  color: _blue,
                  child: Icon(
                    _addIcon,
                    color: _white,
                  ),
                  onPressed: _addTask,
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _todoList.length,
                itemBuilder: buildItem),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPosition = index;
          _todoList.removeAt(index);

          _saveData();

          final snackBar = SnackBar(
            content: Text('Tarefa \"${_lastRemoved[titleKey]}\" removida'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
                label: "Desfazer",
                textColor: _blue,
                onPressed: () {
                  setState(() {
                    _todoList.insert(_lastRemovedPosition, _lastRemoved);

                    _saveData();
                  });
                }),
          );

          Scaffold.of(context).showSnackBar(snackBar);
        });
      },
      background: Container(
        color: _red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            _trashIcon,
            color: _white,
          ),
        ),
      ),
      child: CheckboxListTile(
        secondary: CircleAvatar(
          backgroundColor: _darkGray,
          child: Icon(
            _todoList[index][doneKey] ? _doneIcon : _todoIcon,
            color: _todoList[index][doneKey] ? _white : _yellow,
            size: _todoList[index][doneKey] ? 30.0 : 40.0,
          ),
        ),
        title: Text(
          _todoList[index][titleKey],
          style: TextStyle(color: _darkGray, fontSize: _textSize),
        ),
        value: _todoList[index][doneKey],
        onChanged: (checked) {
//          setState(() {
            _todoList[index][doneKey] = checked;
//            _saveData();
          _sortTasks();
//          });
        },
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
