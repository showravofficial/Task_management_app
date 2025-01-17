import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List tasks = List.generate(
    10,
        (index) => {
      '_id': '$index',
      'title': 'Task ${index + 1}',
      'description': 'This is the description for Task ${index + 1}',
    },
  );
  String? token;

  Future<void> fetchTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://139.59.65.225:8052/task/get-all-task'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        tasks = jsonDecode(response.body)['data'];
      });
    } else {
      print('Failed to fetch tasks: ${response.statusCode}');
      // Retain the initial dummy data if the API fails
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tasks[index]['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    tasks[index]['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                        String? token = prefs.getString('token');

                        final response = await http.delete(
                          Uri.parse(
                              'http://139.59.65.225:8052/delete-task/${tasks[index]['_id']}'),
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                            'Authorization': 'Bearer $token',
                          },
                        );

                        if (response.statusCode == 200) {
                          fetchTasks();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Task deleted successfully')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete task')),
                          );
                          print('Failed to delete task: ${response.statusCode}');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              final TextEditingController titleController =
              TextEditingController();
              final TextEditingController descriptionController =
              TextEditingController();

              return AlertDialog(
                title: Text('Create Task'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                      String? token = prefs.getString('token');

                      final response = await http.post(
                        Uri.parse(
                            'http://139.59.65.225:8052/task/create-task'),
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                          'Authorization': 'Bearer $token',
                        },
                        body: jsonEncode(<String, String>{
                          'title': titleController.text,
                          'description': descriptionController.text,
                        }),
                      );

                      if (response.statusCode == 200) {
                        fetchTasks();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Task created successfully')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Task creation failed')),
                        );
                      }
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
}
