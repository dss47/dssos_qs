pragma Singleton
import QtQuick

QtObject {
    id: icons

    readonly property var paths: ({
        sr: '<circle cx="11" cy="11" r="6"/><path d="M20 20l-4-4"/>',
        fd: '<path d="M3 6h7l2 2h9v11H3z"/>',
        tm: '<path d="M4 7l5 5-5 5M12 17h8"/>',
        gl: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/>',
        gr: '<circle cx="12" cy="12" r="3"/><path d="M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M5.6 18.4l2.1-2.1M16.3 7.7l2.1-2.1"/>',
        ch: '<path d="M3 12h4l3-8 4 16 3-8h4"/>',
        wf: '<path d="M2 9a15 15 0 0 1 20 0M5 13a10 10 0 0 1 14 0M8.5 16.5a5 5 0 0 1 7 0M12 20h.01"/>',
        vl: '<path d="M4 9v6h4l5 4V5L8 9zM16 9a4 4 0 0 1 0 6"/>',
        bt: '<rect x="2" y="7" width="18" height="10"/><path d="M22 11v2M5 10v4M8 10v4M11 10v4"/>',
        bl: '<path d="M7 7l10 10-5 4V3l5 4L7 17"/>',
        mn: '<path d="M20 14A8 8 0 1 1 10 4a6 6 0 0 0 10 10z"/>',
        pw: '<path d="M12 3v9M7 6a8 8 0 1 0 10 0"/>',
        rs: '<path d="M20 12a8 8 0 1 1-3-6.2M20 4v5h-5"/>',
        sl: '<path d="M20 14A8 8 0 1 1 10 4a6 6 0 0 0 10 10z"/>',
        ms: '<path d="M9 18V6l10-2v12"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="16" r="2"/>',
        cl: '<rect x="4" y="5" width="16" height="15"/><path d="M4 10h16M9 3v4M15 3v4"/>',
        im: '<rect x="3" y="5" width="18" height="14"/><circle cx="9" cy="10" r="2"/><path d="M3 17l5-4 4 3 4-4 5 4"/>',
        pd: '<path d="M6 3h8l4 4v14H6zM14 3v4h4"/>',
        cd: '<path d="M9 8l-4 4 4 4M15 8l4 4-4 4"/>',
        sn: '<circle cx="12" cy="12" r="4"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>',
        pl: '<path d="M17.8 19.2L16 11l3.5-3.5C21 6 21.5 4 21 3.5c-.5-.5-2.5 0-4 1.5L13.5 8.5 5.3 6.7 4 8l6 4-3 3-2.5-.5L3 16l3.5 1.5L8 21l1.5-1.5-.5-2.5 3-3 4 6 1.8-1.3z"/>',
        dn: '<path d="M13.73 21a2 2 0 0 1-3.46 0M18.63 13A17.89 17.89 0 0 1 18 8M6.26 6.26A5.86 5.86 0 0 0 6 8c0 7-3 9-3 9h14M1 1l22 22"/>',
        sv: '<rect x="2" y="7" width="18" height="10"/><path d="M22 11v2M11 10v4"/>',
        lk: '<rect x="3" y="11" width="18" height="11"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
        hs: '<circle cx="12" cy="12" r="2"/><path d="M16.24 7.76a6 6 0 0 1 0 8.49m-8.48-.01a6 6 0 0 1 0-8.49m11.31-2.82a10 10 0 0 1 0 14.14m-14.14 0a10 10 0 0 1 0-14.14"/>'
    })

    readonly property var _cache: ({})

    function get(name, strokeColor, strokeWidth) {
        var c = strokeColor ? strokeColor.toString() : "#8c8c8c";
        var sw = strokeWidth ? strokeWidth.toString() : "1.6";
        var key = name + "_" + c + "_" + sw;
        if (_cache[key]) return _cache[key];

        var p = paths[name] || "";
        var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="' + sw + '" stroke-linecap="round" stroke-linejoin="round">' + p + '</svg>';
        var uri = "data:image/svg+xml;utf8," + encodeURIComponent(svg);
        _cache[key] = uri;
        return uri;
    }
}
