import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/app_bootstrap.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_service.dart';
import 'profile_screen.dart';
import 'support_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.data,
    required this.apiService,
    required this.session,
    required this.onSignOut,
  });

  final AppBootstrap data;
  final ApiService apiService;
  final AuthSession session;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      children: [
        _AccountCard(session: session, onSignOut: onSignOut),
        const SizedBox(height: 10),
        ...data.menuSections.map((section) {
          return _Section(
            section: section,
            onTap: (item) async {
              final routeName = item.route.toLowerCase();
              final label = item.label.toLowerCase();

              if (item.route == 'profile' ||
                  routeName.contains('profile') ||
                  label.contains('profile')) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileScreen(
                      profile: data.profile,
                      apiService: apiService,
                      achievements: data.achievements,
                    ),
                  ),
                );
                return;
              }

              if (routeName.contains('logout') || label.contains('logout')) {
                await onSignOut();
                return;
              }

              if (routeName.contains('support') ||
                  routeName.contains('help') ||
                  label.contains('support') ||
                  label.contains('request')) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SupportScreen(
                      title: item.label,
                      apiService: apiService,
                    ),
                  ),
                );
                return;
              }

              if (routeName.contains('achievement') ||
                  label.contains('achievement')) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AchievementsScreen(
                      achievements: data.achievements,
                      profile: data.profile,
                    ),
                  ),
                );
                return;
              }

              if (routeName.contains('stat') ||
                  routeName.contains('reading') ||
                  label.contains('reading stat') ||
                  label.contains('stats')) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReadingStatsScreen(
                      profile: data.profile,
                      apiService: apiService,
                    ),
                  ),
                );
                return;
              }

              if (routeName.contains('content') ||
                  routeName.contains('warning') ||
                  label.contains('content warning') ||
                  label.contains('warnings')) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ContentWarningsScreen(),
                  ),
                );
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _PlaceholderScreen(title: item.label),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.session, required this.onSignOut});

  final AuthSession session;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.brand.withValues(alpha: 0.12),
            backgroundImage:
                session.photoUrl != null && session.photoUrl!.isNotEmpty
                    ? NetworkImage(session.photoUrl!)
                    : null,
            child: session.photoUrl == null || session.photoUrl!.isEmpty
                ? Text(
                    session.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  session.email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onSignOut, child: const Text('Log out')),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.section, required this.onTap});

  final MenuSectionModel section;
  final ValueChanged<MenuItemModel> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
            child: Text(
              section.section,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          ...section.items.map((item) {
            return ListTile(
              dense: true,
              leading: Icon(_iconFor(item.icon), size: 20, color: AppTheme.ink),
              title: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.muted,
              ),
              onTap: () => onTap(item),
            );
          }),
        ],
      ),
    );
  }

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'person':
        return Icons.person;
      case 'bar_chart':
        return Icons.bar_chart;
      case 'groups':
        return Icons.groups;
      case 'help':
        return Icons.help_outline;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'notifications':
        return Icons.notifications_none;
      case 'language':
        return Icons.language;
      case 'favorite':
        return Icons.favorite_border;
      case 'auto_awesome':
        return Icons.auto_awesome_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'cookie':
        return Icons.cookie_outlined;
      case 'description':
        return Icons.description_outlined;
      case 'lock':
        return Icons.lock_outline;
      case 'logout':
        return Icons.logout;
      default:
        return Icons.chevron_right;
    }
  }
}

// ─── Achievements (Inkitt / CosmicChaos video) ───────────────────────────────

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({
    super.key,
    required this.achievements,
    required this.profile,
  });

  final List<AchievementGroupModel> achievements;
  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: achievements.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _lockedCard('First Chapter', 'Read your first chapter'),
                _lockedCard('Bookworm', 'Read 10 chapters'),
                _lockedCard('Night Owl', 'Read after midnight'),
                _lockedCard('Streak Starter', '3-day reading streak'),
                _lockedCard('Social Butterfly', 'Follow 5 authors'),
                _lockedCard('Critic', 'Write your first review'),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: achievements.length,
              itemBuilder: (context, gi) {
                final group = achievements[gi];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 8),
                      child: Text(
                        group.groupName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ...group.items.map((a) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8EAED)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.brand.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                a.badgeValue.isNotEmpty ? a.badgeValue : '★',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.brand,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    a.subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                  if (a.progressLabel.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      a.progressLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.brand,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }

  Widget _lockedCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: AppTheme.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reading Stats ──────────────────────────────────────────────────────────

class ReadingStatsScreen extends StatefulWidget {
  const ReadingStatsScreen({
    super.key,
    required this.profile,
    required this.apiService,
  });

  final ProfileModel profile;
  final ApiService apiService;

  @override
  State<ReadingStatsScreen> createState() => _ReadingStatsScreenState();
}

class _ReadingStatsScreenState extends State<ReadingStatsScreen> {
  int chapters = 0;
  int karma = 0;
  int streak = 0;
  int following = 0;
  int followers = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    chapters = widget.profile.chaptersRead;
    karma = widget.profile.socialKarma;
    streak = widget.profile.dayStreak;
    following = widget.profile.following;
    followers = widget.profile.followers;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final me = await widget.apiService.fetchMe();
      if (!mounted) return;
      setState(() {
        chapters = (me['chapters_read'] as num?)?.toInt() ?? chapters;
        karma = (me['social_karma'] as num?)?.toInt() ?? karma;
        streak = (me['day_streak'] as num?)?.toInt() ?? streak;
        following = (me['following'] as num?)?.toInt() ?? following;
        followers = (me['followers'] as num?)?.toInt() ?? followers;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reading Stats'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _bigStat(
                  Icons.menu_book_rounded,
                  const Color(0xFF9B59B6),
                  'Chapters Read',
                  '$chapters',
                ),
                const SizedBox(height: 12),
                _bigStat(
                  Icons.blur_on,
                  const Color(0xFF5B9BD5),
                  'Day Reading Streak',
                  '$streak',
                ),
                const SizedBox(height: 12),
                _bigStat(
                  Icons.campaign_outlined,
                  AppTheme.brand,
                  'Social Karma',
                  '$karma',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _smallStat('Following', '$following'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _smallStat('Followers', '$followers'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Keep reading to grow your streak and unlock achievements.',
                  style: TextStyle(color: AppTheme.muted, height: 1.4),
                ),
              ],
            ),
    );
  }

  Widget _bigStat(IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.muted,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        ],
      ),
    );
  }
}

// ─── Content Warnings ───────────────────────────────────────────────────────

class ContentWarningsScreen extends StatefulWidget {
  const ContentWarningsScreen({super.key});

  @override
  State<ContentWarningsScreen> createState() => _ContentWarningsScreenState();
}

class _ContentWarningsScreenState extends State<ContentWarningsScreen> {
  final Map<String, bool> _prefs = {
    'Violence': false,
    'Sexual content': false,
    'Strong language': false,
    'Substance use': false,
    'Self-harm': false,
    'Spoilers': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Content Warnings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Choose topics you prefer to be warned about before reading a story.',
            style: TextStyle(color: AppTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          ..._prefs.keys.map((key) {
            return SwitchListTile(
              title: Text(key),
              value: _prefs[key]!,
              activeColor: AppTheme.brand,
              onChanged: (v) => setState(() => _prefs[key] = v),
            );
          }),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brand,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Content warning preferences saved')),
              );
              Navigator.pop(context);
            },
            child: const Text('Save preferences'),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title page is ready.')),
    );
  }
}
