import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/task_model.dart';

/// Where [TaskRepository] keeps tasks.
abstract class TaskStore {
  /// Tasks available right away (null when they arrive via [listen]).
  List<TaskModel>? get initial;

  /// Calls [onChange] with the full list whenever it changes remotely.
  void listen(void Function(List<TaskModel> tasks) onChange) {}

  Future<void> save(TaskModel task, List<TaskModel> all);

  Future<void> delete(String id, List<TaskModel> all);

  void dispose() {}
}

/// Tasks saved on this device (offline demo).
class LocalTaskStore extends TaskStore {
  LocalTaskStore(this._storage, {required this._samples});

  static const _key = 'tasks';

  final StorageService _storage;
  final List<TaskModel> Function() _samples;

  @override
  List<TaskModel> get initial {
    final saved = _storage.readList(_key);
    return saved == null ? _samples() : saved.map(TaskModel.fromJson).toList();
  }

  @override
  Future<void> save(TaskModel task, List<TaskModel> all) => _write(all);

  @override
  Future<void> delete(String id, List<TaskModel> all) => _write(all);

  Future<void> _write(List<TaskModel> all) =>
      _storage.writeList(_key, all.map((t) => t.toJson()).toList());
}

/// The signed-in user's private tasks in Firestore at `users/{uid}/tasks`.
/// Firestore's offline cache keeps them usable without a connection.
class FirestoreTaskStore extends TaskStore {
  FirestoreTaskStore(this.uid, {this._firestore});

  final String uid;
  final FirebaseFirestore? _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      (_firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(uid)
          .collection('tasks');

  @override
  List<TaskModel>? get initial => null;

  @override
  void listen(void Function(List<TaskModel> tasks) onChange) {
    _sub = _tasks.snapshots().listen((snapshot) {
      final tasks = <TaskModel>[];
      for (final doc in snapshot.docs) {
        try {
          tasks.add(TaskModel.fromJson({...doc.data(), 'id': doc.id}));
        } catch (e) {
          debugPrint('Skipping unreadable task ${doc.id}: $e');
        }
      }
      onChange(tasks);
    }, onError: (Object e) => debugPrint('Tasks unavailable: $e'));
  }

  @override
  Future<void> save(TaskModel task, List<TaskModel> all) =>
      _tasks.doc(task.id).set(task.toJson());

  @override
  Future<void> delete(String id, List<TaskModel> all) =>
      _tasks.doc(id).delete();

  @override
  void dispose() => _sub?.cancel();
}

/// No tasks; used while signed out.
class EmptyTaskStore extends TaskStore {
  @override
  List<TaskModel> get initial => [];

  @override
  Future<void> save(TaskModel task, List<TaskModel> all) async {}

  @override
  Future<void> delete(String id, List<TaskModel> all) async {}
}
