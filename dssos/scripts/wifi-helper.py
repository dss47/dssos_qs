#!/usr/bin/env python3
import sys
import subprocess
import json
import re

def split_nmcli(line):
    parts = []
    cur = []
    i = 0
    while i < len(line):
        if line[i] == '\\' and i + 1 < len(line) and line[i+1] == ':':
            cur.append(':')
            i += 2
        elif line[i] == ':':
            parts.append(''.join(cur))
            cur = []
            i += 1
        else:
            cur.append(line[i])
            i += 1
    parts.append(''.join(cur))
    return parts

def scan_wifi():
    try:
        # Rescan auto
        out = subprocess.check_output(
            ['nmcli', '-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY,BSSID', 'dev', 'wifi', 'list'],
            stderr=subprocess.DEVNULL,
            text=True
        )
    except Exception as e:
        return {'networks': [], 'error': str(e)}

    nets = {}
    for line in out.strip().split('\n'):
        if not line:
            continue
        parts = split_nmcli(line)
        if len(parts) >= 3:
            in_use = (parts[0].strip() == '*')
            ssid = parts[1].strip()
            if not ssid:
                continue
            try:
                sig = int(parts[2].strip())
            except:
                sig = 0
            sec = parts[3].strip() if len(parts) > 3 else ''
            bssid = parts[4].strip() if len(parts) > 4 else ''

            if ssid not in nets or in_use or sig > nets[ssid]['signal']:
                nets[ssid] = {
                    'ssid': ssid,
                    'signal': sig,
                    'security': sec,
                    'secured': bool(sec and sec != '--'),
                    'inUse': in_use,
                    'bssid': bssid
                }

    result = list(nets.values())
    result.sort(key=lambda x: (not x['inUse'], -x['signal'], x['ssid'].lower()))
    return {'networks': result}

def connect_wifi(ssid, password=None):
    if not ssid:
        return {'success': False, 'message': 'Missing SSID'}
    
    cmd = ['nmcli', 'dev', 'wifi', 'connect', ssid]
    if password:
        cmd.extend(['password', password])
    
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=25)
        if proc.returncode == 0:
            return {'success': True, 'message': proc.stdout.strip()}
        else:
            # If failed, check if a saved connection already exists and can be activated
            up_proc = subprocess.run(['nmcli', 'con', 'up', 'id', ssid], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=15)
            if up_proc.returncode == 0:
                return {'success': True, 'message': up_proc.stdout.strip()}
            return {'success': False, 'message': proc.stderr.strip() or proc.stdout.strip()}
    except subprocess.TimeoutExpired:
        return {'success': False, 'message': 'Connection timed out'}
    except Exception as e:
        return {'success': False, 'message': str(e)}

def disconnect_wifi(ssid=None):
    try:
        if ssid:
            proc = subprocess.run(['nmcli', 'con', 'down', 'id', ssid], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=10)
            if proc.returncode == 0:
                return {'success': True, 'message': proc.stdout.strip()}
        
        # Fallback: disconnect wifi device directly
        dev_out = subprocess.check_output(['nmcli', '-t', '-f', 'DEVICE,TYPE', 'dev'], stderr=subprocess.DEVNULL, text=True)
        wifi_dev = None
        for l in dev_out.strip().split('\n'):
            if ':wifi' in l:
                wifi_dev = l.split(':')[0]
                break
        if wifi_dev:
            proc = subprocess.run(['nmcli', 'dev', 'disconnect', wifi_dev], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=10)
            return {'success': proc.returncode == 0, 'message': proc.stdout.strip()}
        return {'success': False, 'message': 'No Wi-Fi interface found'}
    except Exception as e:
        return {'success': False, 'message': str(e)}

def status_wifi():
    try:
        out = subprocess.check_output(
            ['nmcli', '-t', '-f', 'active,ssid,signal,security', 'dev', 'wifi'],
            stderr=subprocess.DEVNULL,
            text=True
        )
        for line in out.strip().split('\n'):
            if line.startswith('yes:'):
                parts = split_nmcli(line)
                return {
                    'connected': True,
                    'ssid': parts[1],
                    'signal': int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else 0,
                    'security': parts[3] if len(parts) > 3 else ''
                }
        return {'connected': False, 'ssid': 'Disconnected', 'signal': 0, 'security': ''}
    except Exception as e:
        return {'connected': False, 'ssid': 'Disconnected', 'signal': 0, 'error': str(e)}

def main():
    if len(sys.argv) < 2 or sys.argv[1] == 'scan':
        print(json.dumps(scan_wifi()))
    elif sys.argv[1] == 'connect':
        ssid = sys.argv[2] if len(sys.argv) > 2 else ''
        pwd = sys.argv[3] if len(sys.argv) > 3 else None
        print(json.dumps(connect_wifi(ssid, pwd)))
    elif sys.argv[1] == 'disconnect':
        ssid = sys.argv[2] if len(sys.argv) > 2 else None
        print(json.dumps(disconnect_wifi(ssid)))
    elif sys.argv[1] == 'status':
        print(json.dumps(status_wifi()))
    else:
        print(json.dumps({'error': 'Unknown command'}))

if __name__ == '__main__':
    main()
