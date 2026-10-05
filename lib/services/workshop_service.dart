import 'package:supabase_flutter/supabase_flutter.dart';

class WorkshopService {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchAll() async {
    final res = await _db
        .from('workshops')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> create(Map<String, dynamic> data) async {
    await _db.from('workshops').insert(data);
  }

  static Future<void> update(dynamic id, Map<String, dynamic> data) async {
    await _db.from('workshops').update(data).eq('id', id);
  }

  static Future<void> setPublished(dynamic id, bool value) async {
    await _db.from('workshops').update({'is_published': value}).eq('id', id);
  }

  static Future<void> delete(dynamic id) async {
    await _db.from('workshops').delete().eq('id', id);
  }
}
