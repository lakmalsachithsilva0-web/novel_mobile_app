# Fix flutter analyze errors

<<<<<<< HEAD
## 1. DELETE this broken local-only file (not on GitHub)
=======
## 1. DELETE this broken local-only file
>>>>>>> f2550211c5b76b7b09bd47a9dd535f5e0cac6454

```
del lib\ui\screens\discover_search.dart
```

<<<<<<< HEAD
Or:
```
Remove-Item lib\ui\screens\discover_search.dart
```

`SearchScreen` already lives inside `discover_screen.dart`. The orphan file has no Flutter imports and causes 100+ errors.

## 2. Pull fixed files from GitHub
=======
Or PowerShell:
```
Remove-Item lib\ui\screens\discover_search.dart -ErrorAction SilentlyContinue
```

`SearchScreen` already lives inside `discover_screen.dart`. The orphan file has no Flutter imports and causes 100+ analyzer errors.

## 2. Pull fixed files
>>>>>>> f2550211c5b76b7b09bd47a9dd535f5e0cac6454

```
git pull origin main
```

## 3. Re-analyze

```
flutter clean
flutter pub get
flutter analyze
```

<<<<<<< HEAD
## Verbose run (to see runtime errors)
=======
## Verbose run (see runtime errors)
>>>>>>> f2550211c5b76b7b09bd47a9dd535f5e0cac6454

```
flutter run -d A201SH -v --dart-define=API_BASE_URL=http://192.168.1.4:8000 --dart-define=GOOGLE_CLIENT_ID=YOUR_CLIENT_ID
```

<<<<<<< HEAD
Or:
```
flutter run -d A201SH --verbose --dart-define=API_BASE_URL=http://192.168.1.4:8000 --dart-define=GOOGLE_CLIENT_ID=YOUR_CLIENT_ID
```

=======
>>>>>>> f2550211c5b76b7b09bd47a9dd535f5e0cac6454
## Admin panel

```
cd admin-panel
copy .env.example .env
<<<<<<< HEAD
# Edit VITE_API_BASE_URL=http://192.168.1.4:8000  (or your HF URL)
=======
# Set VITE_API_BASE_URL=http://192.168.1.4:8000
>>>>>>> f2550211c5b76b7b09bd47a9dd535f5e0cac6454
npm install
npm run dev
```

Open the URL Vite prints (usually http://localhost:5173).
<<<<<<< HEAD

Login: values from backend `.env` (`ADMIN_USERNAME` / `ADMIN_PASSWORD`). Check `backend/.env` or server env.

## Author name on write

Create Story now auto-fills author from logged-in `display_name` and locks the field.

## Hashtags

Type in the text box; only admin-created tags from the database are suggested. Users cannot invent tags.
=======
Login: `ADMIN_USERNAME` / `ADMIN_PASSWORD` from backend `.env`.

## Author + hashtags

- Author auto-fills from logged-in display name (locked).
- Hashtags: type to search; only admin-created tags allowed.
>>>>>>> f2550211c5b76b7b09bd47a9dd535f5e0cac6454
