.PHONY: help dev-android build-android

SUPABASE_DEFINE_FILE := config/supabase.local.json
ANDROID_DEVICE := emulator-5554

help:
	@echo "Available commands:"
	@echo "  make dev-android    Run Android emulator with Supabase feedback config"
	@echo "  make build-android  Build Google Play app bundle with Supabase feedback config"

dev-android:
	flutter run -d $(ANDROID_DEVICE) --dart-define-from-file=$(SUPABASE_DEFINE_FILE)

build-android:
	flutter build appbundle --release --dart-define-from-file=$(SUPABASE_DEFINE_FILE)
