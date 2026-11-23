import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Caelestia.Config
import Caelestia.State
import qs.components
import qs.components.containers
import qs.services
import qs.utils

StyledWindow {
    id: root

    required property ShellScreen modelData
    property int shimejiCount: 1

    readonly property alias shimejiScreen: root.modelData

    // Hidden in game mode (MiDnight's default: utilities.gameMode.disableShimeji = true)
    readonly property bool shouldBeVisible: !RuntimeState.gameMode && (!GlobalConfig.forScreen(modelData.name).shimeji.autoHide || (Hypr.monitorFor(modelData)?.activeWorkspace?.toplevels?.values.every(t => t.lastIpcObject?.floating) ?? true))

    property var extractedPaths: []

    property Process extractor: Process {
        running: false
        command: ["unzip", "-o"]
        workingDirectory: "/tmp"
    }

    readonly property real borderThickness: modelData ? contentItem.Config.border.thickness : 0

    readonly property real shimejiScale: contentItem.Config.shimeji.scale

    // Upstream: the per-screen BarWrapper is registered in ShellState (MiDnight used Visibilities.bars)
    readonly property var barWrapper: root.modelData ? ShellState.componentsFor(root.modelData)?.bar : undefined

    readonly property real barExclusiveZone: barWrapper?.exclusiveZone ?? (contentItem.Tokens.sizes.bar.innerWidth + Math.max(contentItem.Tokens.padding.small, contentItem.Config.border.thickness))

    // Upstream's bar is always on the left edge (no bar.position option)
    readonly property real floorOffset: 0
    readonly property real ceilingOffset: 0
    readonly property real leftOffset: barExclusiveZone
    readonly property real rightOffset: 0

    // The window's input mask covers only the sprites — everything outside
    // their rects passes input through to windows, panels and the desktop.
    property list<Region> spriteMasks: []

    function getImgPath(): string {
        if (!modelData)
            return "";
        // Upstream Paths.absolutePath doesn't expand "root:" (MiDnight's did), so do it here
        let path = Paths.absolutePath(String(contentItem.Config.shimeji.path).replace(/^root:\/?/, Quickshell.shellDir + "/"));
        if (!path)
            return "";

        if (path.endsWith(".zip")) {
            const extractDir = path.replace(".zip", "/");
            if (!extractor.running && !extractedPaths.includes(path)) {
                extractedPaths.push(path);
                extractor.arguments = ["-o", "-d", extractDir, path];
                extractor.running = true;
            }
            return extractDir;
        }

        return path.replace(/\/?$/, "/");
    }

    function registerSpriteMask(region: Region): void {
        if (!root.spriteMasks.includes(region))
            root.spriteMasks = [...root.spriteMasks, region];
    }

    function unregisterSpriteMask(region: Region): void {
        root.spriteMasks = root.spriteMasks.filter(m => m !== region);
    }

    mask: Region {
        regions: root.spriteMasks
    }

    screen: modelData
    visible: shouldBeVisible

    name: "shimeji"
    // Top layer: the shimeji walks above windows (like the real Shimeji pet).
    // Bottom-layer input routing made grabbing unreliable (clicks competed
    // with regular windows and the fullscreen wallpaper surface).
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    surfaceFormat.opaque: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Item {
        anchors.fill: parent

        Repeater {
            id: spriteRepeater

            model: Math.max(1, root.shimejiCount)

            ShimejiSprite {
                maskHost: root
                screenSize: Qt.size(shimejiScreen.width, shimejiScreen.height)
                borderThickness: root.borderThickness
                sizeScale: root.shimejiScale
                floorOffset: root.floorOffset
                ceilingOffset: root.ceilingOffset
                leftOffset: root.leftOffset
                rightOffset: root.rightOffset
                imgPath: root.getImgPath()
            }
        }
    }
}
