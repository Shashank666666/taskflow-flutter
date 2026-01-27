import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow_flutter/models/task.dart';

class TaskService {
  static const String _tasksKey = 'tasks';

  static Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_tasksKey) ?? '[]';
    final List<dynamic> tasksList = json.decode(tasksJson);
    return tasksList.map((json) => Task.fromJson(json)).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = json.encode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_tasksKey, tasksJson);
  }

  static Future<void> addTask(Task task) async {
    final tasks = await loadTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  static Future<void> updateTask(Task task) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await saveTasks(tasks);
    }
  }

  static Future<void> deleteTask(String id) async {
    final tasks = await loadTasks();
    tasks.removeWhere((task) => task.id == id);
    await saveTasks(tasks);
  }
}