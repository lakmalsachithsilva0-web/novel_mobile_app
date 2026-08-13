import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_bootstrap.dart';
import '../../data/services/api_service.dart';
import 'story_detail_screen.dart';

part 'profile_tabs.dart';

/// Galatea-style profile: cover + overlapping avatar, stats, About/Stories/Wall/Activity/Reviews.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.apiService,
    required this.achievements,
    this.viewingUserId,
  });

  final ProfileModel profile;
  final ApiService apiService;
  final List<AchievementGroupModel> achievements;
  final int? viewingUserId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  late TabController _tabController;

  Map<String, dynamic>? _userProfile;
  bool _loadingProfile = true;
  bool _isFollowing = false;
  bool _isOwnProfile = true;

  List<Map<String, dynamic>> _stories = const [];
  List<Map<String, dynamic>> _wall = const [];
  List<Map<String, dynamic>> _activity = const [];
  List<Map<String, dynamic>> _reviews = const [];
  List<Map<String, dynamic>> _readingLists = const [];
  String _storyQuery = '';
  String _storySort = 'Recently Updated';
  String _storyFilter = 'All stories';

  static const Color brand = Color(0xFF00A88E);
  static const Color muted = Color(0xFF8A8F98);
  static const Color cardBg = Color(0xFFF7F8FA);
  static const Color border = Color(0xFFE8EAED);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loadingProfile = true);
    try {
      final me = await widget.apiService.fetchMe();
      final meId = _asInt(me['id'] ?? me['user_id']);
      final viewId = widget.viewingUserId;
      _isOwnProfile = viewId == null || (meId != 0 && viewId == meId);

      final int targetId = _isOwnProfile
          ? (meId != 0 ? meId : (widget.profile.id ?? 0))
          : (viewId ?? 0);

      if (_isOwnProfile) {
        _userProfile = me.isNotEmpty ? me : {
          'id': widget.profile.id,
          'display_name': widget.profile.displayName,
          'username': widget.profile.username,
          'following': widget.profile.following,
          'followers': widget.profile.followers,
          'chapters_read': widget.profile.chaptersRead,
          'social_karma': widget.profile.socialKarma,
          'day_streak': widget.profile.dayStreak,
          'photo_url': widget.profile.photoUrl,
          'cover_url': widget.profile.coverUrl,
        };
      } else {
        _userProfile = await widget.apiService.fetchProfile(viewId!);
        try {
          _isFollowing = await widget.apiService.fetchAuthorFollowing(viewId);
        } catch (_) {
          _isFollowing = false;
        }
      }

      List stories = const [];
      List wall = const [];
      List activity = const [];
      List reviews = const [];
      List lists = const [];

      if (targetId > 0) {
        final results = await Future.wait([
          (_isOwnProfile
                  ? widget.apiService.fetchWriterStories()
                  : widget.apiService.fetchUserStories(targetId))
              .catchError((_) => <Map<String, dynamic>>[]),
          widget.apiService.fetchUserWall(targetId).catchError((_) => <Map<String, dynamic>>[]),
          widget.apiService.fetchUserActivity(targetId).catchError((_) => <Map<String, dynamic>>[]),
          (_isOwnProfile
                  ? widget.apiService.fetchMyReviews()
                  : widget.apiService.fetchUserReviews(targetId))
              .catchError((_) => <Map<String, dynamic>>[]),
          (_isOwnProfile
                  ? widget.apiService.fetchReadingLists()
                  : widget.apiService.fetchUserReadingLists(targetId))
              .catchError((_) => <Map<String, dynamic>>[]),
        ]);
        stories = List<Map<String, dynamic>>.from(results[0] as List);
        wall = List<Map<String, dynamic>>.from(results[1] as List);
        activity = List<Map<String, dynamic>>.from(results[2] as List);
        reviews = List<Map<String, dynamic>>.from(results[3] as List);
        lists = List<Map<String, dynamic>>.from(results[4] as List);
      }

      if (!mounted) return;
      setState(() {
        _stories = stories.cast<Map<String, dynamic>>();
        _wall = wall.cast<Map<String, dynamic>>();
        _activity = activity.cast<Map<String, dynamic>>();
        _reviews = reviews.cast<Map<String, dynamic>>();
        _readingLists = lists.cast<Map<String, dynamic>>();
        _loadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  String _s(dynamic v) => v == null ? '' : '$v'.trim();
  int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  String get _displayName {
    final n = _s(_userProfile?['display_name']);
    if (n.isNotEmpty) return n;
    if (widget.profile.displayName.trim().isNotEmpty) {
      return widget.profile.displayName;
    }
    return widget.profile.username;
  }

  String get _username {
    final u = _s(_userProfile?['username']);
    if (u.isNotEmpty) return u.replaceAll('@', '');
    return widget.profile.username.replaceAll('@', '');
  }

  String get _bio {
    final b = _s(_userProfile?['bio']);
    if (b.isNotEmpty) return b;
    return 'Just a reader turning pages into worlds.';
  }

  String get _aboutLong {
    final a = _s(_userProfile?['about'] ?? _userProfile?['bio']);
    return a.isNotEmpty ? a : _bio;
  }

  int get _following =>
      _asInt(_userProfile?['following'] ?? widget.profile.following);
  int get _followers =>
      _asInt(_userProfile?['followers'] ?? widget.profile.followers);
  int get _chaptersRead =>
      _asInt(_userProfile?['chapters_read'] ?? widget.profile.chaptersRead);
  int get _karma =>
      _asInt(_userProfile?['social_karma'] ?? widget.profile.socialKarma);
  int get _streak =>
      _asInt(_userProfile?['day_streak'] ?? widget.profile.dayStreak);

  String get _avatarUrl {
    final p = _s(_userProfile?['avatar_url'] ?? _userProfile?['photo_url']);
    if (p.isEmpty) return '';
    return widget.apiService.resolveAssetUrl(p);
  }

  String get _coverUrl {
    final p = _s(_userProfile?['cover_url'] ?? _userProfile?['banner_url']);
    if (p.isEmpty) return '';
    return widget.apiService.resolveAssetUrl(p);
  }

  Future<void> _toggleFollow() async {
    final id = widget.viewingUserId ?? widget.profile.id;
    if (id == null || _isOwnProfile) return;
    try {
      final dynamic res = _isFollowing
          ? await widget.apiService.unfollowAuthor(id)
          : await widget.apiService.followAuthor(id);
      if (!mounted) return;
      int? followers;
      if (res is Map) {
        followers = (res['followers'] as num?)?.toInt();
      }
      setState(() {
        _isFollowing = !_isFollowing;
        if (_userProfile != null) {
          if (followers != null) {
            _userProfile = {..._userProfile!, 'followers': followers};
          } else {
            final cur = _asInt(_userProfile!['followers']);
            _userProfile = {
              ..._userProfile!,
              'followers': _isFollowing ? cur + 1 : (cur > 0 ? cur - 1 : 0),
            };
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  void _showMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Share profile', style: TextStyle(color: Color(0xFF2B6CB0))),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('Block user', style: TextStyle(color: Color(0xFF2B6CB0))),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('Report user', style: TextStyle(color: Color(0xFF2B6CB0))),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('Cancel', textAlign: TextAlign.center),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    if (!_isOwnProfile) return;
    final nameCtrl = TextEditingController(text: _displayName);
    final bioCtrl = TextEditingController(text: _bio);
    String photoUrl = _s(_userProfile?['photo_url'] ?? _userProfile?['avatar_url']);
    String coverUrl = _s(_userProfile?['cover_url']);
    bool uploading = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Edit profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Display name')),
                  TextField(controller: bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () async {
                                  final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
                                  if (picked == null) return;
                                  setModal(() => uploading = true);
                                  try {
                                    final bytes = await picked.readAsBytes();
                                    final res = await widget.apiService.uploadUserImage(bytes, picked.name);
                                    final path = (res['path'] ?? res['photo_url'] ?? '').toString();
                                    if (path.isNotEmpty) setModal(() => photoUrl = path);
                                  } finally {
                                    setModal(() => uploading = false);
                                  }
                                },
                          icon: const Icon(Icons.person),
                          label: Text(uploading ? 'Uploading…' : 'Profile photo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () async {
                                  final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
                                  if (picked == null) return;
                                  setModal(() => uploading = true);
                                  try {
                                    final bytes = await picked.readAsBytes();
                                    final res = await widget.apiService.uploadUserImage(bytes, picked.name);
                                    final path = (res['path'] ?? res['cover_url'] ?? '').toString();
                                    if (path.isNotEmpty) setModal(() => coverUrl = path);
                                  } finally {
                                    setModal(() => uploading = false);
                                  }
                                },
                          icon: const Icon(Icons.image),
                          label: const Text('Cover'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: brand, foregroundColor: Colors.white),
                    onPressed: () async {
                      try {
                        await widget.apiService.updateMe({
                          'display_name': nameCtrl.text.trim(),
                          'bio': bioCtrl.text.trim(),
                          if (photoUrl.isNotEmpty) 'photo_url': photoUrl,
                          if (coverUrl.isNotEmpty) 'cover_url': coverUrl,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadAll();
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredStories {
    var list = List<Map<String, dynamic>>.from(_stories);
    final q = _storyQuery.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        final title = _s(s['title']).toLowerCase();
        final desc = _s(s['description']).toLowerCase();
        return title.contains(q) || desc.contains(q);
      }).toList();
    }
    bool isCompleted(Map<String, dynamic> s) {
      final st = _s(s['status_text']).toLowerCase();
      final flag = s['is_completed'];
      if (flag == true || flag == 1 || '$flag' == '1') return true;
      return st.contains('complete') || st.contains('finished') || st == 'published';
    }
    if (_storyFilter == 'Completed') {
      list = list.where(isCompleted).toList();
    } else if (_storyFilter == 'In progress') {
      list = list.where((s) => !isCompleted(s)).toList();
    }
    if (_storySort == 'Name') {
      list.sort((a, b) => _s(a['title']).toLowerCase().compareTo(_s(b['title']).toLowerCase()));
    } else if (_storySort == 'Last Read') {
      list.sort((a, b) => _s(b['updated_at'] ?? b['created_at']).compareTo(_s(a['updated_at'] ?? a['created_at'])));
    }
    return list;
  }

  void _showStorySortSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Sort by', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              for (final opt in ['Recently Updated', 'Name', 'Last Read'])
                RadioListTile<String>(
                  dense: true,
                  activeColor: brand,
                  title: Text(opt),
                  value: opt,
                  groupValue: _storySort,
                  onChanged: (v) {
                    setState(() => _storySort = v!);
                    Navigator.pop(ctx);
                  },
                ),
              const Text('Filter', style: TextStyle(fontWeight: FontWeight.w600)),
              for (final opt in ['All stories', 'Completed', 'In progress'])
                RadioListTile<String>(
                  dense: true,
                  activeColor: brand,
                  title: Text(opt),
                  value: opt,
                  groupValue: _storyFilter,
                  onChanged: (v) {
                    setState(() => _storyFilter = v!);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: brand))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 168,
                    pinned: true,
                    backgroundColor: const Color(0xFF1A2030),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: _showMoreMenu,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_coverUrl.isNotEmpty)
                            Image.network(
                              _coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _defaultCover(),
                            )
                          else
                            _defaultCover(),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Sli