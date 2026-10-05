import 'package:supabase_flutter/supabase_flutter.dart';

class WorkshopLesson {
  final String? id;
  final String workshopId;
  String title;
  String? description;
  int position;

  WorkshopLesson({
    this.id,
    required this.workshopId,
    required this.title,
    this.description,
    this.position = 0,
  });

  factory WorkshopLesson.fromMap(Map<String, dynamic> m) => WorkshopLesson(
        id: m['id'] as String,
        workshopId: m['workshop_id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        position: (m['position'] as int?) ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'workshop_id': workshopId,
        'title': title,
        'description': description,
        'position': position,
      };
}

class WorkshopLink {
  final String? id;
  final String workshopId;
  String? lessonId;
  String label;
  String url;

  WorkshopLink({
    this.id,
    required this.workshopId,
    this.lessonId,
    required this.label,
    required this.url,
  });

  factory WorkshopLink.fromMap(Map<String, dynamic> m) => WorkshopLink(
        id: m['id'] as String,
        workshopId: m['workshop_id'] as String,
        lessonId: m['lesson_id'] as String?,
        label: m['label'] as String,
        url: m['url'] as String,
      );

  Map<String, dynamic> toMap() => {
        'workshop_id': workshopId,
        'lesson_id': lessonId,
        'label': label,
        'url': url,
      };
}

class WorkshopContentService {
  final _db = Supabase.instance.client;

  // ---------- Lessons ----------
  Future<List<WorkshopLesson>> getLessons(String workshopId) async {
    final rows = await _db
        .from('workshop_lessons')
        .select()
        .eq('workshop_id', workshopId)
        .order('position');
    return (rows as List).map((r) => WorkshopLesson.fromMap(r)).toList();
  }

  Future<void> addLesson(WorkshopLesson l) =>
      _db.from('workshop_lessons').insert(l.toMap());

  Future<void> updateLesson(WorkshopLesson l) =>
      _db.from('workshop_lessons').update(l.toMap()).eq('id', l.id!);

  Future<void> deleteLesson(String id) =>
      _db.from('workshop_lessons').delete().eq('id', id);

  // ---------- Links ----------
  Future<List<WorkshopLink>> getLinks(String workshopId) async {
    final rows = await _db
        .from('workshop_links')
        .select()
        .eq('workshop_id', workshopId)
        .order('created_at');
    return (rows as List).map((r) => WorkshopLink.fromMap(r)).toList();
  }

  Future<void> addLink(WorkshopLink l) =>
      _db.from('workshop_links').insert(l.toMap());

  Future<void> updateLink(WorkshopLink l) =>
      _db.from('workshop_links').update(l.toMap()).eq('id', l.id!);

  Future<void> deleteLink(String id) =>
      _db.from('workshop_links').delete().eq('id', id);
}
