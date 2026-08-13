# Fix flutter analyze errors

## 1. DELETE this broken local-only file

```
del lib\ui\screens\discover_search.dart
```

Or PowerShell:
```
Remove-Item lib\ui\screens\discover_search.dart -ErrorAction SilentlyContinue
```

`SearchScreen` already lives inside `discover_screen.dart`. The orphan file has no Flutter imports and causes 100+ analyzer errors.

## 2. Pull fixed files

```
git pull origin main
```

## 3. Re-analyze

```
flutter clean
flutter pub get
flutter analyze
```

## Verbose run (see runtime errors)

```
flutter run -d A201SH -v --dart-define=API_BASE_URL=http://192.168.1.4:8000 --dart-define=GOOGLE_CLIENT_ID=YOUR_CLIENT_ID
```

## Admin panel

```
cd admin-panel
copy .env.example .env
# Set VITE_API_BASE_URL=http://192.168.1.4:8000
npm install
npm run dev
```

Open the URL Vite prints (usually http://localhost:5173).
Login: `ADMIN_USERNAME` / `ADMIN_PASSWORD` from backend `.env`.

## Author + hashtags

- Author auto-fills from logged-in display name (locked).
- Hashtags: type to search; only admin-created tags allowed.
