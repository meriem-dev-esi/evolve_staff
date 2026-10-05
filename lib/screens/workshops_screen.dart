import 'package:flutter/material.dart';

import '../services/workshop_service.dart';

const _lime = Color(0xFF84CC16);

const _domains = [
  'Career Skills',
  'Cloud & DevOps',
  'Cybersecurity',
  'Data & AI',
  'Design',
  'Mobile Development',
  'Web Development',
];

// Check your existing rows in Supabase and adjust these to match exactly.
const _levels = ['Débutant', 'Intermédiaire', 'Avancé'];

class WorkshopsScreen extends StatefulWidget {
  const WorkshopsScreen({super.key});

  @override
  State<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends State<WorkshopsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await WorkshopService.fetchAll();
      if (!mounted) return;
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openForm([Map<String, dynamic>? workshop]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _WorkshopFormDialog(workshop: workshop),
    );
    if (saved == true) {
      _snack(workshop == null ? 'Workshop created' : 'Workshop updated');
      await _load();
    }
  }

  Future<void> _togglePublished(Map<String, dynamic> w, bool value) async {
    try {
      await WorkshopService.setPublished(w['id'], value);
      setState(() => w['is_published'] = value);
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _delete(Map<String, dynamic> w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workshop'),
        content: Text('Delete "${w['title']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await WorkshopService.delete(w['id']);
      _snack('Workshop deleted');
      await _load();
    } catch (e) {
      _snack('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF212121),
        elevation: 0,
        title: const Text(
          'Workshops',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: Colors.black,
              ),
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('New workshop'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unable to load workshops: $_error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _items.isEmpty
          ? const Center(
              child: Text(
                'No workshops yet. Click "New workshop" to create one.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _row(_items[i]),
            ),
    );
  }

  Widget _row(Map<String, dynamic> w) {
    final image = w['image_url']?.toString() ?? '';
    final published = w['is_published'] == true;
    final price = num.tryParse('${w['price'] ?? 0}') ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 88,
              height: 60,
              child: image.isEmpty
                  ? Container(
                      color: const Color(0xFFEFFFD8),
                      child: const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF65A30D),
                      ),
                    )
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w['title']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${w['domain'] ?? '-'} · ${w['level'] ?? '-'} · ${w['duration'] ?? '-'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              price == 0 ? 'Gratuit' : '${price.toStringAsFixed(0)} DA',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            published ? 'Published' : 'Draft',
            style: TextStyle(
              fontSize: 12,
              color: published ? const Color(0xFF65A30D) : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch(
            value: published,
            activeColor: _lime,
            onChanged: (v) => _togglePublished(w, v),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openForm(w),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _delete(w),
          ),
        ],
      ),
    );
  }
}

class _WorkshopFormDialog extends StatefulWidget {
  final Map<String, dynamic>? workshop;
  const _WorkshopFormDialog({this.workshop});

  @override
  State<_WorkshopFormDialog> createState() => _WorkshopFormDialogState();
}

class _WorkshopFormDialogState extends State<_WorkshopFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _image;
  late final TextEditingController _duration;
  late final TextEditingController _price;
  String? _domain;
  String? _level;
  bool _published = false;
  bool _saving = false;

  bool get _isEdit => widget.workshop != null;

  @override
  void initState() {
    super.initState();
    final w = widget.workshop;
    _title = TextEditingController(text: w?['title']?.toString() ?? '');
    _description = TextEditingController(
      text: w?['description']?.toString() ?? '',
    );
    _image = TextEditingController(text: w?['image_url']?.toString() ?? '');
    _duration = TextEditingController(text: w?['duration']?.toString() ?? '');
    final p = num.tryParse('${w?['price'] ?? ''}');
    _price = TextEditingController(text: p == null ? '' : p.toString());
    _domain = w?['domain']?.toString();
    _level = w?['level']?.toString();
    _published = w?['is_published'] == true;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _image.dispose();
    _duration.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'image_url': _image.text.trim().isEmpty ? null : _image.text.trim(),
      'duration': _duration.text.trim(),
      'level': _level,
      'domain': _domain,
      'price': num.tryParse(_price.text.trim()) ?? 0,
      'is_published': _published,
    };
    try {
      if (_isEdit) {
        await WorkshopService.update(widget.workshop!['id'], data);
      } else {
        await WorkshopService.create(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  List<String> _withCurrent(List<String> base, String? current) =>
      current != null && current.isNotEmpty && !base.contains(current)
      ? [...base, current]
      : base;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder();
    return AlertDialog(
      title: Text(_isEdit ? 'Edit workshop' : 'New workshop'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: border,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: border,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _image,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: border,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_image.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _image.text.trim(),
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 40,
                        child: Center(child: Text('Preview unavailable')),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _domain,
                  decoration: const InputDecoration(
                    labelText: 'Domain',
                    border: border,
                  ),
                  items: _withCurrent(_domains, _domain)
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _domain = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _level,
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    border: border,
                  ),
                  items: _withCurrent(_levels, _level)
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _level = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _duration,
                        decoration: const InputDecoration(
                          labelText: 'Duration (e.g. 2 jours)',
                          border: border,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (DA)',
                          border: border,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return num.tryParse(v.trim()) == null
                              ? 'Invalid number'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: _lime,
                  title: const Text('Published (visible to students)'),
                  value: _published,
                  onChanged: (v) => setState(() => _published = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _lime,
            foregroundColor: Colors.black,
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
