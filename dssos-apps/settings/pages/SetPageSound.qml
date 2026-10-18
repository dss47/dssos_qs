import settings
import QtQuick
import QtQuick.Layouts
import Quickshell

// SettingsState never had `volume`/`micVolume`: both sliders here read and
// assigned properties that did not exist, so they showed nothing and every drag
// wrote into the void. PipeWire owns the volume, and QuickSettings already
// talks to it this way -- mirroring it into JSON would add a second source of
// truth that nothing applies.
readonly property var sink: Pipewire.defaultAudioSink
readonly property var source: Pipewire.defaultAudioSource

// PipeWire volumes are 0..1; the sliders are 0..100.
readonly property real volPct: sink && sink.audio ? sink.audio.volume * 100 : 0
readonly property real micPct: source && source.audio ? source.audio.volume * 100 : 0

PwObjectTracker { objects: [soundPage.sink, soundPage.source] }

// System > Sound
ColumnLayout {
    id: soundPage
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Sound"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Output"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Output device"
            hint: "Select where to play audio"
            SetDropdown {
                options: ["Built-in Speakers", "Headphones (3.5mm)", "HDMI Audio"]
                current: 0
            }
        }

        SetRow {
            label: "Master volume"
            SetSlider {
                id: volSlider
                from: 0
                to: 100
                value: soundPage.volPct
                onMoved: (v) => { if (soundPage.sink && soundPage.sink.audio)
                                      soundPage.sink.audio.volume = v / 100; }
            }
            Text {
                text: Math.round(volSlider.value) + "%"
                font.pixelSize: 13
                color: SettingsTheme.text
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 38
            }
        }

        SetRow {
            label: "Over-amplification"
            hint: "Allow volume boost above 100% for quiet media"
            isLast: true
            SetToggle { on: false }
        }
    }

    Text {
        text: "Input"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Input device"
            SetDropdown {
                options: ["Internal Microphone", "Headset Mic"]
                current: 0
            }
        }

        SetRow {
            label: "Microphone level"
            SetSlider {
                id: micSlider
                from: 0
                to: 100
                value: soundPage.micPct
                onMoved: (v) => { if (soundPage.source && soundPage.source.audio)
                                      soundPage.source.audio.volume = v / 100; }
            }
            Text {
                text: Math.round(micSlider.value) + "%"
                font.pixelSize: 13
                color: SettingsTheme.text
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 38
            }
        }

        SetRow {
            label: "Noise suppression"
            hint: "Lightweight voice filter optimized for low CPU usage"
            isLast: true
            SetToggle { on: true }
        }
    }
}
