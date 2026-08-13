import 'package:flutter/material.dart';
import '../../data/models/app_bootstrap.dart';
import '../../data/services/api_service.dart';
import 'story_detail_screen.dart';

/// Inkitt profile: cover, avatar, stats cards, About/Stories/Wall/Activity/Reviews (backend-wired).
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
  late TabController _tabController;
  bool _loading = true;
  Map<String, dynamic>? _userProfile;
  bool _isFollowing = false;
  bool _isOwnProfile = true;
  List<Map<String, dynamic>> _stories = const [];
  List<Map<String, dynamic>> _wall = const [];
  List<Map<String, dynamic>> _activity = const [];
  List<Map<String, dynamic>> _reviews = const [];
  List<Map<String, dynamic>> _readingLists = const [];

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

  int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  String _s(dynamic v) => v == null ? '' : '$v'.trim();

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final me = await widget.apiService.fetchMe();
      final meId = _asInt(me['id'] ?? me['user_id']);
      final viewId = widget.viewingUserId;
      _isOwnProfile = viewId == null || (meId != 0 && viewId == meId);
      final int targetId = _isOwnProfile
          ? (meId != 0 ? meId : (widget.profile.id ?? 0))
          : (viewId ?? 0);

      if (_isOwnProfile) {
        _userProfile = me.isNotEmpty
            ? me
            : {
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

      if (targetId > 0) {
        final results = await Future.wait([
          (_isOwnProfile
                  ? widget.apiService.fetchWriterStories()
                  : widget.apiService.fetchUserStories(targetId))
              .catchError((_) => <Map<String, dynamic>>[]),
          widget.apiService
              .fetchUserWall(targetId)
              .catchError((_) => <Map<String, dynamic>>[]),
          widget.apiService
              .fetchUserActivity(targetId)
              .catchError((_) => <Map<String, dynamic>>[]),
          (_isOwnProfile
                  ? widget.apiService.fetchMyReviews()
                  : widget.apiService.fetchUserReviews(targetId))
              .catchError((_) => <Map<String, dynamic>>[]),
          (_isOwnProfile
                  ? widget.apiService.fetchReadingLists()
                  : widget.apiService.fetchUserReadingLists(targetId))
              .catchError((_) => <Map<String, dynamic>>[]),
        ]);
        if (mounted) {
          setState(() {
            _stories = List<Map<String, dynamic>>.from(results[0] as List);
            _wall = List<Map<String, dynamic>>.from(results[1] as List);
            _activity = List<Map<String, dynamic>>.from(results[2] as List);
            _reviews = List<Map<String, dynamic>>.from(results[3] as List);
            _readingLists = List<Map<String, dynamic>>.from(results[4] as List);
            _loading = false;
          });
        }
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
      if (_isFollowing) {
        await widget.apiService.unfollowAuthor(id);
      } else {
        await widget.apiService.followAuthor(id);
      }
      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
        if (_userProfile != null) {
          final cur = _asInt(_userProfile!['followers']);
          _userProfile = {
            ..._userProfile!,
            'followers': _isFollowing ? cur + 1 : (cur > 0 ? cur - 1 : 0),
          };
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
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
                    flexibleSpace: FlexibleSpaceBar(
                      background: _coverUrl.isNotEmpty
                          ? Image.network(
                              _coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: const Color(0xFF1A2030)),
                            )
                          : Container(color: const Color(0xFF1A2030)),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -36),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFFE2E8F0),
                            backgroundImage: _avatarUrl.isNotEmpty
                                ? NetworkImage(_avatarUrl)
                                : null,
                            child: _avatarUrl.isEmpty
                                ? Text(
                                    _displayName.isNotEmpty
                                        ? _displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: muted,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '@$_username',
                            style: const TextStyle(fontSize: 14, color: muted),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              _bio,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, height: 1.35),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_following Following',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$_followers Followers',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _isOwnProfile ? null : _toggleFollow,
                            child: Text(
                              _isOwnProfile
                                  ? 'Edit profile'
                                  : (_isFollowing ? 'Following' : 'Follow'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: brand,
                        unselectedLabelColor: muted,
                        indicatorColor: brand,
                        tabs: const [
                          Tab(text: 'About'),
                          Tab(text: 'Stories'),
                          Tab(text: 'Wall'),
                          Tab(text: 'Activity'),
                          Tab(text: 'Reviews'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _statRow('CHAPTERS READ', '$_chaptersRead',
                          Icons.menu_book_rounded, const Color(0xFF9B59B6)),
                      const SizedBox(height: 10),
                      _statRow('SOCIAL KARMA', '$_karma',
                          Icons.campaign_outlined, brand),
                      const SizedBox(height: 10),
                      _statRow('DAY READING STREAK', '$_streak', Icons.blur_on,
                          const Color(0xFF5B9BD5)),
                      const SizedBox(height: 16),
                      Text(_bio, style: const TextStyle(fontSize: 14, height: 1.4)),
                      const SizedBox(height: 16),
                      Text(
                        'Reading lists: ${_readingLists.length}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Achievements: ${widget.achievements.length} groups',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  _stories.isEmpty
                      ? const Center(child: Text('No stories yet'))
                      : ListView.builder(
                          itemCount: _stories.length,
                          itemBuilder: (context, i) {
                            final s = _stories[i];
                            return ListTile(
                              title: Text(_s(s['title'])),
                              subtitle: Text(_s(s['description']),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              onTap: () {
                                final id = _asInt(s['id']);
                                if (id <= 0) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => StoryDetailScreen(
                                      apiService: widget.apiService,
                                      book: BookDetailModel(
                                        id: id,
                                        title: _s(s['title']),
                                        author: _s(s['author']),
                                        description: _s(s['description']),
                                        statusText: _s(s['status_text']),
                                        rating: (s['rating'] is num)
                                            ? (s['rating'] as num).toDouble()
                                            : 0,
                                        genre: _s(s['genre']),
                                        cta: 'Read now',
                                        coverPath: _s(s['cover_path']),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  _wall.isEmpty
                      ? const Center(child: Text('No wall posts yet'))
                      : ListView.builder(
                          itemCount: _wall.length,
                          itemBuilder: (context, i) {
                            final m = _wall[i];
                            return ListTile(
                              title: Text(_s(
                                  m['sender_name'] ?? m['username'] ?? 'User')),
                              subtitle: Text(
                                  _s(m['message'] ?? m['body'] ?? m['text'])),
                            );
                          },
                        ),
                  _activity.isEmpty
                      ? const Center(child: Text('No recent activity'))
                      : ListView.builder(
                          itemCount: _activity.length,
                          itemBuilder: (context, i) {
                            final n = _activity[i];
                            return ListTile(
                              title: Text(_s(n['title'])),
                              subtitle: Text(_s(n['message'])),
                            );
                          },
                        ),
                  _reviews.isEmpty
                      ? const Center(child: Text('No reviews yet'))
                      : ListView.builder(
                          itemCount: _reviews.length,
                          itemBuilder: (context, i) {
                            final r = _reviews[i];
                            return ListTile(
                              title: Text(
                                  _s(r['book_title'] ?? r['title'] ?? 'Story')),
                              subtitle: Text(
                                  _s(r['body'] ?? r['comment'] ?? r['review'])),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _statRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: muted)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
