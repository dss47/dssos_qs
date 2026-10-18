pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: state

    property bool open: false
    property string activeCategory: "system"

    // Persisted Shell + Wayfire Values
    property int barHeight: 34
    property int flyoutGap: 8
    property int slideIn: 200
    property int slideOut: 180
    property string accent: "green"

    property string kbLayout: "us"
    property int kbRepeatDelay: 400
    property int kbRepeatRate: 40
    property real mouseSpeed: 0.0
    property bool touchpadTap: true
    property bool touchpadNatural: true

    property bool wfAnimate: true
    property bool wfWobbly: false
    property bool wfCube: false
    property string displayScale: "1.0"
    property string powerProfile: "balanced"

    // Notification switches.
    //
    // These two did not exist at all: SetPageNotifications bound its toggles
    // to them, so the page rendered `undefined` and every click assigned to
    // nothing. There is still no notification daemon in DssOS, so what they
    // actually gate is the notification cards the shell shows -- see
    // QuickSettings.qml.
    property bool notificationsEnabled: true
    property bool doNotDisturb: false

    // Power profiles are DISCOVERED, never hardcoded.
    // "performance" only exists when a real cpufreq driver is present, so the
    // list on a VM is {balanced, power-saver} and on real hardware it gains a
    // third entry. The UI must render whatever this machine actually offers.
    property var powerProfiles: []
    property int powerProfileIndex: 0

    // Battery (absent on desktops and in VMs -> batteryPresent stays false)
    property bool batteryPresent: false
    property int batteryLevel: 0
    property string batteryStatus: "Unknown"

    // Display & Hardware Backlight
    property int brightness: 100
    property bool hasBacklight: false
    property string displayOutput: ""
    property var availableResolutions: []
    property int currentResolutionIndex: 0
    property var availableRefreshRates: ["60 Hz"]
    property int currentRefreshIndex: 0
    property var availableScales: ["100% (recommended)", "125%", "200%", "Custom"]
    property var scaleValues: [1.0, 1.25, 2.0]
    property int currentScaleIndex: 0
    property real currentScale: 1.0

    // System Info
    property string sysHost: "dssos"
    property string sysKernel: "Linux"
    property string sysUptime: "..."
    property string sysCpu: "Intel i7-7600U"
    property string sysMem: "..."
    property string displayInfo: "Detecting display..."

    property bool loaded: false

    // QML treats `property var x: Process {...}` as a BINDING: the object is
    // only built when the property is READ. Nothing read loadProc on startup, so
    // it was never created, never ran, `loaded` stayed false, and save() then
    // returned early -- silently discarding every setting change. Touching each
    // one inside an array literal forces evaluation at construction time.
    property var _forceInit: [
        loadProc, randrProc, brightProc, sysInfoProc,
        dispInfoProc, powerListProc, powerGetProc,
        batteryProc, batteryTimer
    ]

    function setBrightness(val) {
        state.brightness = val;
        if (state.hasBacklight) {
            Quickshell.execDetached(["brightnessctl", "-q", "set", val + "%"]);
        }
    }

    function currentRefreshHz() {
        const s = state.availableRefreshRates[state.currentRefreshIndex];
        if (!s) return 0;
        const hz = parseInt(s);
        return isNaN(hz) ? 0 : hz;
    }

    function currentResolutionWH() {
        const s = state.availableResolutions[state.currentResolutionIndex];
        if (!s) return [0, 0];
        const parts = s.split("×");
        if (parts.length !== 2) return [0, 0];
        const w = parseInt(parts[0].trim());
        const h = parseInt(parts[1].trim());
        return [isNaN(w) ? 0 : w, isNaN(h) ? 0 : h];
    }

    // Single place that actually puts a mode on screen.
    // Wayfire owns output state: writing [output:NAME] mode is enough, because
    // the compositor watches its config file with inotify (IN_CLOSE_WRITE) and
    // reconfigures the output live. No wlr-randr call, no compositor restart.
    function applyMode(w, h, hz) {
        if (!state.displayOutput || !w || !h) return;
        let rr = (hz === undefined || hz === null || isNaN(hz)) ? state.currentRefreshHz() : hz;
        if (!rr) rr = 60;
        // dssos-settings-ctl builds the wayfire string; never build it here.
        Quickshell.execDetached(["dssos-settings-ctl", "output",
                                state.displayOutput, String(w), String(h), String(Math.round(rr))]);
    }

    function setResolution(resStr, idx) {
        if (idx !== undefined) state.currentResolutionIndex = idx;
        if (!state.displayOutput || !resStr) return;
        // Labels look like "1920 × 1080 (Recommended)". Split on the sign, not on
        // the exact spacing, and drop every non-numeric label before use.
        const parts = resStr.split("×");
        if (parts.length !== 2) return;
        const w = parseInt(parts[0].trim());
        const h = parseInt(parts[1].trim());
        if (isNaN(w) || isNaN(h)) return;
        // Keep the user's chosen refresh rate instead of forcing 60 Hz.
        applyMode(w, h, state.currentRefreshHz());
    }

    function setScale(scaleVal) {
        // Enforce hard lower bound of 1.0: wlroots preferred_buffer_scale casts to int32_t,
        // so any scale < 1.0 truncates to 0 and triggers: Assertion `scale > 0' failed (SIGABRT).
        let clamped = Math.max(1.0, Math.min(3.0, Number(scaleVal) || 1.0));
        state.currentScale = clamped;
        state.displayScale = String(clamped);
        if (state.displayOutput) {
            Quickshell.execDetached(["dssos-settings-ctl", "output-scale",
                                    state.displayOutput, String(clamped)]);
        }
        save();
    }

    function applyScaleByIndex(idx) {
        state.currentScaleIndex = idx;
        if (idx === 0) setScale(1.0);
        else if (idx === 1) setScale(1.25);
        else if (idx === 2) setScale(2.0);
    }

    function setCustomScale(val) {
        state.currentScaleIndex = 3;
        setScale(val);
    }

    function setRefresh(rateStr) {
        const idx = state.availableRefreshRates.indexOf(rateStr);
        if (idx >= 0) state.currentRefreshIndex = idx;
        const hz = parseInt(rateStr);
        if (isNaN(hz)) return;
        const wh = state.currentResolutionWH();
        if (!wh[0] || !wh[1]) return;
        applyMode(wh[0], wh[1], hz);
    }

    function syncStyle() {
        if (typeof Style !== "undefined") {
            Style.barHeight = state.barHeight;
            Style.flyoutGap = state.flyoutGap;
            Style.slideIn = state.slideIn;
            Style.slideOut = state.slideOut;
            Style.accentName = state.accent;
        }
    }

    // Every one of these used to be a plain property with no handler: dragging
    // the taskbar height, the flyout gap, the key repeat rate, the pointer speed
    // or a Wayfire effect toggle changed the value in memory and nothing else.
    // The window was closed and the change was gone, because only setScale()
    // and setPowerProfile() ever reached save().
    //
    // save() returns early while `loaded` is false, so the handlers are safe to
    // fire during the initial load -- they cannot overwrite the stored file
    // with the defaults that are still being read into it.
    onAccentChanged: save()
    onBarHeightChanged: save()
    onFlyoutGapChanged: save()
    onKbRepeatDelayChanged: save()
    onKbRepeatRateChanged: save()
    onMouseSpeedChanged: save()
    onTouchpadTapChanged: save()
    onTouchpadNaturalChanged: save()
    onWfAnimateChanged: { save(); applyWayfireEffects(); }
    onWfWobblyChanged: { save(); applyWayfireEffects(); }
    onWfCubeChanged: { save(); applyWayfireEffects(); }
    onNotificationsEnabledChanged: save()
    onDoNotDisturbChanged: save()

    function save() {
        if (!loaded) return;
        syncStyle();
        const payload = JSON.stringify({
            barHeight: state.barHeight,
            flyoutGap: state.flyoutGap,
            slideIn: state.slideIn,
            slideOut: state.slideOut,
            accent: state.accent,
            kbLayout: state.kbLayout,
            kbRepeatDelay: state.kbRepeatDelay,
            kbRepeatRate: state.kbRepeatRate,
            mouseSpeed: Number(state.mouseSpeed.toFixed(2)),
            touchpadTap: state.touchpadTap,
            touchpadNatural: state.touchpadNatural,
            wfAnimate: state.wfAnimate,
            wfWobbly: state.wfWobbly,
            wfCube: state.wfCube,
            displayScale: state.displayScale,
            powerProfile: state.powerProfile,
            notificationsEnabled: state.notificationsEnabled,
            doNotDisturb: state.doNotDisturb
        });
        Quickshell.execDetached(["dssos-settings-ctl", "save", payload]);
    }

    function profileLabel(p) {
        if (p === "power-saver") return "Power Saver";
        if (p === "balanced") return "Balanced";
        if (p === "performance") return "Performance";
        return p;
    }

    // Called from the radio. The list is already validated against this machine,
    // but re-check anyway so a stale index can never send a bogus profile.
    function setPowerProfileByIndex(idx) {
        if (idx < 0 || idx >= state.powerProfiles.length) return;
        state.powerProfileIndex = idx;
        state.setPowerProfile(state.powerProfiles[idx]);
    }

    function setPowerProfile(prof) {
        if (!prof) return;
        state.powerProfile = prof;
        Quickshell.execDetached(["dssos-settings-ctl", "power-set", prof]);
        // Re-read instead of assuming success: polkit can still refuse.
        batteryTimer.count = 0;
        powerGetProc.running = true;
        save();
    }

    function refreshBattery() {
        batteryProc.running = true;
    }

    // Pushes the three effect toggles into wayfire.ini.
    //
    // They were plain properties before: flipping a switch changed a boolean
    // that nothing read, and setWayfire() had zero callers in the whole tree.
    //
    // Two of them are ordinary ini keys. The third, `cube`, is not -- it is a
    // word in the [core] plugins list, which is why dssos-settings-ctl grew a
    // wayfire-plugin verb instead of being handed a fixed string to write.
    function applyWayfireEffects() {
        // Wayfire's animate plugin has no on/off key: an animation is either a
        // name or "none", on each of the three transitions.
        const anim = state.wfAnimate ? "zoom" : "none";
        setWayfire("animate", "open_animation", anim);
        setWayfire("animate", "close_animation", anim);
        setWayfire("animate", "minimize_animation", anim);

        setWayfire("wobbly", "enabled_for", state.wfWobbly ? "all" : "none");

        Quickshell.execDetached(["dssos-settings-ctl", "wayfire-plugin", "cube",
                                 state.wfCube ? "1" : "0"]);
    }

    function setWayfire(section, key, val) {
        Quickshell.execDetached(["dssos-settings-ctl", "wayfire", section, key, String(val)]);
    }

    function refreshSysInfo() {
        sysInfoProc.running = true;
        dispInfoProc.running = true;
    }

    property var loadProc: Process {
        id: loadProc
        command: ["dssos-settings-ctl", "load"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim());
                    if (d.barHeight !== undefined) state.barHeight = d.barHeight;
                    if (d.flyoutGap !== undefined) state.flyoutGap = d.flyoutGap;
                    if (d.slideIn !== undefined) state.slideIn = d.slideIn;
                    if (d.slideOut !== undefined) state.slideOut = d.slideOut;
                    if (d.accent !== undefined) state.accent = d.accent;
                    if (d.kbLayout !== undefined) state.kbLayout = d.kbLayout;
                    if (d.kbRepeatDelay !== undefined) state.kbRepeatDelay = d.kbRepeatDelay;
                    if (d.kbRepeatRate !== undefined) state.kbRepeatRate = d.kbRepeatRate;
                    if (d.mouseSpeed !== undefined) state.mouseSpeed = d.mouseSpeed;
                    if (d.touchpadTap !== undefined) state.touchpadTap = d.touchpadTap;
                    if (d.touchpadNatural !== undefined) state.touchpadNatural = d.touchpadNatural;
                    if (d.wfAnimate !== undefined) state.wfAnimate = d.wfAnimate;
                    if (d.wfWobbly !== undefined) state.wfWobbly = d.wfWobbly;
                    if (d.wfCube !== undefined) state.wfCube = d.wfCube;
                    if (d.displayScale !== undefined) state.displayScale = d.displayScale;
                    if (d.powerProfile !== undefined) state.powerProfile = d.powerProfile;
                    if (d.notificationsEnabled !== undefined) state.notificationsEnabled = d.notificationsEnabled;
                    if (d.doNotDisturb !== undefined) state.doNotDisturb = d.doNotDisturb;
                } catch (e) {
                    console.log("Settings JSON load fallback:", e);
                }
                state.loaded = true;
                state.syncStyle();
            }
        }
    }

    property var sysInfoProc: Process {
        id: sysInfoProc
        command: ["dssos-settings-ctl", "sysinfo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const info = JSON.parse(text.trim());
                    state.sysHost = info.host || "dssos";
                    state.sysKernel = info.kernel || "Arch Linux";
                    state.sysUptime = info.uptime || "0m";
                    state.sysCpu = info.cpu || "Intel i7-7600U";
                    state.sysMem = info.mem || "N/A";
                } catch (e) {}
            }
        }
    }

    property var dispInfoProc: Process {
        id: dispInfoProc
        command: ["dssos-settings-ctl", "displays"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                if (out.length > 0 && state.displayInfo.startsWith("Detecting")) state.displayInfo = out;
            }
        }
    }

    property var brightProc: Process {
        id: brightProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const lines = text.trim().split("\n");
                    for (let i = 0; i < lines.length; i++) {
                        let parts = lines[i].split(",");
                        if (parts.length >= 4 && parts[1] === "backlight") {
                            state.hasBacklight = true;
                            let pct = parseInt(parts[3].replace("%", ""));
                            if (!isNaN(pct)) state.brightness = pct;
                            break;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: {
        loadProc.running = true;
        randrProc.running = true;
        brightProc.running = true;
        powerListProc.running = true;
        powerGetProc.running = true;
        batteryProc.running = true;
        sysInfoProc.running = true;
        dispInfoProc.running = true;
    }

    // The profile list is static for the life of the session (it only depends
    // on which cpufreq driver the hardware exposes), so it is fetched once and
    // never polled. Only the battery is polled, and slowly: it is a percentage
    // that changes over minutes, so 15s is already generous and keeps process
    // spawns (which are not free on a 2C/4T laptop) near zero.
    property var powerListProc: Process {
        id: powerListProc
        
        command: ["dssos-settings-ctl", "power-list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.trim().split("\n")
                    .map(s => s.trim())
                    .filter(s => s.length > 0);
                if (names.length === 0) {
                    state.powerProfiles = [];
                    return;
                }
                state.powerProfiles = names;
                const cur = names.indexOf(state.powerProfile);
                state.powerProfileIndex = cur >= 0 ? cur : 0;
            }
        }
    }

    property var powerGetProc: Process {
        id: powerGetProc
        
        command: ["dssos-settings-ctl", "power-get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const cur = text.trim();
                if (!cur) return;
                state.powerProfile = cur;
                const idx = state.powerProfiles.indexOf(cur);
                if (idx >= 0) state.powerProfileIndex = idx;
            }
        }
    }

    property var batteryProc: Process {
        id: batteryProc
        
        command: ["dssos-settings-ctl", "battery"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim());
                    state.batteryPresent = !!d.present;
                    if (d.present) {
                        state.batteryLevel = parseInt(d.capacity) || 0;
                        state.batteryStatus = d.status || "Unknown";
                    }
                } catch (e) {}
            }
        }
    }

    property var batteryTimer: Timer {
        id: batteryTimer
        
        interval: 15000
        repeat: true
        running: true
        onTriggered: batteryProc.running = true
    }

    property var randrProc: Process {
        id: randrProc
        command: ["wlr-randr", "--json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim());
                    if (data && data.length > 0) {
                        const out = data[0];
                        state.displayOutput = out.name || "";
                        state.currentScale = out.scale || 1.0;
                        state.displayScale = String(out.scale || 1.0);

                        let resMap = {};
                        let resList = [];
                        let activeResIdx = 0;
                        let rates = [];
                        let activeRateIdx = 0;

                        if (out.modes) {
                            let nativeW = 0, nativeH = 0;
                            let currentW = 0, currentH = 0;

                            for (let i = 0; i < out.modes.length; i++) {
                                const m = out.modes[i];
                                if (m.preferred || nativeW === 0) {
                                    nativeW = m.width;
                                    nativeH = m.height;
                                }
                                if (m.current) {
                                    currentW = m.width;
                                    currentH = m.height;
                                }
                            }

                            // Standard desktop resolutions in priority order
                            const standardSizes = [
                                { w: 3840, h: 2160 },
                                { w: 2560, h: 1440 },
                                { w: 1920, h: 1080 },
                                { w: 1600, h: 900 },
                                { w: 1366, h: 768 },
                                { w: 1360, h: 768 },
                                { w: 1280, h: 720 },
                                { w: 1280, h: 768 },
                                { w: 1024, h: 768 },
                                { w: 800, h: 600 }
                            ];

                            // Catalog actual modes provided by the hardware
                            let hwModes = {};
                            for (let i = 0; i < out.modes.length; i++) {
                                const m = out.modes[i];
                                hwModes[m.width + "x" + m.height] = true;
                            }

                            // Curate the most relevant resolutions (max 4-5)
                            let selected = [];
                            let seen = {};

                            // 1. Native / Preferred mode
                            let nativeKey = nativeW + "x" + nativeH;
                            selected.push({ w: nativeW, h: nativeH, isNative: true });
                            seen[nativeKey] = true;

                            // 2. Currently active mode (if different)
                            if (currentW > 0 && currentH > 0) {
                                let currKey = currentW + "x" + currentH;
                                if (!seen[currKey]) {
                                    selected.push({ w: currentW, h: currentH, isNative: false });
                                    seen[currKey] = true;
                                }
                            }

                            // 3. Supported standard resolutions <= screen dimensions (max 1080p for VMs)
                            let maxW = Math.max(nativeW, 1920);
                            let maxH = Math.max(nativeH, 1080);
                            for (let j = 0; j < standardSizes.length; j++) {
                                if (selected.length >= 5) break;
                                const s = standardSizes[j];
                                let key = s.w + "x" + s.h;
                                if (!seen[key] && hwModes[key] && s.w <= maxW && s.h <= maxH) {
                                    selected.push({ w: s.w, h: s.h, isNative: false });
                                    seen[key] = true;
                                }
                            }

                            // Sort descending by resolution area
                            selected.sort((a, b) => (b.w * b.h) - (a.w * a.h));

                            // Build final display list
                            for (let i = 0; i < selected.length; i++) {
                                const item = selected[i];
                                let raw = item.w + " × " + item.h;
                                let label = raw + (item.isNative ? " (Recommended)" : "");
                                resList.push(label);
                                if (item.w === currentW && item.h === currentH) {
                                    activeResIdx = i;
                                }
                            }

                            state.availableResolutions = resList;
                            state.currentResolutionIndex = activeResIdx;

                            let currResStr = resList[activeResIdx] || "";
                            let currParts = currResStr.split(" × ");
                            let cw = parseInt(currParts[0]) || 0;
                            let ch = parseInt(currParts[1]) || 0;
                            for (let i = 0; i < out.modes.length; i++) {
                                const m = out.modes[i];
                                if (m.width === cw && m.height === ch) {
                                    rates.push(Math.round(m.refresh) + " Hz");
                                    if (m.current) {
                                        activeRateIdx = rates.length - 1;
                                    }
                                }
                            }
                            state.availableRefreshRates = rates.length > 0 ? rates : ["60 Hz"];
                            state.currentRefreshIndex = activeRateIdx;

                            state.availableScales = ["100% (recommended)", "125%", "200%", "Custom"];
                            state.scaleValues = [1.0, 1.25, 2.0];
                            let curS = out.scale || 1.0;
                            if (Math.abs(curS - 1.0) < 0.05) state.currentScaleIndex = 0;
                            else if (Math.abs(curS - 1.25) < 0.05) state.currentScaleIndex = 1;
                            else if (Math.abs(curS - 2.0) < 0.05) state.currentScaleIndex = 2;
                            else state.currentScaleIndex = 3;
                        }
                    }
                } catch (e) {}
            }
        }
    }
}
