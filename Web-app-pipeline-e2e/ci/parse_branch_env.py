#!/usr/bin/env python3
import argparse
import sys

# Minimal YAML loader for our simple mapping file (no external deps)
def load_simple_yaml(path):
    mappings = {}
    prefixes = {}
    section = None
    try:
        with open(path, 'r', encoding='utf-8') as f:
            for raw in f:
                line = raw.split('#',1)[0].rstrip('\n')
                if not line.strip():
                    continue
                if not line.startswith(' '):
                    # top-level key
                    key = line.split(':',1)[0].strip()
                    if key == 'mappings':
                        section = 'mappings'
                    elif key == 'prefixes':
                        section = 'prefixes'
                    else:
                        section = None
                    continue
                # indented line - parse key: value
                if section:
                    # remove leading spaces
                    line = line.lstrip()
                    if ':' in line:
                        k,v = line.split(':',1)
                        k = k.strip()
                        v = v.strip()
                        # remove surrounding quotes if present
                        if v.startswith('"') and v.endswith('"'):
                            v = v[1:-1]
                        if v.startswith("'") and v.endswith("'"):
                            v = v[1:-1]
                        if section == 'mappings':
                            mappings[k.lower()] = v
                        elif section == 'prefixes':
                            prefixes[k.lower()] = v
        return mappings, prefixes
    except FileNotFoundError:
        return {}, {}


def choose_env(env_param, branch, mappings, prefixes):
    raw = (env_param or branch).strip()
    key = raw.lower().replace('/', '-')
    # explicit mapping
    if env_param:
        return env_param
    if key in mappings:
        return mappings[key]
    # prefix match
    for p,v in prefixes.items():
        if key.startswith(p):
            return v
    # defaults
    if key in ('main','master','prod') or key.startswith('release'):
        return 'prod'
    if key in ('develop','dev','development'):
        return 'dev'
    if key in ('qa','staging','stage'):
        return 'qa'
    # sanitize
    import re
    return re.sub(r'[^A-Za-z0-9_-]', '-', raw)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--branch', default='dev')
    ap.add_argument('--env', default='')
    ap.add_argument('--mapping', default='ci/branch-env-map.yml')
    args = ap.parse_args()

    mappings, prefixes = load_simple_yaml(args.mapping)
    result = choose_env(args.env if args.env else None, args.branch, mappings, prefixes)
    print(result)

if __name__ == '__main__':
    main()
