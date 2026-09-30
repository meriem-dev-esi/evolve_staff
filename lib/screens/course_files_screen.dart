import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseFilesScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseFilesScreen({super.key, required this.course});

  @override
  State<CourseFilesScreen> createState() => _CourseFilesScreenState();
}

class _CourseFilesScreenState extends State<CourseFilesScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  bool uploading = false;
  String? error;
  List<Map<String, dynamic>> files = [];

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final courseId = widget.course['id'].toString();
      final res = await supabase
          .from('course_files')
          .select('*')
          .eq('course_id', courseId)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        files = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.any,
      );

      if (result == null) return;

      final file = result.files.single;

      if (file.bytes == null) {
        throw Exception('Could not read the selected file.');
      }

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('You are not logged in.');
      }

      setState(() {
        uploading = true;
      });

      final courseId = widget.course['id'].toString();
      final filePath = '$courseId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      // Upload to Supabase Storage
      await supabase.storage
          .from('course-files')
          .uploadBinary(
            filePath,
            file.bytes!,
            fileOptions: const FileOptions(upsert: false),
          );

      // Save file record in database
      await supabase.from('course_files').insert({
        'course_id': courseId,
        'teacher_id': user.id,
        'file_name': file.name,
        'file_path': filePath,
        'file_type': file.extension,
        'file_size': file.size,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload successful: ${file.name}'),
          backgroundColor: const Color(0xFF65A30D),
        ),
      );

      await loadFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          uploading = false;
        });
      }
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> item) async {
    final fileName = item['file_name']?.toString() ?? 'file';
    final filePath = item['file_path']?.toString();
    final fileId = item['id'].toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (filePath != null && filePath.isNotEmpty) {
        try {
          await supabase.storage.from('course-files').remove([filePath]);
        } catch (_) {}
      }
      await supabase.from('course_files').delete().eq('id', fileId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File "$fileName" deleted.')));
      await loadFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  IconData _getFileIcon(String? ext) {
    final e = (ext ?? '').toLowerCase();
    if (e == 'pdf') return Icons.picture_as_pdf_outlined;
    if (['doc', 'docx', 'txt'].contains(e)) return Icons.description_outlined;
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(e)) return Icons.image_outlined;
    if (['zip', 'rar', '7z', 'tar'].contains(e)) return Icons.folder_zip_outlined;
    if (['mp4', 'mov', 'avi'].contains(e)) return Icons.video_file_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String _formatFileSize(dynamic size) {
    if (size == null) return '';
    final bytes = size is num ? size.toDouble() : double.tryParse(size.toString()) ?? 0;
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final courseTitle = widget.course['title']?.toString() ?? 'Course Files';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Course Files', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadFiles,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: uploading ? null : _pickAndUploadFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              icon: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.upload_file, size: 18),
              label: Text(uploading ? 'Uploading...' : 'Upload File', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(courseTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Manage syllabus, slides, worksheets, and downloadable resources.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFEFFFD8), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${files.length} file${files.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Color(0xFF65A30D), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              Text('Error loading files: $error', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: loadFiles, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : files.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_open_outlined, size: 60, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text('No files uploaded yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text('Upload PDFs, presentation decks, or project code.', style: TextStyle(color: Colors.grey.shade600)),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: uploading ? null : _pickAndUploadFile,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: Colors.black),
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Upload First File'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: files.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final f = files[index];
                                final name = f['file_name']?.toString() ?? 'File';
                                final ext = f['file_type']?.toString();
                                final sizeStr = _formatFileSize(f['file_size']);
                                final dateStr = f['created_at'] != null ? f['created_at'].toString().substring(0, 10) : '';

                                return Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: const Color(0xFFEFFFD8), borderRadius: BorderRadius.circular(10)),
                                      child: Icon(_getFileIcon(ext), color: const Color(0xFF65A30D)),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      [if (sizeStr.isNotEmpty) sizeStr, if (dateStr.isNotEmpty) 'Uploaded $dateStr'].join('  •  '),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Delete File',
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteFile(f),
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
