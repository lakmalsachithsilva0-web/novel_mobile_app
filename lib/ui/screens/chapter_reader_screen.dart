import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/api_service.dart';

/// Inkitt-style chapter reader: themes, reactions, next chapter, chapter drawer.
class ChapterReaderScreen extends StatefulWidget {
  const ChapterReaderScreen({
    super.key,
    required this.apiService,
    required this.title,
    required this.author,
    required this.coverPath,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.chapterContent,
    this.bookId,
    this.tags = const [],
    this.authorUserId,
    this.chapters = const [],
    this.initialChapterIndex = 0,
  });

  final ApiService apiService;
  final String title;
  final String author;
  final String coverPath;
  final int chapterNumber;
  final String chapterTitle;
  final String chapterContent;
  final int? bookId;
  final List<String> tags;
  final int? authorUserId;
  final List<Map<String, dynamic>> chapters;
  final int initialChapterIndex;

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

enum _ReaderTheme { white, eggshell, nightowl }

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  late int _chapterIndex;
  late List<Map<String, dynamic>> _chapters;
  late String _chapterTitle;
  late String _chapterContent;
  late int _chapterNumber;

  _ReaderTheme _theme = _ReaderTheme.white;
  double _fontSize = 17;
  bool _showThemePanel = false;
  final Set<String> _selectedReactions = {};
  bool _liked = false;
  int _likeCount = 0;

  static const _reactionOptions = <List<String>>[
    ['❤️', 'Love this'],
    ['😂', 'Funny'],
    ['🌶️', 'Spicy'],
    ['😨', 'Suspenseful'],
    ['😢', 'Emotional'],
    ['🤔', 'Profound'],
    ['🥰', 'Heartwarming'],
    ['😲', 'Shocking'],
    ['✍️', 'Good Writing'],
    ['📖', 'Compelling Plot'],
    ['🎭', 'Great Character'],
    ['💬', 'Strong Dialog'],
  ];

  @override
  void initState() {
    super.initState();
    _chapters = List<Map<String, dynamic>>.from(widget.chapters);
    _loadLikeState();
    _chapterIndex = widget.initialChapterIndex.clamp(
      0,
      _chapters.isEmpty ? 0 : _chapters.length - 1,
    );
    if (_chapters.isNotEmpty) {
      _applyChapter(_chapters[_chapterIndex]);
    } else {
      _chapterTitle = widget.chapterTitle;
      _chapterContent = widget.chapterContent;
      _chapterNumber = widget.chapterNumber;
    }
    _loadChaptersIfNeeded();
  }

  Future<void> _loadChaptersIfNeeded() async {
    if (_chapters.isNotEmpty || widget.bookId == null) return;
    try {
      final list = await widget.apiService.fetchStoryChapters(widget.bookId!);
      if (!mounted || list.isEmpty) return;
      setState(() {
        _chapters = list;
        if (_chapterIndex >= _chapters.length) {
          _chapterIndex = _chapters.length - 1;
        }
        _applyChapter(_chapters[_chapterIndex]);
      });
    } catch (_) {}
  }

  void _applyChapter(Map<String, dynamic> chapter) {
    _chapterTitle = chapter['title'] as String? ?? 'Untitled';
    _chapterContent = chapter['content'] as String? ?? '';
    _chapterNumber = (chapter['chapter_number'] as num?)?.toInt() ??
        (_chapterIndex + 1);
  }

  Color get _bg {
    switch (_theme) {
      case _ReaderTheme.white:
        return Colors.white;
      case _ReaderTheme.eggshell:
        return const Color(0xFFF5F0E8);
      case _ReaderTheme.nightowl:
        return const Color(0xFF1A1A1A);
    }
  }

  Color get _fg {
    return _theme == _ReaderTheme.nightowl ? Colors.white : Colors.black87;
  }

  Color get _muted {
    return _theme == _ReaderTheme.nightowl
        ? Colors.white60
        : Colors.black54;
  }

