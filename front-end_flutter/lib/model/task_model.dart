class TaskModel {
  final String? id;
  final String title;
  final String category;
  final String by;
  final List<ChecklistItemModel> checklist;
  final DateTime timestamp;
  final bool isDeleted;

  TaskModel({
    this.id,
    required this.title,
    required this.category,
    required this.by,
    required this.checklist,
    required this.timestamp,
    this.isDeleted = false,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id']?.toString(),
      title: (map['title'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      by: (map['by'] ?? '') as String,
      checklist: (map['task_items'] ?? map['checklist'] ?? [])
          .map<ChecklistItemModel>((item) =>
              ChecklistItemModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: (map['isDeleted'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'by': by,
      'task_items': checklist.map((c) => c.toMap()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? category,
    String? by,
    List<ChecklistItemModel>? checklist,
    DateTime? timestamp,
    bool? isDeleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      by: by ?? this.by,
      checklist: checklist ?? this.checklist,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class ChecklistItemModel {
  final String task;
  final bool done;

  ChecklistItemModel({
    required this.task,
    required this.done,
  });

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map) {
    return ChecklistItemModel(
      task: (map['task'] ?? '') as String,
      done: (map['done'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'done': done,
    };
  }

  ChecklistItemModel copyWith({
    String? task,
    bool? done,
  }) {
    return ChecklistItemModel(
      task: task ?? this.task,
      done: done ?? this.done,
    );
  }
}
