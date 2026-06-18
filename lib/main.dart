import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TaskHome(),
    );
  }
}

class TaskHome extends StatefulWidget {
  const TaskHome({super.key});

  @override
  State<TaskHome> createState() => _TaskHomeState();
}

class _TaskHomeState extends State<TaskHome> {
  // TASK DATA
  List<Map<String, String>> tasks = [];

  // CONTROLLERS
  TextEditingController taskController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  // STATES
  String searchQuery = "";
  String selectedCategory = "Work";

  @override
  void initState() {
    super.initState();
    loadTasks();

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  // SAVE TASKS
  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> encoded = tasks.map((task) {
      return "${task['task']}|${task['category']}";
    }).toList();

    prefs.setStringList("tasks", encoded);
  }

  // LOAD TASKS
  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList("tasks") ?? [];

    setState(() {
      tasks = stored.map((item) {
        final parts = item.split("|");
        return {
          "task": parts[0],
          "category": parts.length > 1 ? parts[1] : "Work",
        };
      }).toList();
    });
  }

  // ADD TASK
  void addTask() {
    if (taskController.text.trim().isEmpty) return;

    setState(() {
      tasks.add({
        "task": taskController.text.trim(),
        "category": selectedCategory,
      });

      taskController.clear();
    });

    saveTasks();
  }

  // DELETE TASK
  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });

    saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    // FILTER TASKS (SEARCH)
    final filteredTasks = tasks.where((task) {
      return task["task"]!.toLowerCase().contains(searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // SEARCH BAR
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Search tasks",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),

            const SizedBox(height: 10),

            // TASK INPUT
            TextField(
              controller: taskController,
              decoration: const InputDecoration(
                labelText: "Enter task",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // CATEGORY DROPDOWN
            DropdownButton<String>(
              value: selectedCategory,
              items: ["Work", "Personal", "Study"]
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 10),

            // ADD BUTTON
            ElevatedButton(
              onPressed: addTask,
              child: const Text("Add Task"),
            ),

            const SizedBox(height: 10),

            // TASK LIST
            Expanded(
              child: filteredTasks.isEmpty
                  ? const Center(child: Text("No tasks found"))
                  : ListView.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];

                        return Card(
                          child: ListTile(
                            title: Text(task["task"]!),
                            subtitle: Text(task["category"]!),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                int realIndex = tasks.indexOf(task);
                                deleteTask(realIndex);
                              },
                            ),
                          ),
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
