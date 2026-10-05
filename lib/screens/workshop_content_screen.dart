import 'package:flutter/material.dart';
import 'package:evolve_staff/services/workshop_content_service.dart';

class WorkshopContentScreen extends StatefulWidget {
  final String workshopId;
  final String workshopTitle;
  const WorkshopContentScreen({
    super.key,
    required this.workshopId,
    required this.workshopTitle,
  });

  @override
  State<WorkshopContentScreen> createState() => _WorkshopContentScreenState();
}

class _WorkshopContentScreenState extends State<WorkshopContentScreen> {
  final _svc = WorkshopContentService();
  List<WorkshopLesson> _lessons = [];
  List<WorkshopLink> _links = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _err(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: $e')));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final l = await _svc.getLessons(widget.workshopId);
      final k = await _svc.getLinks(widget.workshopId);
      if (!mounted) return;
      setState(() {
        _lessons = l;
        _links = k;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _err(e);
    }
  }

  Future<void> _editLesson([WorkshopLesson? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'New lesson' : 'Edit lesson'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                  labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: desc,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    try {
      if (existing == null) {
        await _svc.addLesson(WorkshopLesson(
          workshopId: widget.workshopId,
          title: title.text.trim(),
          description: desc.text.trim().isEmpty ? null : desc.text.trim(),
          position: _lessons.length,
        ));
      } else {
        existing.title = title.text.trim();
        existing.description =
            desc.text.trim().isEmpty ? null : desc.text.trim();
        await _svc.updateLesson(existing);
      }
      await _load();
    } catch (e) {
      _err(e);
    }
  }

  Future<void> _reorderLessons(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _lessons.removeAt(oldIndex);
    _lessons.insert(newIndex, item);
    setState(() {});
    try {
      for (var i = 0; i < _lessons.length; i++) {
        _lessons[i].position = i;
        await _svc.updateLesson(_lessons[i]);
      }
    } catch (e) {
      _err(e);
      _load();
    }
  }

  Future<void> _deleteLesson(WorkshopLesson l) async {
    try {
      await _svc.deleteLesson(l.id!);
      await _load();
    } catch (e) {
      _err(e);
    }
  }

  Future<void> _editLink([WorkshopLink? existing]) async {
    final label = TextEditingController(text: existing?.label ?? '');
    final url = TextEditingController(text: existing?.url ?? '');
    String? lessonId = existing?.lessonId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(existing == null ? 'New link' : 'Edit link'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: label,
                decoration: const InputDecoration(
                    labelText: 'Label', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                    labelText: 'URL (https://...)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: lessonId,
                decoration: const InputDecoration(
                    labelText: 'Attach to', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('Whole workshop')),
                  ..._lessons.map((l) => DropdownMenuItem<String?>(
                      value: l.id, child: Text(l.title))),
                ],
                onChanged: (v) => setD(() => lessonId = v),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || label.text.trim().isEmpty || url.text.trim().isEmpty) {
      return;
    }
    try {
      if (existing == null) {
        await _svc.addLink(WorkshopLink(
          workshopId: widget.workshopId,
          lessonId: lessonId,
          label: label.text.trim(),
          url: url.text.trim(),
        ));
      } else {
        existing.label = label.text.trim();
        existing.url = url.text.trim();
        existing.lessonId = lessonId;
        await _svc.updateLink(existing);
      }
      await _load();
    } catch (e) {
      _err(e);
    }
  }

  Future<void> _deleteLink(WorkshopLink l) async {
    try {
      await _svc.deleteLink(l.id!);
      await _load();
    } catch (e) {
      _err(e);
    }
  }

  Widget _lessonsTab() {
    if (_lessons.isEmpty) {
      return const Center(child: Text('No lessons yet'));
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _lessons.length,
      onReorder: _reorderLessons,
      itemBuilder: (ctx, i) {
        final l = _lessons[i];
        return Card(
          key: ValueKey(l.id),
          child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(l.title),
            subtitle:
                (l.description ?? '').isEmpty ? null : Text(l.description!),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editLesson(l)),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteLesson(l)),
              const SizedBox(width: 24),
            ]),
          ),
        );
      },
    );
  }

  Widget _linksTab() {
    if (_links.isEmpty) {
      return const Center(child: Text('No links yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _links.length,
      itemBuilder: (ctx, i) {
        final l = _links[i];
        final lesson = _lessons.where((x) => x.id == l.lessonId).toList();
        return Card(
          child: ListTile(
            leading: const Icon(Icons.link),
            title: Text(l.label),
            subtitle: Text(
                '${l.url}\n${lesson.isEmpty ? 'Whole workshop' : lesson.first.title}'),
            isThreeLine: true,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editLink(l)),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteLink(l)),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        final tabs = DefaultTabController.of(context);
        return AnimatedBuilder(
          animation: tabs,
          builder: (context, _) => Scaffold(
            appBar: AppBar(
              title: Text(widget.workshopTitle),
              bottom: const TabBar(tabs: [
                Tab(text: 'Lessons', icon: Icon(Icons.play_lesson_outlined)),
                Tab(text: 'Links', icon: Icon(Icons.link)),
              ]),
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(tabs.index == 0 ? 'Add lesson' : 'Add link'),
              onPressed: () => tabs.index == 0 ? _editLesson() : _editLink(),
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(children: [_lessonsTab(), _linksTab()]),
          ),
        );
      }),
    );
  }
}