#!/bin/bash
# Run this once from inside the flutter-test folder to bootstrap platform files.
# It generates android/, ios/, etc. without touching our existing lib/ files.

set -e

echo "🔧 Bootstrapping Flutter platform files..."

# Back up our custom lib files
mkdir -p /tmp/flutter_test_backup
cp -r lib /tmp/flutter_test_backup/
cp pubspec.yaml /tmp/flutter_test_backup/

# Generate platform boilerplate (this will overwrite lib/main.dart)
flutter create . --project-name flutter_test_app --platforms android,ios,macos

# Restore our custom files over the generated ones
cp -r /tmp/flutter_test_backup/lib .
cp /tmp/flutter_test_backup/pubspec.yaml .
rm -rf /tmp/flutter_test_backup

echo "📦 Installing dependencies..."
flutter pub get

echo ""
echo "✅ Setup complete!"
echo ""
echo "Run the app with:"
echo "   flutter run"
echo ""
echo "Test credentials:"
echo "   Email:    test@example.com"
echo "   Password: password123"
