import struct
import unittest
import tempfile
import zipfile
from pathlib import Path
from check_android_page_alignment import check_elf, check_archive


def elf(alignment, offset=0, address=0):
    data = bytearray(120)
    data[:6] = b'\x7fELF\x02\x01'
    struct.pack_into('<Q', data, 32, 64)
    struct.pack_into('<HH', data, 54, 56, 1)
    struct.pack_into('<IIQQQQQQ', data, 64, 1, 5, offset, address, 0, 0, 0, alignment)
    return data


class AlignmentTest(unittest.TestCase):
    def test_accepts_16k_and_larger(self):
        for alignment in (16384, 65536):
            self.assertEqual(check_elf(elf(alignment)), alignment)

    def test_rejects_4k(self):
        with self.assertRaises(ValueError):
            check_elf(elf(4096))

    def test_rejects_incongruent_load(self):
        with self.assertRaises(ValueError):
            check_elf(elf(16384, offset=4096))

    def test_rejects_missing_load(self):
        data = elf(16384)
        struct.pack_into('<I', data, 64, 2)
        with self.assertRaises(ValueError):
            check_elf(data)

    def test_checks_every_library_and_rejects_empty_archives(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / 'release.aab'
            with zipfile.ZipFile(archive, 'w') as output:
                output.writestr('base/lib/arm64-v8a/good.so', elf(16384))
                output.writestr('base/lib/x86_64/bad.so', elf(4096))
            with self.assertRaisesRegex(ValueError, 'bad.so'):
                check_archive(archive)
            with zipfile.ZipFile(archive, 'w') as output:
                output.writestr('base/lib/armeabi-v7a/32bit.so', b'ignored')
            with self.assertRaisesRegex(ValueError, 'no 64-bit'):
                check_archive(archive)


if __name__ == '__main__':
    unittest.main()
