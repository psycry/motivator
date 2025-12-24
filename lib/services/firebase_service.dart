import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  FirebaseService({required this.userId});

  // Get reference to user's tasks collection
  CollectionReference get _tasksCollection =>
      _firestore.collection('users').doc(userId).collection('tasks');

  // Save or update a task
  Future<void> saveTask(Task task, DateTime date) async {
    final dateKey = _dateToKey(date);
    await _tasksCollection.doc('${dateKey}_${task.id}').set(task.toMap());
  }

  // Delete a task
  Future<void> deleteTask(String taskId, DateTime date) async {
    final dateKey = _dateToKey(date);
    await _tasksCollection.doc('${dateKey}_$taskId').delete();
  }

  // Load tasks for a specific date
  Future<List<Task>> loadTasksForDate(DateTime date) async {
    final dateKey = _dateToKey(date);
    final querySnapshot = await _tasksCollection
        .where('id', isGreaterThanOrEqualTo: dateKey)
        .where('id', isLessThan: '${dateKey}_z')
        .get();

    return querySnapshot.docs
        .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Load all tasks (for getting task counts)
  Future<Map<DateTime, List<Task>>> loadAllTasks() async {
    final querySnapshot = await _tasksCollection.get();
    final Map<DateTime, List<Task>> tasksByDate = {};

    for (var doc in querySnapshot.docs) {
      final task = Task.fromMap(doc.data() as Map<String, dynamic>);
      final date = _normalizeDate(task.startTime);
      
      if (!tasksByDate.containsKey(date)) {
        tasksByDate[date] = [];
      }
      tasksByDate[date]!.add(task);
    }

    return tasksByDate;
  }

  // Stream tasks for a specific date (real-time updates)
  Stream<List<Task>> streamTasksForDate(DateTime date) {
    final dateKey = _dateToKey(date);
    return _tasksCollection
        .where('id', isGreaterThanOrEqualTo: dateKey)
        .where('id', isLessThan: '${dateKey}_z')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Save side tasks (tasks not yet assigned to timeline)
  Future<void> saveSideTask(Task task) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('sideTasks')
        .doc(task.id)
        .set(task.toMap());
  }

  // Load side tasks
  Future<List<Task>> loadSideTasks() async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('sideTasks')
        .get();

    return querySnapshot.docs
        .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Delete side task
  Future<void> deleteSideTask(String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('sideTasks')
        .doc(taskId)
        .delete();
  }

  // Helper methods
  String _dateToKey(DateTime date) {
    final normalized = _normalizeDate(date);
    return '${normalized.year}${normalized.month.toString().padLeft(2, '0')}${normalized.day.toString().padLeft(2, '0')}';
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Batch save tasks for a date
  Future<void> saveTasksForDate(DateTime date, List<Task> tasks) async {
    final batch = _firestore.batch();
    final dateKey = _dateToKey(date);

    // Delete existing tasks for this date
    final existingDocs = await _tasksCollection
        .where('id', isGreaterThanOrEqualTo: dateKey)
        .where('id', isLessThan: '${dateKey}_z')
        .get();
    
    for (var doc in existingDocs.docs) {
      batch.delete(doc.reference);
    }

    // Add new tasks
    for (var task in tasks) {
      final docRef = _tasksCollection.doc('${dateKey}_${task.id}');
      batch.set(docRef, task.toMap());
    }

    await batch.commit();
  }

  // Batch save side tasks
  Future<void> saveSideTasks(List<Task> tasks) async {
    final batch = _firestore.batch();
    final sideTasksCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('sideTasks');

    // Delete all existing side tasks
    final existingDocs = await sideTasksCollection.get();
    for (var doc in existingDocs.docs) {
      batch.delete(doc.reference);
    }

    // Add new side tasks
    for (var task in tasks) {
      final docRef = sideTasksCollection.doc(task.id);
      batch.set(docRef, task.toMap());
    }

    await batch.commit();
  }

  // Clear all tasks and side tasks for the user
  Future<void> clearAllTasks() async {
    final batch = _firestore.batch();

    // Delete all tasks
    final tasksDocs = await _tasksCollection.get();
    for (var doc in tasksDocs.docs) {
      batch.delete(doc.reference);
    }

    // Delete all side tasks
    final sideTasksCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('sideTasks');
    final sideTasksDocs = await sideTasksCollection.get();
    for (var doc in sideTasksDocs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
