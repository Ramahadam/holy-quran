.PHONY: help dev-android build-android

ANDROID_DEVICE := emulator-5554

help:
	@echo "Available commands:"
	@echo "  make dev-android    Run Android emulator with Cloudflare API config"
	@echo "  make build-android  Build Google Play app bundle with Cloudflare API config"

dev-android:
	flutter run -d $(ANDROID_DEVICE)

build-android:
	flutter build appbundle --release
