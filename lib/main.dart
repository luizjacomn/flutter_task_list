import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
final _trashIcon = Icons.delete_sweep;
final _checkAllIcon = Icons.check_box;
final _checkNoneIcon = Icons.check_box_outline_blank;

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

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List _todoList = [];
  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPosition;
  bool _selectAll = false;

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
    try {
      setState(() {
        Map<String, dynamic> newTask = Map();
        newTask[titleKey] = _taskController.text.trim();
        newTask[doneKey] = false;

        bool notExists = !_todoList
            .map((t) => t[titleKey])
            .toList()
            .contains(_taskController.text);

        bool exists = !notExists;

        bool isValid = _formKey.currentState.validate();

        if (exists) throw Exception();

        if (isValid && notExists) {
          _todoList.add(newTask);
          _saveData();

          _taskController.clear();
        }
      });
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Uma tarefa com este nome já existe!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: _darkGray,
          textColor: _yellow,
          fontSize: _labelSize);
    }
  }

  void _sortTasks() {
    if (_todoList.isEmpty)
      Fluttertoast.showToast(
          msg: 'A lista de tarefas está vazia! :(',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: _darkGray,
          textColor: _yellow,
          fontSize: _labelSize);

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

  void _selectAllTasks() {
    setState(() {
      if (_selectAll) {
        _todoList.forEach((task) => task[doneKey] = false);
        _selectAll = false;
      } else {
        _todoList.forEach((task) => task[doneKey] = true);
        _selectAll = true;
      }
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
            icon: Icon(_selectAll ? _checkAllIcon : _checkNoneIcon),
            onPressed: _selectAllTasks,
            tooltip: 'Selecionar todas as tarefas',
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 10.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _taskController,
                      validator: (value) {
                        if (value.isEmpty) return 'Informe o nome';
                        if (value.length < 3)
                          return 'O nome deve ter no mínimo 3 caracteres';
                        else
                          return null;
                      },
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
                    shape: CircleBorder(),
                    elevation: 6,
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
                textColor: _yellow,
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
