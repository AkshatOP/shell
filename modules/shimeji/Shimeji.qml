import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Caelestia.Config
import Caelestia.State
import qs.components.containers
import qs.components
import qs.services
import qs.utils

StyledWindow {
    id: root

    required property ShellScreen modelData
    property int shimejiCount: 1

    readonly property alias shimejiScreen: root.modelData

    readonly property bool shouldBeVisible: !RuntimeState.gameMode && (!GlobalConfig.forScreen(modelData.name).shimeji.autoHide || (Hypr.monitorFor(modelData)?.activeWorkspace?.toplevels?.values.every(t => t.lastIpcObject?.floating) ?? true))

    property var extractedPaths: []

    property Process extractor: Process {
        running: false
        command: ["unzip", "-o"]
        workingDirectory: "/tmp"
    }

    readonly property real borderThickness: modelData ? contentItem.Config.border.thickness : 0

    // Upstream's bar is always on the left (no bar.position), so there is never a bottom bar to stand on
    readonly property real floorOffset: 0

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

    screen: modelData
    visible: shouldBeVisible

    name: "shimeji"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    surfaceFormat.opaque: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Component.onCompleted: {
        Qt.callLater(() => {
            extractor.running = false;
        });
    }

    Item {
        anchors.fill: parent

        Repeater {
            id: spriteRepeater

            model: root.shimejiCount > 0 ? root.shimejiCount : 1

            ShimejiSprite {
                screenSize: Qt.size(shimejiScreen.width, shimejiScreen.height)
                borderThickness: root.borderThickness
                floorOffset: root.floorOffset
                imgPath: root.getImgPath()
            }
        }
    }
}
