#!/usr/bin/env python3
"""Fetch Quran data from Quran.com API.

Source: King Fahd Complex (KFGQPC) via Quran.com
Translation: Saheeh International (ID: 20)
"""

import json
import re
import time
import sys
import urllib.request


def fetch_json(url):
    req = urllib.request.Request(url, headers={
        'Accept': 'application/json',
        'User-Agent': 'HolyQuranApp/1.0 (educational project)',
    })
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read().decode('utf-8'))


def strip_html(text):
    """Remove HTML tags like <sup foot_note=...>1</sup>"""
    return re.sub(r'<[^>]+>', '', text)


def main():
    print("Fetching Quran data from Quran.com API...")
    print("Source: KFGQPC via Quran.com")
    print("Translation: Saheeh International (ID: 20)")
    print()

    all_verses = []

    for surah_num in range(1, 115):
        print(f"  Surah {surah_num:3d}/114...", end=" ", flush=True)

        try:
            arabic_data = fetch_json(
                f"https://api.quran.com/api/v4/quran/verses/uthmani?chapter_number={surah_num}"
            )
            trans_data = fetch_json(
                f"https://api.quran.com/api/v4/quran/translations/20?chapter_number={surah_num}"
            )

            arabic_verses = arabic_data.get('verses', [])
            translations = trans_data.get('translations', [])

            for i, verse in enumerate(arabic_verses):
                verse_key = verse['verse_key']
                surah, verse_num = verse_key.split(':')

                translation = ''
                if i < len(translations):
                    translation = strip_html(translations[i].get('text', ''))

                all_verses.append({
                    'verseId': verse_key,
                    'surahNumber': int(surah),
                    'verseNumber': int(verse_num),
                    'arabicText': verse['text_uthmani'],
                    'translation': translation,
                })

            print(f"ok ({len(arabic_verses)} verses)")
            time.sleep(0.3)

        except Exception as e:
            print(f"FAILED: {e}")
            sys.exit(1)

    with open("assets/quran/verses.json", 'w', encoding='utf-8') as f:
        json.dump(all_verses, f, ensure_ascii=False, indent=2)

    print(f"\nDone: {len(all_verses)} verses saved to assets/quran/verses.json")
    print(f"Expected: 6236 | Got: {len(all_verses)}")


if __name__ == '__main__':
    main()
