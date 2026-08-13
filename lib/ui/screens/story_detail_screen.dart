import 'package:flutter/material.dart';

import '../../data/models/app_bootstrap.dart';
import '../../data/services/api_service.dart';
import 'chapter_reader_screen.dart';

/// Story detail page (Inkitt-style). Full version also in project artifacts.
class StoryDetailScreen extends StatefulWidget {
  const StoryDetailScreen({
    super.key,
    required this.book,
    required this.apiService,
  });

  final BookDetailModel book;
  final ApiService apiService;

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  late BookDetailModel _book;
  bool _loading = true;
  List<Map<String, dynamic>> _chapters = const [];
  List<Map<String, dynamic>> _reviews = const [];
  int _likesCount = 0;
  bool _liked = false;
  bool _isFollowing = false;
  bool _summaryExpanded = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final detail = await widget.apiService.fetchPublicBook(_book.id);
      if (detail != null && mounted) {
        setState(() => _book = BookDetailModel.fromMap(detail));
      }
      final chapters = await widget.apiService.fetchStoryChapters(_book.id);
      final reviews = await widget.apiService.fetchBookReviews(_book.id);
      try {
        final likeState = await widget.apiService.fetchBookLike(_book.id);
        if (mounted) {
          _liked = (likeState['liked'] as bool?) ?? false;
          _likesCount = (likeState['likes_count'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}
      if (_book.authorUserId != null) {
        try {
          _isFollowing =
              await widget.apiService.fetchAuthorFollowing(_book.authorUserId!);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _reviews = reviews;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openChapter(Map<String, dynamic> chapter, {int index = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChapterReaderScreen(
          apiService: widget.apiService,
          title: _book.title,
          author: _book.author,
          coverPath: _book.coverPath,
          chapterNumber: (chapter['chapter_number'] as num?)?.toInt() ?? 1,
          chapterTitle: chapter['title'] as String? ?? 'Chapter',
          chapterContent: chapter['content'] as String? ?? '',
          bookId: _book.id,
          chapters: _chapters,
          initialChapterIndex: index,
        ),
      ),
    );
  }

  Future<void> _readNow() async {
    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No chapters yet')),
      );
      return;
    }
    try {
      await widget.apiService.addLibraryEntry({
        'book_id': _book.id,
        'reading_status': 'Reading',
        'updated_text': 'Just started',
        'chapters': _chapters.length,
        'primary_genre': _book.genre,
        'secondary_genre': '',
        'sort_order': 0,
      });
    } catch (_) {}
    if (!mounted) return;
    _openChapter(_chapters.first);
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _book.coverPath.isEmpty
        ? null
        : widget.apiService.resolveAssetUrl(_book.coverPath);
    final summary =
        _book.description.isEmpty ? 'No summary available.' : _book.description;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: coverUrl == null
                            ? Container(
                                width: 160,
                                height: 230,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.menu_book, size: 48),
                              )
                            : Image.network(
                                coverUrl,
                                width: 160,
                                height: 230,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 160,
                                  height: 230,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      children: [
                        Text(
                          _book.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        if (_book.author.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'by ${_book.author}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat('Chapters', '${_chapters.length}'),
                        _stat(
                          'Status',
                          _book.statusText.isNotEmpty
                              ? _book.statusText
                              : 'Ongoing',
                        ),
                        _stat('Reviews', '${_reviews.length}'),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          summary,
                          maxLines: _summaryExpanded ? null : 4,
                          overflow: _summaryExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                        TextButton(
                          onPressed: () => setState(
                            () => _summaryExpanded = !_summaryExpanded,
                          ),
                          child: Text(
                            _summaryExpanded ? 'Show less' : 'Read More',
                            style: const TextStyle(
                              color: Color(0xFF00C853),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              final res = _liked
                                  ? await widget.apiService
                                      .unlikeBook(_book.id)
                                  : await widget.apiService.likeBook(_book.id);
                              if (!mounted) return;
                              setState(() {
                                _liked = (res['liked'] as bool?) ?? !_liked;
                                _likesCount =
                                    (res['likes_count'] as num?)?.toInt() ??
                                        _likesCount;
                              });
                            } catch (_) {}
                          },
                          icon: Icon(
                            _liked ? Icons.favorite : Icons.favorite_border,
                            color: _liked ? Colors.red : null,
                          ),
                          label: Text(
                            _likesCount > 0
                                ? '$_likesCount Likes'
                                : 'Likes',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              final lists =
                                  await widget.apiService.fetchReadingLists();
                              if (!mounted || lists.isEmpty) return;
                              final id =
                                  (lists.first['id'] as num?)?.toInt() ?? 0;
                              if (id > 0) {
                                await widget.apiService
                                    .addReadingListItem(id, _book.id);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Saved')),
                                );
                              }
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.bookmark_border),
                          label: const Text('Save'),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.star_border),
                          label: Text('${_reviews.length} Reviews'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_book.author.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              _book.author.isNotEmpty
                                  ? _book.author[0].toUpperCase()
                                  : 'A',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _book.author,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_book.authorUserId != null)
                            OutlinedButton(
                              onPressed: () async {
                                try {
                                  if (_isFollowing) {
                                    await widget.apiService
                                        .unfollowAuthor(_book.authorUserId!);
                                  } else {
                                    await widget.apiService
                                        .followAuthor(_book.authorUserId!);
                                  }
                                  if (mounted) {
                                    setState(
                                      () => _isFollowing = !_isFollowing,
                                    );
                                  }
                                } catch (_) {}
                              },
                              child: Text(
                                _isFollowing ? 'Following' : 'Follow',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Chapters (${_chapters.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chapter = _chapters[index];
                      final title =
                          chapter['title'] as String? ?? 'Untitled';
                      final number =
                          (chapter['chapter_number'] as num?)?.toInt() ??
                              index + 1;
                      return ListTile(
                        leading: Text('$number'),
                        title: Text(title),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openChapter(chapter, index: index),
                      );
                    },
                    childCount: _chapters.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _readNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Read Now',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
