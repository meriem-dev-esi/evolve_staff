import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  bool _unreadOnly = false;
  List<Map<String, dynamic>> _conversations = [];
  RealtimeChannel? _messagesChannel;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _messagesChannel = _supabase
        .channel('staff_direct_messages_inbox')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_messages',
          callback: (_) {
            if (mounted) _loadConversations(showLoading: false);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_messagesChannel != null) {
      _supabase.removeChannel(_messagesChannel!);
    }
    super.dispose();
  }

  Future<void> _loadConversations({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('You are not signed in.');

      final rows = await _supabase
          .from('conversations')
          .select('id, participant_one, participant_two, created_at')
          .or('participant_one.eq.${user.id},participant_two.eq.${user.id}')
          .order('updated_at', ascending: false);
      final conversations = List<Map<String, dynamic>>.from(rows);
      final studentIds = conversations
          .map(
            (item) => item['participant_one'] == user.id
                ? item['participant_two']?.toString()
                : item['participant_one']?.toString(),
          )
          .whereType<String>()
          .toSet()
          .toList();
      final conversationIds = conversations
          .map((item) => item['id'].toString())
          .toList();

      final students = studentIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _supabase.rpc(
                'get_messaging_contact_profiles',
                params: {'p_user_ids': studentIds},
              ),
            );
      final messages = conversationIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _supabase
                  .from('direct_messages')
                  .select(
                    'conversation_id, content, created_at, sender_id, receiver_id, is_read',
                  )
                  .inFilter('conversation_id', conversationIds)
                  .order('created_at', ascending: false),
            );

      final studentById = <String, Map<String, dynamic>>{
        for (final item in students)
          if (_isStudentRole(item['role']?.toString()))
            item['id'].toString(): item,
      };
      final latestByConversation = <String, Map<String, dynamic>>{};
      final unreadByConversation = <String, int>{};
      for (final message in messages) {
        final conversationId = message['conversation_id'].toString();
        latestByConversation.putIfAbsent(conversationId, () => message);
        if (message['receiver_id'] == user.id && message['is_read'] == false) {
          unreadByConversation.update(
            conversationId,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }

      for (final conversation in conversations) {
        final studentId = conversation['participant_one'] == user.id
            ? conversation['participant_two']?.toString()
            : conversation['participant_one']?.toString();
        final student = studentId == null ? null : studentById[studentId];
        conversation['student_id'] = studentId;
        conversation['student_name'] = student?['full_name']?.toString() ?? '';
        conversation['latest_message'] =
            latestByConversation[conversation['id'].toString()]?['content']
                ?.toString() ??
            '';
        conversation['latest_message_at'] =
            latestByConversation[conversation['id'].toString()]?['created_at']
                ?.toString() ??
            conversation['created_at']?.toString();
        conversation['unread_count'] =
            unreadByConversation[conversation['id'].toString()] ?? 0;
      }

      conversations.removeWhere(
        (conversation) =>
            conversation['student_name']?.toString().isEmpty ?? true,
      );
      conversations.sort((first, second) {
        final firstDate = DateTime.tryParse(
          first['latest_message_at']?.toString() ?? '',
        );
        final secondDate = DateTime.tryParse(
          second['latest_message_at']?.toString() ?? '',
        );
        if (firstDate == null) return secondDate == null ? 0 : 1;
        if (secondDate == null) return -1;
        return secondDate.compareTo(firstDate);
      });

      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openConversation(Map<String, dynamic> conversation) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _ConversationThreadScreen(
          conversationId: conversation['id'].toString(),
          studentId: conversation['student_id'].toString(),
          studentName: conversation['student_name']?.toString() ?? 'Student',
        ),
      ),
    );
    if (mounted) await _loadConversations();
  }

  List<Map<String, dynamic>> get _filteredConversations {
    final query = _searchQuery.trim().toLowerCase();
    return _conversations.where((conversation) {
      final name = conversation['student_name']?.toString().toLowerCase() ?? '';
      final preview =
          conversation['latest_message']?.toString().toLowerCase() ?? '';
      final matchesSearch =
          query.isEmpty || name.contains(query) || preview.contains(query);
      final matchesUnread =
          !_unreadOnly || (conversation['unread_count'] as int? ?? 0) > 0;
      return matchesSearch && matchesUnread;
    }).toList();
  }

  static bool _isStudentRole(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'student':
      case 'étudiant':
      case 'étudiante':
      case 'étudiant evolve':
      case 'étudiante evolve':
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredConversations = _filteredConversations;
    final unreadCount = _conversations.fold<int>(
      0,
      (total, conversation) =>
          total + (conversation['unread_count'] as int? ?? 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Student Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Refresh messages',
            onPressed: _loading ? null : _loadConversations,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_conversations.length} conversations',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (unreadCount > 0)
                      Chip(
                        avatar: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 16,
                        ),
                        label: Text('$unreadCount unread'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search students or messages',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () => setState(() => _searchQuery = ''),
                            icon: const Icon(Icons.close),
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                FilterChip(
                  avatar: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 18,
                  ),
                  label: const Text('Unread only'),
                  selected: _unreadOnly,
                  onSelected: (selected) =>
                      setState(() => _unreadOnly = selected),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadConversations,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredConversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _conversations.isEmpty
                                ? Icons.forum_outlined
                                : Icons.search_off,
                            size: 48,
                            color: Colors.black38,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _conversations.isEmpty
                                ? 'No student conversations yet'
                                : 'No conversations match these filters',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _conversations.isEmpty
                                ? 'New conversations appear here when a student sends you a message.'
                                : 'Try another name or turn off the unread filter.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadConversations,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: filteredConversations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final conversation = filteredConversations[index];
                        final timestamp = DateTime.tryParse(
                          conversation['latest_message_at']?.toString() ?? '',
                        );
                        final unread =
                            conversation['unread_count'] as int? ?? 0;
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFEFFFD8),
                              child: Text(
                                (conversation['student_name']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ??
                                        false)
                                    ? conversation['student_name']
                                          .toString()
                                          .trim()[0]
                                          .toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: Color(0xFF65A30D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              conversation['student_name']?.toString() ??
                                  'Student',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                conversation['latest_message']
                                            ?.toString()
                                            .isNotEmpty ==
                                        true
                                    ? conversation['latest_message'].toString()
                                    : 'Conversation started — send a reply',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (timestamp != null)
                                  Text(
                                    _formatTimestamp(timestamp),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                if (unread > 0)
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF65A30D),
                                    child: Text(
                                      unread > 99 ? '99+' : '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.black45,
                                  ),
                              ],
                            ),
                            onTap: () => _openConversation(conversation),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _ConversationThreadScreen extends StatefulWidget {
  final String conversationId;
  final String studentId;
  final String studentName;

  const _ConversationThreadScreen({
    required this.conversationId,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<_ConversationThreadScreen> createState() =>
      _ConversationThreadScreenState();
}

class _ConversationThreadScreenState extends State<_ConversationThreadScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  bool _sending = false;
  String? _error;
  RealtimeChannel? _messagesChannel;

  @override
  void initState() {
    super.initState();
    _messagesStream = _supabase
        .from('direct_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: false);
    _markConversationAsRead();
    _messagesChannel = _supabase
        .channel('staff_direct_messages_${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            final user = _supabase.auth.currentUser;
            final message = payload.newRecord;
            if (user != null &&
                message['receiver_id'] == user.id &&
                message['id'] != null) {
              _markMessageAsRead(message['id'].toString());
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_messagesChannel != null) {
      _supabase.removeChannel(_messagesChannel!);
    }
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markConversationAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('direct_messages')
          .update({'is_read': true})
          .eq('conversation_id', widget.conversationId)
          .eq('receiver_id', user.id)
          .eq('is_read', false);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not mark messages as read: $error');
      }
    }
  }

  Future<void> _markMessageAsRead(String messageId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('direct_messages')
          .update({'is_read': true})
          .eq('id', messageId)
          .eq('receiver_id', user.id)
          .eq('is_read', false);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not mark message as read: $error');
      }
    }
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    final user = _supabase.auth.currentUser;
    if (body.isEmpty || _sending) return;
    if (user == null) {
      setState(() => _error = 'You are not signed in.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _supabase.from('direct_messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': user.id,
        'receiver_id': widget.studentId,
        'content': body,
      });
      _messageController.clear();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.studentName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Student conversation', style: TextStyle(fontSize: 13)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load messages: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages in this conversation yet.'),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isTeacherMessage =
                        message['sender_id'] != widget.studentId;
                    final createdAt = DateTime.tryParse(
                      message['created_at']?.toString() ?? '',
                    );
                    return Align(
                      alignment: isTeacherMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 560),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isTeacherMessage
                              ? const Color(0xFFE7F8C8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message['content']?.toString() ?? ''),
                            if (createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                createdAt.toLocal().toString().substring(0, 16),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLength: 4000,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write a reply...',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
