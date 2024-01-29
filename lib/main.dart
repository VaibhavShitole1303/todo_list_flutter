import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO App',
      home: TodoList(),
    );
  }
}

class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  late Database _database;
  List<Todo> todos = [];

  @override
  void initState() {
    super.initState();
    _openDatabase();
  }

  Future<void> _openDatabase() async {
    // Open the database
    _database = await openDatabase(
      join(await getDatabasesPath(), 'todo_database.db'),
      onCreate: (db, version) {
        // Create the table
        return db.execute(
          'CREATE TABLE todos(id INTEGER PRIMARY KEY, task TEXT, isCompleted INTEGER)',
        );
      },
      version: 1,
    );

    // Fetch todos from the database
    List<Map<String, dynamic>> todosFromDB = await _database.query('todos');
    todos = todosFromDB.map((todo) => Todo.fromMap(todo)).toList();

    setState(() {}); // Update the UI with the loaded todos
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TODO List'),
      ),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(todos[index].task),
            leading: Checkbox(
              value: todos[index].isCompleted,
              onChanged: (bool? value) {
                _toggleCompleted(index, value ?? false);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String newTodo = ''; // Initialize an empty string to store the new todo
              return AlertDialog(
                title: Text('Add TODO'),
                content: TextField(
                  onChanged: (value) {
                    newTodo = value;
                  },
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Save the new todo to the database
                      int id = await _database.insert('todos', {'task': newTodo, 'isCompleted': 0});
                      // Update the UI with the new todo
                      setState(() {
                        todos.add(Todo(id: id, task: newTodo, isCompleted: false));
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _toggleCompleted(int index, bool isCompleted) async {
    // Update the completed status in the database
    await _database.update(
      'todos',
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [todos[index].id],
    );

    // Update the UI with the new completed status
    setState(() {
      todos[index].isCompleted = isCompleted;
    });
  }

  void _addTodo() {

  }
}

class Todo {
  final int id;
  final String task;
  late final bool isCompleted;

  Todo({
    required this.id,
    required this.task,
    required this.isCompleted,
  });

  Todo.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        task = map['task'],
        isCompleted = map['isCompleted'] == 1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }
}
