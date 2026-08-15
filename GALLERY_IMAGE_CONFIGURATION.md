# Gallery Image Configuration Guide

## Current Status ✅

Your gallery is currently configured with **3 existing images**:

### Available Images in `assets/images/`:
1. ✅ **fest_poster.png** - Main fest poster/banner
2. ✅ **hacathon.png** - Hackathon event image  
3. ✅ **song.png** - Cultural/music event image

---

## Gallery Organization

### Technical Events Gallery (Hackathon, Coding Competition, Flutter Workshop)
**Current images used:**
- `assets/images/fest_poster.png`
- `assets/images/hacathon.png`
- `assets/images/song.png`

**To add more images:**
1. Place images in `assets/images/` folder
2. Update the `getGalleryImages()` method in `TechnicalEvent` class (line ~120)
3. Example format: `'assets/images/tech_event_4.jpg'`

### Cultural Events Gallery (Kannada Orchestra, Performances)
**Current images used:**
- `assets/images/fest_poster.png`
- `assets/images/song.png`
- `assets/images/hacathon.png`

**To add more images:**
1. Place images in `assets/images/` folder
2. Update the `getGalleryImages()` method in `CulturalEvent` class (line ~160)
3. Example format: `'assets/images/cultural_4.jpg'`

---

## Image Specifications

### Format & Dimensions
- **Aspect Ratio:** 16:9 (Landscape)
- **Recommended Sizes:**
  - High: 1920 × 1080 px
  - Medium: 1280 × 720 px
  - Standard: 1024 × 576 px

### Supported Formats
- `.jpg` / `.jpeg` (Recommended)
- `.png`
- `.webp`

---

## How to Add More Images

### Step 1: Prepare Your Images
- Create or export images in 16:9 landscape format
- Use sizes: 1920×1080px, 1280×720px, or 1024×576px
- Save as `.jpg` for better performance

### Step 2: Add to Assets
1. Save image file to: `e:\fest_flutter_app\my_app\assets\images\`
2. Example filename: `tech_event_4.jpg`

### Step 3: Update Gallery Code
Edit `lib/main.dart` and find the event's `getGalleryImages()` method:

**For Technical Events (line ~120):**
```dart
@override
List<String> getGalleryImages() {
  return [
    'assets/images/fest_poster.png',
    'assets/images/hacathon.png',
    'assets/images/song.png',
    'assets/images/tech_event_4.jpg',    // Add your new image here
    'assets/images/tech_event_5.jpg',    // Add more as needed
  ];
}
```

**For Cultural Events (line ~160):**
```dart
@override
List<String> getGalleryImages() {
  return [
    'assets/images/fest_poster.png',
    'assets/images/song.png',
    'assets/images/hacathon.png',
    'assets/images/cultural_4.jpg',      // Add your new image here
    'assets/images/cultural_5.jpg',      // Add more as needed
  ];
}
```

### Step 4: Rebuild App
```bash
flutter pub get
flutter run -d chrome
```

---

## Gallery Features

✨ **Current Features:**
- ✅ **Auto-Play:** Images advance every 4 seconds
- ✅ **Manual Navigation:** Previous/Next buttons
- ✅ **Indicator Dots:** Shows current image position
- ✅ **Smooth Transitions:** 500ms easing animation
- ✅ **Smart Timer:** Resets when user navigates manually
- ✅ **Error Handling:** Shows placeholder if image not found

---

## File Structure

```
assets/
├── fest_poster.png       ✅ (Used)
├── hacathon.png          ✅ (Used)
├── song.png              ✅ (Used)
└── images/
    ├── fest_poster.png   (Symlink or copy from assets/)
    ├── hacathon.png      (Symlink or copy from assets/)
    └── song.png          (Symlink or copy from assets/)
```

---

## Troubleshooting

### Image Not Showing?
1. **Check file path** - Must be exactly: `assets/images/filename.ext`
2. **Check pubspec.yaml** - Ensure `assets/images/` is listed
3. **Rebuild app** - Run `flutter pub get` then rebuild
4. **Check file exists** - Verify file is actually in `assets/images/` folder

### Image Quality Issues?
1. Use 16:9 landscape ratio
2. Use recommended sizes (1920×1080, 1280×720, or 1024×576)
3. Compress images before adding (keep file size < 500KB each)

### App Crashes?
1. Check `flutter analyze` for errors
2. Verify all image paths are spelled correctly
3. Ensure pubspec.yaml asset paths are correct
4. Clear build: `flutter clean` then rebuild

---

## Quick Reference: Image Paths

Current gallery will display these images in order:

**Hackathon/Technical Events:**
1. assets/images/fest_poster.png
2. assets/images/hacathon.png
3. assets/images/song.png

**Cultural Events:**
1. assets/images/fest_poster.png
2. assets/images/song.png
3. assets/images/hacathon.png

To change, edit the `getGalleryImages()` methods in `lib/main.dart`.
