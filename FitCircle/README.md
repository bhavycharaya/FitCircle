# FitCircle — Ecosystem Documentation & Setup Guide

**Move Together. Stay Fit Together.**

FitCircle is a full family fitness ecosystem designed for Android, featuring step tracking, family circle leaderboards, real-time sync, exercise logging, and an intelligent Overtake Engine.

---

## 📁 Repository Structure

```text
FitCircle/
├── app/                        ← Flutter Android application
│   ├── lib/
│   │   ├── config/             ← Theme and Supabase initialization
│   │   ├── models/             ← Data models (Profile, Family, Steps, Exercise, etc.)
│   │   ├── services/           ← Backend & sensor services (Step, Leaderboard, etc.)
│   │   ├── providers/          ← Reactive Providers (AuthProvider, FitCircleProvider)
│   │   ├── screens/            ← UI Screens (Home, Auth, Family, etc.)
│   │   └── widgets/            ← UI Components (StepRing, OvertakeBanner, etc.)
│   ├── pubspec.yaml
│   └── .env.example
│
├── website/                    ← Public landing page & APK host
│   ├── index.html              ← Responsive FitCircle landing page
│   ├── privacy.html            ← Privacy policy page
│   ├── js/config.js            ← SINGLE SOURCE OF TRUTH for APK URLs & GitHub link
│   ├── js/main.js              ← Interactive scripts & scroll reveal
│   ├── css/styles.css          ← Dark navy + purple/orange gradient styling
│   └── assets/images/          ← Logo and app mockup assets
│
├── supabase/                   ← Backend PostgreSQL SQL scripts
│   ├── schema.sql              ← Full schema, triggers & leaderboard views
│   ├── policies.sql            ← Row Level Security (RLS) policies
│   └── migrations/             ← Migration entries
│
├── README.md                   ← Master documentation
└── .env.example
```

---

## ⚡ Supabase Setup

1. Create a project at [Supabase.com](https://supabase.com).
2. Navigate to **SQL Editor**.
3. Execute `supabase/schema.sql` to build all tables, leaderboard views (`family_leaderboard`), and streak update triggers.
4. Execute `supabase/policies.sql` to apply Row Level Security policies.
5. Copy your **Project URL** and **Anon API Key** into `app/.env`:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

---

## 🚀 Running the Flutter App

1. Ensure Flutter 3.x+ SDK is installed.
2. Change directory into `app/`:
   ```bash
   cd app
   flutter pub get
   ```
3. Run on an Android emulator or connected device:
   ```bash
   flutter run
   ```

### Building Release APK
To build the distribution APK for the website:
```bash
flutter build apk --release
```
The APK will be generated at `app/build/app/outputs/flutter-apk/app-release.apk`.

---

## 🌐 Deploying the Website & Updating APK Releases

1. Create a new release on GitHub (e.g. tag `v1.0.0`) and attach `app-release.apk`.
2. Copy the direct asset download link.
3. Open `website/js/config.js` and update `APK_DOWNLOAD_URL`:
   ```javascript
   const FITCIRCLE_CONFIG = {
     APP_VERSION: "1.0.0",
     APK_DOWNLOAD_URL: "https://github.com/bhavycharaya/FitCircle/releases/download/v1.0.0/fitcircle-v1.0.0.apk",
     GITHUB_REPOSITORY_URL: "https://github.com/bhavycharaya/FitCircle"
   };
   ```
4. Deploy the `website/` folder to GitHub Pages, Netlify, or Vercel.

---

## 🔒 Security Architecture
- **No Client Ranks**: Ranks are computed exclusively server-side via PostgreSQL window functions (`RANK() OVER (...)`).
- **Family Isolation**: RLS ensures users can only read step and exercise data from members of their own family circle (`family_id`).
- **Private Workout Notes**: Individual workout notes are strictly hidden from family feeds.
