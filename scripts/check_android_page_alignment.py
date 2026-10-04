"""Check every 64-bit ELF LOAD segment in an APK or AAB (stdlib only)."""
import argparse
import struct
import zipfile


def check_elf(data):
    if data[:4] != b'\x7fELF':
        raise ValueError('not an ELF library')
    if data[4] != 2:
        raise ValueError('expected a 64-bit ELF library')
    endian = {1: '<', 2: '>'}[data[5]]
    offset = struct.unpack_from(endian + 'Q', data, 32)[0]
    size, count = struct.unpack_from(endian + 'HH', data, 54)
    loads = []
    for index in range(count):
        header = struct.unpack_from(endian + 'IIQQQQQQ', data, offset + index * size)
        if header[0] == 1:
            alignment = header[7]
            if alignment < 16384 or alignment & (alignment - 1):
                raise ValueError(f'LOAD alignment {alignment} is below 16384 or invalid')
            if (header[3] - header[2]) % 16384:
                raise ValueError('LOAD virtual address and file offset are incongruent')
            loads.append(alignment)
    if not loads:
        raise ValueError('no LOAD segments')
    return min(loads)


def check_archive(path):
    failures = []
    checked = 0
    with zipfile.ZipFile(path) as archive:
        for entry in archive.infolist():
            if not entry.filename.endswith('.so') or not any(
                f'/lib/{abi}/' in '/' + entry.filename
                for abi in ('arm64-v8a', 'x86_64')
            ):
                continue
            checked += 1
            try:
                alignment = check_elf(archive.read(entry))
                print(f'PASS {entry.filename}: LOAD alignment {alignment}')
            except (ValueError, KeyError, IndexError, struct.error) as error:
                failures.append(f'{entry.filename}: {error}')
    if not checked:
        failures.append('no 64-bit native libraries found')
    if failures:
        raise ValueError('\n'.join(failures))
    print(f'Checked {checked} 64-bit libraries in {path}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', help='release .apk or .aab')
    args = parser.parse_args()
    try:
        check_archive(args.archive)
    except ValueError as error:
        parser.exit(1, f'FAIL: {error}\n')
