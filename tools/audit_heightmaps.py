#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEVEL = ROOT / 'resources' / 'data' / 'levels' / 'LEVEL_0' / 'LEVEL_0.json'
GEN = ROOT / 'source' / 'scripts' / 'world' / 'generated_heightmaps.d'

FLIPPED_ALL_FLAGS_MASK = 0x80000000 | 0x40000000 | 0x20000000

def mask_gid(gid):
    if gid in (-1, 0):
        return gid
    return gid & ~FLIPPED_ALL_FLAGS_MASK


def parse_level():
    j = json.loads(LEVEL.read_text())
    tilesets = []
    for ts in j.get('tilesets', []):
        firstgid = ts.get('firstgid')
        source = ts.get('source','')
        # gather multiple name candidates (source stem, image, name) and normalize them
        def normalize(raw):
            if not raw:
                return ''
            name = Path(raw).name
            # strip extension
            name = Path(name).stem
            # known extra suffixes
            for s in ["_flipped-table-16-16", "_flipped", "-flipped"]:
                if name.endswith(s):
                    name = name[:-len(s)]
            return name.lower()

        name_candidates = []
        if source:
            name_candidates.append(normalize(source))
        if 'image' in ts and ts.get('image'):
            name_candidates.append(normalize(ts.get('image')))
        if 'name' in ts and ts.get('name'):
            name_candidates.append(normalize(ts.get('name')))
        # dedupe and keep first non-empty
        uniq = []
        for n in name_candidates:
            if n and n not in uniq:
                uniq.append(n)
        tilesets.append({'firstgid': firstgid, 'source': source, 'name_candidates': uniq})
    # sort tilesets by firstgid
    tilesets.sort(key=lambda x: x['firstgid'])

    # collect all raw gids from tile layers
    raw_gids = set()
    for layer in j.get('layers', []):
        if layer.get('type') == 'tilelayer':
            data = layer.get('data', [])
            raw_gids.update(data)
    return tilesets, raw_gids


def parse_generated():
    s = GEN.read_text()
    tileset_blocks = {}
    # Split the file on Tileset comment markers to robustly extract each block
    parts = re.split(r"//\s*Tileset:\s*", s)
    # first part is the header before the first tileset
    for part in parts[1:]:
        # name is the rest of the line until newline
        lines = part.splitlines()
        if not lines:
            continue
        name = lines[0].strip()
        # find the first '[' in the remainder of this part
        rest = '\n'.join(lines[1:])
        start_idx = rest.find('[')
        if start_idx == -1:
            continue
        # find matching closing bracket within this part
        depth = 0
        i = start_idx
        end_idx = -1
        while i < len(rest):
            c = rest[i]
            if c == '[':
                depth += 1
            elif c == ']':
                depth -= 1
                if depth == 0:
                    end_idx = i
                    break
            i += 1
        if end_idx == -1:
            continue
        block = rest[start_idx:end_idx+1]
        # count per-tile arrays inside this block: top-level arrays at depth==2
        count = 0
        depth = 0
        i = 0
        while i < len(block):
            c = block[i]
            if c == '[':
                depth += 1
                if depth == 2:
                    count += 1
            elif c == ']':
                depth -= 1
            i += 1
        tileset_blocks[name] = {'count': count, 'start': start_idx, 'end': end_idx}
    return tileset_blocks


def find_tileset_for_gid(tilesets, gid):
    # tilesets sorted by firstgid
    for i, ts in enumerate(tilesets):
        first = ts['firstgid']
        if i+1 < len(tilesets):
            last = tilesets[i+1]['firstgid'] - 1
        else:
            last = 10**9
        if first <= gid <= last:
            return ts, first, last
    return None, None, None


def main():
    tilesets, raw_gids = parse_level()
    print(f"Found {len(tilesets)} tilesets from level:")
    for ts in tilesets:
        print(f"  firstgid={ts['firstgid']} source={ts.get('source','')} name_candidates={ts.get('name_candidates',[])}")

    print(f"\nCollected {len(raw_gids)} unique raw gids (including zeros/empties)")
    masked = sorted({mask_gid(g) for g in raw_gids})
    print(f"After masking flip flags: {len(masked)} unique gids (including -1/0 if present)")

    gen = parse_generated()
    print(f"\nParsed generated heightmaps: found {len(gen)} tileset blocks:\n")
    for name, info in gen.items():
        print(f"  {name} -> {info['count']} tiles")

    # Now build coverage table
    gids = [g for g in masked if g not in (-1,0)]
    uncovered = []
    covered = []
    mapping = []
    # Normalize generated block names for lookup
    gen_norm = {}
    for name, info in gen.items():
        # normalize similar to runtime: strip path/ext/suffixes and lowercase
        gen_basename = Path(name).stem
        for s in ["_flipped-table-16-16", "_flipped", "-flipped"]:
            if gen_basename.endswith(s):
                gen_basename = gen_basename[:-len(s)]
        gen_norm[gen_basename.lower()] = info

    for g in gids:
        ts, first, last = find_tileset_for_gid(tilesets, g)
        if not ts:
            mapping.append((g, None, None, None, 'NO_TILESET'))
            uncovered.append(g)
            continue
        local = g - ts['firstgid']

        # Try each candidate name for this tileset against normalized generated names
        found = False
        for cand in ts.get('name_candidates', []):
            if cand in gen_norm:
                gen_info = gen_norm[cand]
                if local < gen_info['count']:
                    mapping.append((g, cand, local, gen_info['count'], 'COVERED'))
                    covered.append(g)
                else:
                    mapping.append((g, cand, local, gen_info['count'], 'LOCAL_INDEX_OUT_OF_RANGE'))
                    uncovered.append(g)
                found = True
                break
        if not found:
            mapping.append((g, ts.get('name_candidates', []), local, None, 'NO_GENERATED_BLOCK'))
            uncovered.append(g)

    print(f"\nCoverage summary: total gids in use (non-empty) = {len(gids)}")
    print(f"  covered by generated tables: {len(covered)}")
    print(f"  uncovered/missing: {len(uncovered)}\n")

    print("Detailed mapping (gid -> tileset, local_index, gen_count, status):")
    for entry in mapping:
        print(entry)

    # Also list a small sample of uncovered if many
    if uncovered:
        print('\nSample uncovered gids (first 30):', uncovered[:30])

if __name__ == '__main__':
    main()
