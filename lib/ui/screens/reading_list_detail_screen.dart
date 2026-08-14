import 'package:flutter/material.dart';

import '../../data/models/app_bootstrap.dart';
import '../../data/services/api_service.dart';
import 'story_detail_screen.dart';

/// Shows stories inside a reading list. Tap a story → story detail.
class ReadingListDetailScreen extends StatefulWidget {
  const ReadingListDetailScreen({
    super.key,
    required this.apiService,
    required this.listId,
    required this.listName,
  });

  final ApiService apiService;
  final int listId;
  final String listName;

  @override
  State<ReadingListDetailScreen> createState() =>
      _ReadingListDetailScreenState();
}

class _ReadingListDetailScreenState extends State<ReadingListDetailScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];
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
      final items = await widget.apiService.fetchReadingListItems(widget.listId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this list';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.listName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A88E)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Text(
                        'No stories in this list yet',
                        style: TextStyle(color: Color(0xFF8A8F98)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (context, i) {
                        final s = _items[i];
                        final title =
                            (s['title'] ?? s['book_title'] ?? 'Story').toString();
                        final author =
                            (s['author'] ?? s['book_author'] ?? '').toString();
                        final cover =
                            (s['cover_path'] ?? s['cover_url'] ?? '').toString();
                        final bookId = (s['book_id'] as num?)?.toInt() ??
                            (s['id'] as num?)?.toInt() ??
                            0;
                        final coverUrl = cover.isEmpty
                            ? null
                            : widget.apiService.resolveAssetUrl(cover);
                        return InkWell(
                          onTap: bookId <= 0
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => StoryDetailScreen(
                                        apiService: widget.apiService,
                                        book: BookDetailModel.fromMap({
                                          ...s,
                                          'id': bookId,
                                          'title': title,
                                          'author': author,
                                          'cover_path': cover,
                                        }),
                                      ),
                                    ),
                                  );
                                },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: coverUrl == null
                                    ? Container(
                                        width: 64,
                                        height: 90,
                                        color: const Color(0xFFF0F1F3),
                                        child: const Icon(Icons.menu_book),
                                      )
                                    : Image.network(
                                        coverUrl,
                                        width: 64,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          width: 64,
                                          height: 90,
                                          color: const Color(0xFFF0F1F3),
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (author.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'by $author',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF8A8F98),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Color(0xFF8A8F98)),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
