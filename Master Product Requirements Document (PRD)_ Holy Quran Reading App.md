# Master Product Requirements Document (PRD): Holy Quran Reading App

## 1. Executive Summary
The **Holy Quran Reading App** is a high-performance, privacy-first mobile application (iOS & Android) built with **Flutter**. It is designed to provide a serene, "Digital Sanctuary" experience for **casual readers**, prioritizing absolute data accuracy, offline reliability, and intuitive accessibility.

## 2. Core Design Philosophy: The "Digital Sanctuary"
The app avoids the "busy" feel of modern social media. It uses a soft, cream-colored background (mimicking high-quality paper) with subtle, modern Islamic geometric patterns. The goal is to provide immediate spiritual peace upon opening the app.

## 3. Technical Architecture & Data Integrity

### 3.1 Tech Stack
*   **Framework:** Flutter (for pixel-perfect rendering and cross-platform consistency).
*   **State Management:** Riverpod (declarative, AI-friendly, and robust).
*   **Local Database:** Isar (high-performance NoSQL for coordinate mapping and history).
*   **Feedback Backend:** Supabase (anonymous feedback storage and admin dashboard).
*   **Cloud:** **None for user data.** 100% local storage for maximum privacy.

### 3.2 Data Accuracy & Verification
*   **Source:** Verified digital text from the **King Fahd Complex (KFGQPC)** via the Quran.com API.
*   **Integrity Checks:** Every data file is verified using **SHA-256 checksums**.
*   **Atomic Updates:** A "Dual-Partition" system ensures the app only switches to new data if it passes all integrity checks, allowing for safe rollbacks.

### 3.3 Hybrid "Abstract Renderer" Architecture
The app uses a unified interface to support two distinct reading modes:
*   **v1: Classic Mode (Vector Fonts):** Uses the KFGQPC Hafs Digital Font. Extremely lightweight (~20MB total), fast, and supports dynamic text scaling.
*   **v2: Mushaf Mode (HD Images):** Uses high-resolution page images with **Coordinate Mapping (JSON)** to enable word-level interaction (Tafseer/Translation) on the images.
*   **Unified State:** Bookmarks and "Last Read" positions are saved as `VerseIDs`, ensuring a seamless transition between modes.

## 4. User Experience & Features

### 4.1 Spiritual Rhythm Notifications
*   **Prayer-Linked:** Notifications are timed with the **Iqama window** (e.g., 10 minutes after Azan) to capture micro-reading opportunities.
*   **Behavioral Nudges:** Gentle reminders if a user misses their usual reading time, with a "Remind me later" snooze option.

### 4.2 Accessibility: "Focus Mode"
*   **Interaction:** Long-press on any verse to enter a magnified "Verse Detail" view with large-font Tafseer.
*   **Navigation:** Support for **Volume Button Page Turning**, catering to elderly users or those with low dexterity.
*   **Zero-Friction Onboarding:** No accounts or carousels; contextual tooltips guide the user during their first session.

### 4.3 Offline-First Strategy
*   **Time-Focused Onboarding:** Instead of megabytes, the app informs users: *"Preparing your Digital Sanctuary... This will take less than 30 seconds."*
*   **Smart Buffer Pre-fetching:** The app automatically prioritizes downloading the next Juz in the background based on the user's reading progress.

## 5. Privacy & Data Safety
*   **No Cloud Connection:** All reading history and bookmarks stay on the device.
*   **Manual Backup:** A simple "Export/Import" feature allows users to save an encrypted `.quran` file to their local "Files" app for manual backup or device migration.

## 6. Feedback & Dashboard
*   **Heartbeat Feedback:** Non-intrusive prompts (e.g., after a 7-day streak) ask users for feedback.
*   **Anonymous Pipeline:** Feedback is sent anonymously to a **Supabase Dashboard**, allowing the developer to review and prioritize improvements without compromising user privacy.

## 7. Roadmap

### Phase 1: MVP (v1 - Classic Mode)
*   Flutter + Isar + Riverpod foundation.
*   KFGQPC Vector Font rendering.
*   Prayer-time linked notifications.
*   Supabase feedback integration.

### Phase 2: Enhanced Experience (v2 - Mushaf Mode)
*   HD Image rendering with Coordinate Mapping.
*   "Focus Mode" for elderly accessibility.
*   Manual Export/Import backup system.

### Phase 3: Advanced Features
*   Audio recitations (streaming/offline).
*   Advanced "Discover" topic chips.
*   Community error-reporting loop.

---
**Prepared by:** Manus AI  
**Date:** May 17, 2026
