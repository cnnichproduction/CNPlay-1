import QtQuick 2.15

Rectangle {
    id: c
    property var game: null
    property bool focused: false
    property string mode: "box"   // "box" = poster, "banner" = wide art
    radius: 10
    color: "#0a1a3a"
    border.width: focused ? 4 : 1
    border.color: focused ? "#3d8bff" : "#14306b"
    scale: focused ? 1.04 : 1.0
    z: focused ? 2 : 1
    Behavior on scale { NumberAnimation { duration: 120 } }

    // Title shows when a game has no artwork
    Text {
        anchors.centerIn: parent
        width: parent.width - 16
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: "#8fb0ff"; font.pixelSize: 22; font.bold: true
        text: c.game ? c.game.title : ""
    }
    Image {
        anchors { fill: parent; margins: 3 }
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: !c.game ? "" : (c.mode === "banner"
                ? (c.game.assets.banner || c.game.assets.background || c.game.assets.boxFront)
                : (c.game.assets.boxFront || c.game.assets.banner))
    }
}
