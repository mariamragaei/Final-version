#!/bin/bash
echo "Cleaning Flutter project..."
flutter clean

echo "Fetching Flutter dependencies..."
flutter pub get

echo "Navigating to ios directory..."
cd ios || exit

echo "Removing old Pods and Podfile.lock..."
rm -rf Pods
rm -f Podfile.lock

echo "Installing CocoaPods..."
pod install --repo-update

echo "Done! Please clean your build folder in Xcode (Cmd+Shift+K) and try building again."
