# UX fixes branch

## Already on this branch
- `lib/ui/screens/reading_list_detail_screen.dart`

## Copy these from `artifacts/ux-fixes-update.zip` (or the Grok project artifacts folder):

```
lib/ui/screens/profile_screen.dart
lib/ui/screens/story_detail_screen.dart
lib/ui/screens/discover_widgets.dart
lib/ui/screens/chapter_reader_screen.dart
lib/ui/screens/reading_list_detail_screen.dart
```

## PR
https://github.com/lakmalsachithsilva0-web/novel_mobile_app/pull/1

## Fixes summary
1. Profile avatar fully visible
2. Wall post safe (no controller crash)
3. Reading list cards open list detail then stories
4. Reviews show reviewer avatar + name (tap profile)
5. Native Share (WhatsApp, Facebook, SMS, ...)
6. Discover slider: no blank start space (`padEnds: false`)
7. Chapter reader: share + Next Chapter to top
