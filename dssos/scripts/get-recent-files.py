#!/usr/bin/env python3
import os, json, time, sys

def main():
    home = os.path.expanduser('~')
    xbel = os.path.join(home, '.local/share/recently-used.xbel')
    results = []

    if os.path.exists(xbel):
        try:
            import xml.etree.ElementTree as ET
            tree = ET.parse(xbel)
            for b in reversed(tree.getroot().findall('.//bookmark')):
                href = b.get('href', '')
                if href.startswith('file://'):
                    p = href[7:]
                    if os.path.exists(p) and not os.path.isdir(p):
                        results.append((os.path.getmtime(p), os.path.basename(p), p))
                if len(results) >= 6:
                    break
        except Exception:
            pass

    if len(results) < 3:
        for folder in [os.path.join(home, d) for d in ['Downloads', 'Documents', 'Desktop', '']]:
            if os.path.isdir(folder):
                try:
                    for f in os.listdir(folder):
                        if not f.startswith('.'):
                            p = os.path.join(folder, f)
                            if os.path.isfile(p):
                                try:
                                    results.append((os.path.getmtime(p), f, p))
                                except Exception:
                                    pass
                except Exception:
                    pass

    results.sort(reverse=True)
    seen = set()
    out = []
    for mtime, name, path in results:
        if name not in seen:
            seen.add(name)
            ext = os.path.splitext(name)[1].lower()
            icon = 'fd'
            col = '#f5b942'
            if ext in ['.qml', '.py', '.c', '.cpp', '.js', '.ts', '.sh', '.desktop', '.json', '.html', '.css']:
                icon = 'cd'
                col = '#4da3ff'
            elif ext in ['.png', '.jpg', '.jpeg', '.svg', '.gif', '.webp']:
                icon = 'im'
                col = '#b57bee'
            elif ext in ['.pdf', '.txt', '.md', '.doc', '.docx']:
                icon = 'pd'
                col = '#ff5a5a'
            diff = time.time() - mtime
            if diff < 86400:
                dt = 'Today'
            elif diff < 172800:
                dt = 'Yesterday'
            else:
                dt = time.strftime('%d %b', time.localtime(mtime))
            out.append({'name': name, 'path': path, 'icon': icon, 'color': col, 'date': dt})
        if len(out) == 3:
            break

    print(json.dumps(out))

if __name__ == '__main__':
    main()
