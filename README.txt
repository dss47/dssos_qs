dssos-ui - Quickshell shell for DssOS (Hyprland)
Test with: qs -p ~/dssos-ui/shell.qml

Layout:
  shell.qml            entry point, instantiates everything in components/
  components/BarState.qml          shared open/close state (only one flyout at a time)
  components/ContextMenuState.qml  single context-menu controller (show + fire by index)
  components/Style.qml             single palette / motion / geometry source
  components/Taskbar.qml           bottom bar: start button, live Hyprland windows, tray
  components/QuickSettings.qml     right flyout: toggles, sliders, wifi/bt pages
  components/StartMenu.qml         app launcher with search (DesktopEntries)
  components/HiddenTray.qml        tray overflow popup, anchored under the chevron
  components/ContextMenu.qml       the one shared right-click menu window
  assets/icons/              svg icons used by tiles, tray and menus
  Preview/                   mockups and logo drafts (not used by the shell)
