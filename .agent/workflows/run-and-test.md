---
description: How to run, build, and test the Flutter ecom demo app
---

# Run & Test Workflow

## Prerequisites
- Flutter SDK installed and on PATH
- An emulator running or a physical device connected

## Steps

// turbo
1. Check Flutter environment is ready:
```
flutter doctor
```

// turbo
2. Get dependencies:
```
flutter pub get
```

// turbo
3. Run the app in debug mode:
```
flutter run
```

4. Run the app on Chrome (web):
```
flutter run -d chrome
```

5. Build a release APK:
```
flutter build apk --release
```

// turbo
6. Run all tests:
```
flutter test
```

// turbo
7. Analyze code for issues:
```
flutter analyze
```

## Manual Testing Checklist

After running the app, verify the following:

### Scroll Architecture
- [ ] Scroll down — header collapses smoothly
- [ ] Tab bar pins at top when header is fully collapsed
- [ ] Continue scrolling — product list scrolls smoothly below pinned tab bar
- [ ] No jitter or flicker at any point

### Tab Switching
- [ ] Tap on tab — switches content, scroll position does NOT jump
- [ ] Swipe horizontally — switches tab without affecting vertical scroll
- [ ] Scroll down in Tab 1, switch to Tab 2, switch back — Tab 1 scroll position preserved

### Pull-to-Refresh
- [ ] Pull down from top of any tab — refresh indicator appears
- [ ] Data reloads correctly after refresh

### Authentication
- [ ] Login screen loads correctly
- [ ] Can log in with test credentials (username: `mor_2314`, password: `83r5^_`)
- [ ] After login, user profile is displayed
- [ ] Token is stored and used for authenticated state

### Product Display
- [ ] Products load from Fake Store API
- [ ] Product cards show image, title, price, rating
- [ ] Products are filterable by category via tabs
- [ ] Images load without errors (handle network image failures gracefully)
