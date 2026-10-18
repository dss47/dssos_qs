#!/usr/bin/env python3
import sys
import subprocess
import json
import re

def list_devices():
    devices = []
    try:
        out = subprocess.check_output(['bluetoothctl', 'devices'], stderr=subprocess.DEVNULL, text=True)
    except Exception as e:
        return {'devices': [], 'error': str(e)}

    for line in out.strip().split('\n'):
        if not line.startswith('Device '):
            continue
        parts = line.split(' ', 2)
        if len(parts) >= 3:
            mac = parts[1].strip()
            name = parts[2].strip()
            conn = False
            paired = False
            icon = 'bl'
            battery = None
            try:
                info = subprocess.check_output(['bluetoothctl', 'info', mac], stderr=subprocess.DEVNULL, text=True)
                conn = 'Connected: yes' in info
                paired = 'Paired: yes' in info
                for iline in info.split('\n'):
                    if 'Icon:' in iline:
                        raw_icon = iline.split(':', 1)[1].strip()
                        if 'headset' in raw_icon or 'audio' in raw_icon:
                            icon = 'vl'
                        elif 'phone' in raw_icon:
                            icon = 'hs'
                        else:
                            icon = 'bl'
                    elif 'Battery Percentage:' in iline:
                        # Extract percentage e.g. 0x14 (20)
                        m = re.search(r'\((\d+)\)', iline)
                        if m:
                            battery = int(m.group(1))
            except Exception:
                pass

            devices.append({
                'mac': mac,
                'name': name,
                'connected': conn,
                'paired': paired,
                'icon': icon,
                'battery': battery
            })

    devices.sort(key=lambda x: (not x['connected'], not x['paired'], x['name'].lower()))
    return {'devices': devices}

def connect_device(mac):
    if not mac:
        return {'success': False, 'message': 'Missing MAC address'}
    try:
        proc = subprocess.run(['bluetoothctl', 'connect', mac], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=15)
        success = (proc.returncode == 0) or ('Connection successful' in proc.stdout)
        return {'success': success, 'message': proc.stdout.strip() or proc.stderr.strip()}
    except subprocess.TimeoutExpired:
        return {'success': False, 'message': 'Connection timed out'}
    except Exception as e:
        return {'success': False, 'message': str(e)}

def disconnect_device(mac):
    if not mac:
        return {'success': False, 'message': 'Missing MAC address'}
    try:
        proc = subprocess.run(['bluetoothctl', 'disconnect', mac], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=10)
        success = (proc.returncode == 0) or ('Successful disconnected' in proc.stdout)
        return {'success': success, 'message': proc.stdout.strip() or proc.stderr.strip()}
    except Exception as e:
        return {'success': False, 'message': str(e)}

def remove_device(mac):
    if not mac:
        return {'success': False, 'message': 'Missing MAC address'}
    try:
        proc = subprocess.run(['bluetoothctl', 'remove', mac], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=10)
        return {'success': proc.returncode == 0, 'message': proc.stdout.strip()}
    except Exception as e:
        return {'success': False, 'message': str(e)}

def toggle_power(state=None):
    try:
        if state is None:
            # check current state
            show = subprocess.check_output(['bluetoothctl', 'show'], stderr=subprocess.DEVNULL, text=True)
            powered = 'Powered: yes' in show
            target = 'off' if powered else 'on'
        else:
            target = 'on' if state.lower() in ['1', 'true', 'on', 'yes'] else 'off'
        proc = subprocess.run(['bluetoothctl', 'power', target], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=5)
        return {'success': proc.returncode == 0, 'powered': target == 'on'}
    except Exception as e:
        return {'success': False, 'message': str(e)}

def main():
    if len(sys.argv) < 2 or sys.argv[1] == 'list':
        print(json.dumps(list_devices()))
    elif sys.argv[1] == 'connect':
        mac = sys.argv[2] if len(sys.argv) > 2 else ''
        print(json.dumps(connect_device(mac)))
    elif sys.argv[1] == 'disconnect':
        mac = sys.argv[2] if len(sys.argv) > 2 else ''
        print(json.dumps(disconnect_device(mac)))
    elif sys.argv[1] == 'remove':
        mac = sys.argv[2] if len(sys.argv) > 2 else ''
        print(json.dumps(remove_device(mac)))
    elif sys.argv[1] == 'toggle':
        st = sys.argv[2] if len(sys.argv) > 2 else None
        print(json.dumps(toggle_power(st)))
    else:
        print(json.dumps({'error': 'Unknown command'}))

if __name__ == '__main__':
    main()
