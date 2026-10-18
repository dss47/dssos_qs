import QtQuick
import QtQuick.Layouts

// Network > VPN
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "VPN"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "WireGuard tunnels"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "wg0-Frankfurt"
            hint: "10.66.66.2/32 • Endpoint 185.212.x.x:51820"
            SetToggle { on: false }
        }

        SetRow {
            label: "wg1-WorkLab"
            hint: "10.10.0.14/24 • Split tunnel active"
            isLast: true
            SetToggle { on: false }
        }
    }

    Text {
        text: "Connection security"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Auto-connect on untrusted Wi-Fi"
            SetToggle { on: false }
        }

        SetRow {
            label: "DNS leak protection"
            hint: "Route all DNS queries strictly through active tunnel"
            isLast: true
            SetToggle { on: true }
        }
    }
}
