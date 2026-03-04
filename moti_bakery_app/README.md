# moti_bakery_app

## Flutter + Supabase setup

Install dependencies:

```bash
flutter pub get
```

Run with Supabase project values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_publishable_or_anon_key
```

If these `--dart-define` values are not provided, the app falls back to demo/mock services.

Reuse Supabase values from the React app `.env` automatically:

```bash
./scripts/run_with_react_supabase_env.sh
```
