import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas',
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData.dark(),
      home: TodoList(onToggleTheme: _toggleTheme),
    );
  }
}
class TodoList extends StatefulWidget {
  final VoidCallback onToggleTheme;

  TodoList({required this.onToggleTheme});

  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final List<String> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  final List<bool> _completed = [];
  bool _isDarkTheme = false;
  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  void loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedTasks = prefs.getStringList('tasks');
    if (savedTasks != null) {
      setState(() {
        _tasks.addAll(savedTasks);
      });
      final List<String>? savedCompleted = prefs.getStringList('completed');
      if (savedCompleted != null) {
        setState(() {
          _tasks.clear();
          _tasks.addAll(savedTasks);
          _completed.clear();  // Limpar a lista de estados
          if (savedCompleted != null && savedCompleted.length == savedTasks.length) {
            _completed.addAll(savedCompleted.map((e) => e == 'true'));
          } else {
            _completed.addAll(List.filled(savedTasks.length, false));
          }
        });
    }
      }
  }

  void _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tasks', _tasks);
    List<String> completedStrings = _completed.map((e) => e ? 'true' : 'false').toList();
    await prefs.setStringList('completed', completedStrings);
  }
  void _addTask() {
    setState(() {
      final String taskText = _controller.text.trim();
      if (taskText.isNotEmpty) {
        _tasks.add(taskText);
        _completed.add(false);
        _controller.clear();
      }
    });
    _saveTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tarefa adicionada com sucesso!')),
    );
  }

  void _removeTask(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir esta tarefa?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _tasks.removeAt(index);
              });
              _saveTasks();
              Navigator.of(context).pop();
            },
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }


  void _editTask(int index) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController editController = TextEditingController(text: _tasks[index]);
        return AlertDialog(
          title: Text('Editar Tarefa'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(labelText: 'Nova descrição'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks[index] = editController.text;
                });
                _saveTasks();
                Navigator.of(context).pop();
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Nova Tarefa'),
            ),
            ElevatedButton(
              onPressed: _addTask,
              child: Text('Adicionar'),
            ),
        Expanded(
          child: ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Checkbox(
                  value: _completed[index],
                  onChanged: (bool? value) {
                    setState(() {
                      _completed[index] = value!;
                    });
                    _saveTasks();
                  },
                ),
                title: Text(
                  _tasks[index],
                  style: TextStyle(
                    decoration: _completed[index] ? TextDecoration.lineThrough : null,
                    color: _completed[index] ? Colors.grey : null,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editTask(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _removeTask(index),
                    ),
                  ],
                ),
                onTap: () => _editTask(index),
              );
            },
          ),
        ),
          ],
        ),
      ),
    );
  }
}
