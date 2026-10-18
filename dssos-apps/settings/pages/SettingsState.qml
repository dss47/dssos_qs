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

    function setBrightness(val) {
        state.brightness = val;
        if (state.hasBacklight) {
            Quickshell.execDetached(["brightnessctl", "-q", "set", val + "%"]);
        }
    }

    function setResolution(resStr, idx) {
        if (idx !== undefined) state.currentResolutionIndex = idx;
        if (!state.displayOutput || !resStr) return;
        let clean = resStr.replace("(Recommended)", "").trim();
        let parts = clean.split(" × ");
        if (parts.length === 2) {
            let w = parts[0].trim();
            let h = parts[1].trim();
            let modeStr = w + "x" + h;
            setWayfire("output:" + state.displayOutput, "mode", modeStr + "@60000");
            Quickshell.execDetached(["wlr-randr", "--output", state.displayOutput, "--mode", modeStr]);
        }
    }

    function setScale(scaleVal) {
        // Enforce hard lower bound of 1.0: wlroots preferred_buffer_scale casts to int32_t,
        // so any scale < 1.0 truncates to 0 and triggers: Assertion `scale > 0' failed (SIGABRT).
        let clamped = Math.max(1.0, Math.min(3.0, Number(scaleVal) || 1.0));
        state.currentScale = clamped;
        state.displayScale = String(clamped);
        if (state.displayOutput) {
            Quickshell.execDetached(["wlr-randr", "--output", state.displayOutput, "--scale", String(clamped)]);
            setWayfire("output:" + state.displayOutput, "scale", String(clamped));
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
        if (!state.displayOutput || !rateStr) return;
        let rate = parseInt(rateStr);
        let currRes = state.availableResolutions[state.currentResolutionIndex] || "";
        let parts = currRes.split(" × ");
        if (parts.length === 2 && !isNaN(rate)) {
            let modeStr = parts[0].trim() + "x" + parts[1].trim() + "@" + rate + "Hz";
            Quickshell.execDetached(["wlr-randr", "--output", state.displayOutput, "--mode", modeStr]);
            setWayfire("output:" + state.displayOutput, "mode", modeStr);
        }
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
            powerProfile: state.powerProfile
        });
        Quickshell.execDetached(["dssos-settings-ctl", "save", payload]);
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
