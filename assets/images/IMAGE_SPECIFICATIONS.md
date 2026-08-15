# Event Gallery Images - Specifications

## Image Format & Dimensions

### Landscape Ratio: 16:9 (Wide Format)

**Recommended Image Sizes:**
- **High Resolution (Best):** 1920 x 1080 px
- **Medium Resolution:** 1280 x 720 px  
- **Standard Resolution:** 1024 x 576 px

All images should maintain the **16:9 landscape aspect ratio**.

---

## File Naming Convention

Gallery images for events should follow this pattern:

### Technical Events:
- `event_1.jpg`
- `event_2.jpg`
- `event_3.jpg`

### Cultural Events:
- `cultural_1.jpg`
- `cultural_2.jpg`
- `cultural_3.jpg`

---

## Supported Formats
- `.jpg` / `.jpeg`
- `.png`
- `.webp`

**Note:** JPEG format recommended for web/mobile optimization.

---

## Gallery Behavior

- **Home Page Gallery:** Displays as a horizontal scrollable PageView (swipe to view multiple images)
- **Event Detail Page:** Same landscape gallery experience with full-screen layout
- **Fallback:** If images are missing, displays "Image not found" placeholder

---

## How to Add Images

1. Save your landscape images (16:9 ratio) to the `assets/images/` folder
2. Update the `getGalleryImages()` method in the event classes if using different image names
3. Run `flutter pub get` to refresh assets
4. Restart the app to see changes

---

## Example Event Gallery Images Needed

- `event_1.jpg` - Main event activity shot
- `event_2.jpg` - Participants or participants
- `event_3.jpg` - Awards or closing ceremony
- `cultural_1.jpg` - Performance on stage
- `cultural_2.jpg` - Audience or backdrop
- `cultural_3.jpg` - Award or celebration moment

---

**Current Image Paths in Code:**
- Technical Events: `assets/images/event_1.jpg`, `assets/images/event_2.jpg`, `assets/images/event_3.jpg`
- Cultural Events: `assets/images/cultural_1.jpg`, `assets/images/cultural_2.jpg`, `assets/images/cultural_3.jpg`
