# Deployment Guide: Flutter Web App on Render (Free Tier)

This guide deploys the app as a **static site** on Render's free tier
(unlimited sites, always-on, no spin-down, no credit card required).

## How the deployment works

- `render.yaml` defines a **static site** (Blueprints) with:
  - Build command: `bash ./build.sh`
  - Publish directory: `build/web`
- Render's build image does **not** include Flutter, so `build.sh` downloads
  a pinned stable Linux SDK (`3.44.6`), runs `flutter pub get`, and builds
  the web release. Secrets are injected at build time via `--dart-define`
  from the `SUPABASE_URL` / `SUPABASE_KEY` env vars.
- `lib/main.dart` reads `SUPABASE_URL` / `SUPABASE_KEY` first from
  `--dart-define`, and falls back to the bundled `assets/.env` file for
  local development.

> Note: `assets/.env` is git-ignored, so on Render the values must come from
> the service's environment variables (see Step 4). In a web app, the keys
> embedded in the compiled JS are visible to anyone anyway — keep the
> Supabase anon key read-only and lock down the database with Row Level
> Security (RLS).

## Prerequisites

- GitHub repository with this code
- Render account (sign in with GitHub at https://render.com — no credit card)

## Step-by-Step Instructions

### Step 1: Push the project to GitHub

```bash
git init
git add .
git commit -m "Prepare Flutter web app for Render deployment"
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

The repository must be public (or you must add Render as a collaborator).

### Step 2: Create the Render static site

1. Go to https://dashboard.render.com/select-repo?type=static
2. Connect your GitHub account if prompted, and pick your repository.
3. Render auto-detects the Blueprint (`render.yaml`). Create it.

If you are NOT using `render.yaml` and creating the service manually instead,
set these values in the dashboard:

| Setting                | Value                        |
|------------------------|------------------------------|
| Build command          | `bash ./build.sh`            |
| Publish directory      | `build/web`                  |
| Branch                 | `main`                       |
| Auto-deploy            | Yes                          |

### Step 3: Add the Supabase environment variables

1. Open the service → **Environment** tab.
2. Add:
   - `SUPABASE_URL` = your project URL (e.g. `https://xxxx.supabase.co`)
   - `SUPABASE_KEY` = your Supabase **anon** (publishable) key
3. Click **Save Changes**.

### Step 4: Deploy

- The first deploy downloads the Flutter SDK and compiles the app, so it
  takes **10–20 minutes**. Later deploys are faster.
- On success you get `https://<service-name>.onrender.com`.
- With auto-deploy enabled, every push to `main` rebuilds automatically.

### Step 5: (Optional) Custom domain

Settings → **Custom Domain** → add your domain and follow the DNS
instructions (CNAME / TXT). TLS is provisioned automatically.

## Verifying locally before deploying

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_KEY=<anon-key>
```

Serve the output and test:

```bash
python -m http.server 8000 --directory build/web
# open http://localhost:8000
```

## Free tier limits (static sites)

- Unlimited sites, always-on, global CDN, automatic HTTPS.
- Usage counts against the workspace's monthly included **bandwidth** and
  **pipeline (build) minutes**. Keep builds lean; do not push empty commits.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Build fails: `flutter: command not found` | Outdated script — update `FLUTTER_VERSION` in `build.sh` and redeploy. |
| App renders but registration says "Supabase credentials are not configured" | Env vars missing/unsaved in the **Environment** tab; redeploy after saving. |
| Blank page | Open browser DevTools → Console. Common cause: build-time secrets not set, or service worker cache — hard refresh (Ctrl+Shift+R). |
| Slow first load | Normal for Flutter web (CanvasKit). Assets are cached by the service worker afterwards. |
| Registrations rejected by Supabase | Enable RLS and grant `insert` to `anon` on the `registrations` table. |

## Updating the app

```bash
git add .
git commit -m "Update app"
git push origin main
```

Render rebuilds and deploys automatically.
