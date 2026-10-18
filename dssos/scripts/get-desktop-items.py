#!/usr/bin/env python3
import os
import sys
import json

def get_desktop_items():
    desktop_dir = os.path.expanduser('~/Desktop')
    pos_file = os.path.expanduser('~/.config/dssos/desktop-positions.json')
    positions = {}
    if os.path.exists(pos_file):
        try:
            with open(pos_file) as f:
                positions = json.load(f)
        except Exception:
            pass

    items = []
    occupied = set()

    # Standard system shortcuts
    defaults = [
        {'id': 'sys-files', 'name': 'Files', 'icon': 'system-file-manager', 'exec': 'dssos-app files'},
        {'id': 'sys-term', 'name': 'Terminal', 'icon': 'utilities-terminal', 'exec': 'foot'},
        {'id': 'sys-settings', 'name': 'Settings', 'icon': 'preferences-system', 'exec': 'dssos-app settings'},
        {'id': 'sys-tasks', 'name': 'Tasks', 'icon': 'utilities-system-monitor', 'exec': 'dssos-app tasks'},
    ]

    for d in defaults:
        pos = positions.get(d['id'])
        if pos and isinstance(pos, dict):
            gx, gy = int(pos.get('x', 0)), int(pos.get('y', 0))
        else:
            gx, gy = 0, len(items)
        occupied.add((gx, gy))
        items.append({
            'id': d['id'],
            'name': d['name'],
            'icon': d['icon'],
            'exec': d['exec'],
            'type': 'app',
            'gridX': gx,
            'gridY': gy
        })

    # Read user files/shortcuts in ~/Desktop
    if os.path.exists(desktop_dir):
        for f in sorted(os.listdir(desktop_dir)):
            if f.startswith('.'):
                continue
            full_path = os.path.join(desktop_dir, f)
            fid = 'file-' + f
            name = f
            icon = 'text-x-generic'
            cmd = f'xdg-open "{full_path}"'
            ftype = 'file'

            if f.endswith('.desktop'):
                ftype = 'desktop'
                # parse Name and Icon from .desktop file
                try:
                    with open(full_path, 'r', errors='ignore') as df:
                        for line in df:
                            line = line.strip()
                            if line.startswith('Name=') and name == f:
                                name = line.split('=', 1)[1].strip()
                            elif line.startswith('Icon='):
                                icon = line.split('=', 1)[1].strip()
                except Exception:
                    pass
                cmd = f'gtk-launch "{f}" 2>/dev/null || xdg-open "{full_path}"'
            elif os.path.isdir(full_path):
                ftype = 'folder'
                icon = 'folder'
                cmd = f'dssos-app files "{full_path}" 2>/dev/null || xdg-open "{full_path}"'

            pos = positions.get(fid)
            if pos and isinstance(pos, dict):
                gx, gy = int(pos.get('x', 0)), int(pos.get('y', 0))
            else:
                col, row = 0, 0
                while (col, row) in occupied:
                    row += 1
                    if row >= 8:
                        row = 0
                        col += 1
                gx, gy = col, row
            occupied.add((gx, gy))

            items.append({
                'id': fid,
                'name': name,
                'icon': icon,
                'exec': cmd,
                'type': ftype,
                'gridX': gx,
                'gridY': gy
            })

    return items

def save_position(item_id, gx, gy):
    pos_file = os.path.expanduser('~/.config/dssos/desktop-positions.json')
    os.makedirs(os.path.dirname(pos_file), exist_ok=True)
    positions = {}
    if os.path.exists(pos_file):
        try:
            with open(pos_file) as f:
                positions = json.load(f)
        except Exception:
            pass
    positions[item_id] = {'x': int(gx), 'y': int(gy)}
    try:
        with open(pos_file, 'w') as f:
            json.dump(positions, f, indent=2)
        return {'success': True}
    except Exception as e:
        return {'success': False, 'error': str(e)}

def main():
    if len(sys.argv) > 1 and sys.argv[1] == '--save-pos':
        if len(sys.argv) >= 5:
            res = save_position(sys.argv[2], sys.argv[3], sys.argv[4])
            print(json.dumps(res))
        else:
            print(json.dumps({'error': 'Missing arguments for save-pos'}))
    else:
        print(json.dumps(get_desktop_items()))

if __name__ == '__main__':
    main()
