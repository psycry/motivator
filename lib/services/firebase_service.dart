import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

// NOTE: Firebase requires an index on 'dateKey' field for efficient queries.
// If you get an error about missing index, Firebase will provide a link to create it.

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
    final taskData = task.toMap();
    taskData['dateKey'] = dateKey; // Add dateKey for querying
    await _tasksCollection.doc('${dateKey}_${task.id}').set(taskData);
    print('Saved task ${task.id} with dateKey $dateKey to document ${dateKey}_${task.id}');
  }

  // Delete a task
  Future<void> deleteTask(String taskId, DateTime date) async {
    final dateKey = _dateToKey(date);
    await _tasksCollection.doc('${dateKey}_$taskId').delete();
  }

  // Load tasks for a specific date
  Future<List<Task>> loadTasksForDate(DateTime date) async {
    final dateKey = _dateToKey(date);
    print('Loading tasks for date $date with dateKey $dateKey');
    final querySnapshot = await _tasksCollection
        .where('dateKey', isEqualTo: dateKey)
        .get();

    print('Found ${querySnapshot.docs.length} tasks for dateKey $dateKey');
    return querySnapshot.docs
        .map((doc) {
          print('  - Task: ${doc.id}');
          return Task.fromMap(doc.data() as Map<String, dynamic>);
        })
        .toList();
  }

  // Load all tasks (for getting task counts)
  Future<Map<DateTime, List<Task>>> loadAllTasks() async {
    print('Loading all tasks from Firebase...');
    final querySnapshot = await _tasksCollection.get();
    print('Found ${querySnapshot.docs.length} total task documents');
    final Map<DateTime, List<Task>> tasksByDate = {};

    for (var doc in querySnapshot.docs) {
      print('  - Document: ${doc.id}');
      final task = Task.fromMap(doc.data() as Map<String, dynamic>);
      final date = _normalizeDate(task.startTime);
      
      if (!tasksByDate.containsKey(date)) {
        tasksByDate[date] = [];
      }
      tasksByDate[date]!.add(task);
    }

    print('Loaded tasks for ${tasksByDate.length} dates');
    return tasksByDate;
  }

  // Stream tasks for a specific date (real-time updates)
  Stream<List<Task>> streamTasksForDate(DateTime date) {
    final dateKey = _dateToKey(date);
    return _tasksCollection
        .where('dateKey', isEqualTo: dateKey)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Save side tasks (tasks not yet assigned to timeline)
  Future<void> saveSideTask(Task task) async {
    print('Saving side task ${task.id} (${task.title})');
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('sideTasks')
        .doc(task.id)
        .set(task.toMap());
    print('Side task saved successfully');
  }

  // Load side tasks
  Future<List<Task>> loadSideTasks() async {
    print('Loading side tasks from Firebase...');
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('sideTasks')
        .get();

    print('Found ${querySnapshot.docs.length} side tasks');
    return querySnapshot.docs
        .map((doc) {
          print('  - Side task: ${doc.id}');
          return Task.fromMap(doc.data() as Map<String, dynamic>);
        })
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
    try {
      final batch = _firestore.batch();
      final dateKey = _dateToKey(date);
      print('=== SAVING TASKS TO FIREBASE ===');
      print('User ID: $userId');
      print('Date: $date');
      print('DateKey: $dateKey');
      print('Number of tasks: ${tasks.length}');

      // Delete existing tasks for this date
      final existingDocs = await _tasksCollection
          .where('dateKey', isEqualTo: dateKey)
          .get();
      
      print('Deleting ${existingDocs.docs.length} existing tasks');
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Add new tasks
      for (var task in tasks) {
        final docRef = _tasksCollection.doc('${dateKey}_${task.id}');
        final taskData = task.toMap();
        taskData['dateKey'] = dateKey; // Add dateKey for querying
        batch.set(docRef, taskData);
        print('  - Adding task ${task.id} (${task.title}) to document ${dateKey}_${task.id}');
        print('    Task data: ${taskData.toString().substring(0, 100)}...');
      }

      await batch.commit();
      print('✓ Batch commit completed successfully');
      print('=== SAVE COMPLETE ===');
    } catch (e) {
      print('❌ Error saving tasks: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Batch save side tasks
  Future<void> saveSideTasks(List<Task> tasks) async {
    try {
      print('=== SAVING SIDE TASKS TO FIREBASE ===');
      print('User ID: $userId');
      print('Number of side tasks: ${tasks.length}');
      
      final batch = _firestore.batch();
      final sideTasksCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('sideTasks');

      // Delete all existing side tasks
      final existingDocs = await sideTasksCollection.get();
      print('Deleting ${existingDocs.docs.length} existing side tasks');
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Add new side tasks
      for (var task in tasks) {
        final docRef = sideTasksCollection.doc(task.id);
        final taskData = task.toMap();
        batch.set(docRef, taskData);
        print('  - Adding side task ${task.id} (${task.title})');
      }

      await batch.commit();
      print('✓ Side tasks batch commit completed successfully');
      print('=== SIDE TASKS SAVE COMPLETE ===');
    } catch (e) {
      print('❌ Error saving side tasks: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
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

  // Save notes
  Future<void> saveNotes(String notes) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc('scratch_notes')
          .set({
        'content': notes,
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving notes: $e');
      rethrow;
    }
  }

  // Load notes
  Future<String> loadNotes() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc('scratch_notes')
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        return data?['content'] as String? ?? '';
      }
      return '';
    } catch (e) {
      print('Error loading notes: $e');
      return '';
    }
  }
}