  Future<void> _loadLikeState() async {
    final bookId = widget.bookId;
    if (bookId == null) return;
    try {
      final res = await widget.apiService.fetchBookLike(bookId);
      if (!mounted) return;
      setState(() {
        _liked = (res['liked'] as bool?) ?? false;
        _likeCount = (res['likes_count'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final bookId = widget.bookId;
    if (bookId == null) {
      setState(() {
        _liked = !_liked;
        _likeCount += _liked ? 1 : -1;
        if (_likeCount < 0) _likeCount = 0;
      });
      return;
    }
    try {
      final res = _liked
          ? await widget.apiService.unlikeBook(bookId)
          : await widget.apiService.likeBook(bookId);
      if (!mounted) return;
      setState(() {
        _liked = (res['liked'] as bool?) ?? !_liked;
        _likeCount = (res['likes_count'] as num?)?.toInt() ?? _likeCount;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to like. One like per account.')),
      );
    }
  }

  Future<void> _share() async {
    final text =
        'Read ${widget.title} by ${widget.author} — Chapter $_chapterNumber: $_chapterTitle';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Story link copied — share it anywhere')),
    );
  }

  void _openChapterDrawer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _chapters.isEmpty ? 1 : _chapters.length,
                    itemBuilder: (_, i) {
                      if (_chapters.isEmpty) {
                        return ListTile(
                          title: Text(_chapterTitle),
                          subtitle: Text('Chapter $_chapterNumber'),
                        );
                      }
                      final c = _chapters[i];
                      final num = (c['chapter_number'] as num?)?.toInt() ?? i + 1;
                      final title = c['title'] as String? ?? 'Chapter $num';
                      final selected = i == _chapterIndex;
                      return ListTile(
                        selected: selected,
                        title: Text(title),
                        subtitle: Text('Chapter $num'),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _chapterIndex = i;
                            _applyChapter(c);
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

<<<<<<< HEAD
  Future<void> _share() async {
    final text =
        'Read ${widget.title} by ${widget.author} — Chapter $_chapterNumber: $_chapterTitle';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Story link copied — share it anywhere')),
    );
  }

  Future<void> _loadLikeState() async {
    final bookId = widget.bookId;
    if (bookId == null) return;
    try {
      final res = await widget.apiService.fetchBookLike(bookId);
      if (!mounted) return;
      setState(() {
        _liked = (res['liked'] as bool?) ?? false;
        _likeCount = (res['likes_count'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final bookId = widget.bookId;
    if (bookId == null) {
      setState(() {
        _liked = !_liked;
        _likeCount += _liked ? 1 : -1;
        if (_likeCount < 0) _likeCount = 0;
      });
      return;
    }
    try {
      final res = _liked
          ? await widget.apiService.unlikeBook(bookId)
          : await widget.apiService.likeBook(bookId);
      if (!mounted) return;
      setState(() {
        _liked = (res['liked'] as bool?) ?? !_liked;
        _likeCount = (res['likes_count'] as num?)?.toInt() ?? _likeCount;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to like. One like per account.')),
      );
    }
  }

=======
>>>>>>> 719ee01d93a55320f534cf43f18260e34fe81749
  @override
  Widget build(BuildContext context) {
    final total = _chapters.isEmpty ? 1 : _chapters.length;
    final pageLabel = '${_chapterIndex + 1}/$total';
    final hasNext =
        _chapters.isNotEmpty && _chapterIndex < _chapters.length - 1;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _fg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          pageLabel,
          style: TextStyle(color: _muted, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _openChapterDrawer,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _share,
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () => setState(() => _showThemePanel = !_showThemePanel),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showThemePanel)
            Container(
              color: _bg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (final t in _ReaderTheme.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t.name),
                        selected: _theme == t,
                        onSelected: (_) => setState(() => _theme = t),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => setState(() {
                      if (_fontSize > 12) _fontSize -= 1;
                    }),
                  ),
                  Text('${_fontSize.toInt()}'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() {
                      if (_fontSize < 28) _fontSize += 1;
                    }),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter $_chapterNumber',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _chapterTitle,
                    style: TextStyle(
                      color: _fg,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _chapterContent.isEmpty
                        ? 'This chapter has no content yet.'
                        : _chapterContent,
                    style: TextStyle(
                      color: _fg,
                      fontSize: _fontSize,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionChip(
                        icon: _liked ? Icons.favorite : Icons.favorite_border,
                        label: _likeCount > 0 ? '$_likeCount Likes' : 'Like',
                        color: _liked ? Colors.red : null,
                        onTap: _toggleLike,
                      ),
                      _actionChip(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: _share,
                      ),
                    ],
                  ),
                  if (hasNext) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            _chapterIndex++;
                            _applyChapter(_chapters[_chapterIndex]);
                          });
                        },
                        child: const Text('Next chapter'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: color ?? _muted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color ?? _muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
