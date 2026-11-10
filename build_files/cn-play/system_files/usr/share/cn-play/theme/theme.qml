import QtQuick 2.15

FocusScope {
    id: root
    focus: true

    // ------------------------------------------------------------ colors
    readonly property color accent: "#1a73ff"
    readonly property color accentSoft: "#3d8bff"
    readonly property color panel: "#07142e"
    readonly property color line: "#14306b"
    readonly property color textDim: "#8fb0ff"

    // ------------------------------------------------------------ state
    property int tab: 0                // 0 Home, 1 Library, 2 Store, 3 Settings
    property bool showDetails: false
    property var detailGame: null
    property int detailBtn: 0
    property int homeRow: 0            // 0 hero, 1 tiles, 2 recent
    property int homeCol: 0
    property int sideIndex: 0
    property int gridIndex: 0
    property bool libInSide: true
    property int setSide: 0
    property int setRow: 0
    property bool setInSide: true
    property string clock: ""

    property var allArr: []
    property var recent: []
    property var libGames: []
    property var featured: recent.length > 0 ? recent[0] : (allArr.length > 0 ? allArr[0] : null)
    property var tileGames: {
        var out = []
        for (var i = 0; i < allArr.length && out.length < 4; i++)
            if (allArr[i] !== featured) out.push(allArr[i])
        return out
    }

    readonly property var tabs: [
        { n: "Home", i: "\u2302" }, { n: "Library", i: "\u25A4" },
        { n: "Store", i: "\u25A3" }, { n: "Settings", i: "\u2699" } ]
    readonly property var cats: ["All Games", "Favorites", "Action", "Racing", "RPG", "Sports", "Adventure", "Indie"]
    readonly property var setSides: ["General", "Display", "Audio", "Controller", "Network", "About"]
    readonly property var setRows: [
        ["Language", "English"], ["Startup", "CN-PLAY (Fullscreen)"],
        ["Power Options", "Sleep after 30 min"], ["Exit to Desktop", "Confirm"] ]

    // ------------------------------------------------------------ data helpers
    function lp(g) {
        var t = g.lastPlayed ? g.lastPlayed.getTime() : 0
        return isNaN(t) ? 0 : t
    }
    function matches(g, i) {
        if (i === 0) return true
        if (i === 1) return g.favorite
        return (g.genre || "").toLowerCase().indexOf(cats[i].toLowerCase()) >= 0
    }
    function countFor(i) {
        var n = 0
        for (var k = 0; k < allArr.length; k++) if (matches(allArr[k], i)) n++
        return n
    }
    function updateLib() {
        var out = []
        for (var k = 0; k < allArr.length; k++) if (matches(allArr[k], sideIndex)) out.push(allArr[k])
        out.sort(function(a, b) { return a.title.localeCompare(b.title) })
        libGames = out
        if (gridIndex >= out.length) gridIndex = 0
    }
    function refresh() {
        allArr = api.allGames.toVarArray ? api.allGames.toVarArray() : []
        var r = allArr.slice()
        r.sort(function(a, b) { return lp(b) - lp(a) })
        recent = r.slice(0, 6)
        updateLib()
    }
    function openDetails(g) {
        if (!g) return
        detailGame = g; detailBtn = 0; showDetails = true
    }
    function homeGame() {
        if (homeRow === 0) return featured
        if (homeRow === 1) return tileGames[homeCol]
        return recent[homeCol]
    }
    function clampHomeCol() {
        var max = homeRow === 1 ? tileGames.length - 1 : (homeRow === 2 ? recent.length - 1 : 0)
        homeCol = Math.max(0, Math.min(homeCol, max))
    }
    Component.onCompleted: refresh()

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.clock = Qt.formatTime(new Date(), "hh:mm")
    }

    // ------------------------------------------------------------ input
    Keys.onPressed: {
        if (showDetails) { detailKeys(event); return }
        if (api.keys.isNextPage(event)) { event.accepted = true; tab = (tab + 1) % 4; return }
        if (api.keys.isPrevPage(event)) { event.accepted = true; tab = (tab + 3) % 4; return }
        if (tab === 0) homeKeys(event)
        else if (tab === 1) libKeys(event)
        else if (tab === 3) setKeys(event)
    }
    function homeKeys(e) {
        if (api.keys.isDetails(e)) { e.accepted = true; openDetails(homeGame()); return }
        if (api.keys.isAccept(e)) {
            e.accepted = true
            var g = homeGame()
            if (!g) return
            if (homeRow === 0) g.launch(); else openDetails(g)
            return
        }
        if (e.key === Qt.Key_Down)  { e.accepted = true; homeRow = Math.min(2, homeRow + 1); clampHomeCol() }
        else if (e.key === Qt.Key_Up)    { e.accepted = true; homeRow = Math.max(0, homeRow - 1); clampHomeCol() }
        else if (e.key === Qt.Key_Left)  { e.accepted = true; if (homeRow > 0) homeCol = Math.max(0, homeCol - 1) }
        else if (e.key === Qt.Key_Right) { e.accepted = true; if (homeRow > 0) { homeCol++; clampHomeCol() } }
    }
    function libKeys(e) {
        if (libInSide) {
            if (e.key === Qt.Key_Down) { e.accepted = true; sideIndex = Math.min(cats.length - 1, sideIndex + 1); updateLib() }
            else if (e.key === Qt.Key_Up) { e.accepted = true; sideIndex = Math.max(0, sideIndex - 1); updateLib() }
            else if (e.key === Qt.Key_Right || api.keys.isAccept(e)) { e.accepted = true; if (libGames.length > 0) libInSide = false }
            return
        }
        var n = libGames.length
        if (api.keys.isCancel(e)) { e.accepted = true; libInSide = true }
        else if (api.keys.isDetails(e)) { e.accepted = true; openDetails(libGames[gridIndex]) }
        else if (api.keys.isAccept(e)) { e.accepted = true; if (n > 0) libGames[gridIndex].launch() }
        else if (e.key === Qt.Key_Left)  { e.accepted = true; if (gridIndex % 4 === 0) libInSide = true; else gridIndex-- }
        else if (e.key === Qt.Key_Right) { e.accepted = true; gridIndex = Math.min(n - 1, gridIndex + 1) }
        else if (e.key === Qt.Key_Up)    { e.accepted = true; if (gridIndex >= 4) gridIndex -= 4 }
        else if (e.key === Qt.Key_Down)  { e.accepted = true; if (gridIndex + 4 < n) gridIndex += 4 }
    }
    function setKeys(e) {
        if (setInSide) {
            if (e.key === Qt.Key_Down) { e.accepted = true; setSide = Math.min(setSides.length - 1, setSide + 1) }
            else if (e.key === Qt.Key_Up) { e.accepted = true; setSide = Math.max(0, setSide - 1) }
            else if (e.key === Qt.Key_Right || api.keys.isAccept(e)) { e.accepted = true; if (setSide === 0) setInSide = false }
            return
        }
        if (e.key === Qt.Key_Down) { e.accepted = true; setRow = Math.min(3, setRow + 1) }
        else if (e.key === Qt.Key_Up) { e.accepted = true; setRow = Math.max(0, setRow - 1) }
        else if (e.key === Qt.Key_Left || api.keys.isCancel(e)) { e.accepted = true; setInSide = true }
        else if (api.keys.isAccept(e)) { e.accepted = true; if (setRow === 3) api.system.quit() }
    }
    function detailKeys(e) {
        if (api.keys.isCancel(e)) { e.accepted = true; showDetails = false }
        else if (e.key === Qt.Key_Down) { e.accepted = true; detailBtn = Math.min(2, detailBtn + 1) }
        else if (e.key === Qt.Key_Up) { e.accepted = true; detailBtn = Math.max(0, detailBtn - 1) }
        else if (api.keys.isAccept(e)) {
            e.accepted = true
            if (detailBtn === 0) detailGame.launch()
            else if (detailBtn === 1) { detailGame.favorite = !detailGame.favorite; updateLib() }
        }
    }

    // ------------------------------------------------------------ background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#06122b" }
            GradientStop { position: 1.0; color: "#02060f" }
        }
    }

    // ------------------------------------------------------------ 1920x1080 canvas scaled to any screen
    Item {
        id: canvas
        width: 1920; height: 1080
        property real s: Math.min(root.width / 1920, root.height / 1080)
        scale: s
        transformOrigin: Item.TopLeft
        x: (root.width - 1920 * s) / 2
        y: (root.height - 1080 * s) / 2

        // ===== header =====
        Row {
            x: 80; y: 26
            Text { text: "CN-"; color: root.accent; font.pixelSize: 64; font.bold: true; font.letterSpacing: 3 }
            Text { text: "PLAY"; color: "white"; font.pixelSize: 64; font.bold: true; font.letterSpacing: 3 }
        }
        Text {
            x: 84; y: 100; color: root.accentSoft; font.pixelSize: 15; font.letterSpacing: 4
            text: "YOUR GAMES  \u2022  YOUR CONSOLE"
        }
        Row {
            x: 520; y: 30; spacing: 14
            Repeater {
                model: root.tabs
                Rectangle {
                    width: 150; height: 86; radius: 12
                    color: index === root.tab ? "#0f3a99" : "transparent"
                    border.width: 2
                    border.color: index === root.tab ? root.accentSoft : "transparent"
                    Column {
                        anchors.centerIn: parent; spacing: 4
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.i
                               color: index === root.tab ? "white" : root.textDim; font.pixelSize: 30 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.n
                               color: index === root.tab ? "white" : root.textDim; font.pixelSize: 18 }
                    }
                }
            }
        }
        Row {
            anchors { right: parent.right; rightMargin: 80 }
            y: 50; spacing: 36
            Text { text: "\u2315"; color: "white"; font.pixelSize: 34 }
            Text { text: "\u224B"; color: "white"; font.pixelSize: 34 }
            Text { text: root.clock; color: "white"; font.pixelSize: 32 }
        }

        // ===== HOME =====
        Item {
            visible: root.tab === 0 && !root.showDetails
            anchors.fill: parent

            Rectangle {   // hero
                x: 80; y: 170; width: 920; height: 400; radius: 14
                color: "#0a1a3a"
                border.width: root.homeRow === 0 ? 4 : 2
                border.color: root.homeRow === 0 ? root.accentSoft : root.accent
                Image {
                    anchors { fill: parent; margins: 3 }
                    asynchronous: true; fillMode: Image.PreserveAspectCrop
                    source: root.featured ? (root.featured.assets.background || root.featured.assets.banner
                                             || (root.featured.assets.screenshots.length > 0 ? root.featured.assets.screenshots[0] : "")) : ""
                }
                Rectangle {
                    anchors { fill: parent; margins: 3 }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#e602060f" }
                        GradientStop { position: 0.7; color: "#33000000" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                Image {
                    x: 50; y: 40; height: 110; width: 420
                    fillMode: Image.PreserveAspectFit; horizontalAlignment: Image.AlignLeft
                    asynchronous: true
                    visible: source != ""
                    source: root.featured ? root.featured.assets.logo : ""
                }
                Text {
                    x: 50; y: 50; width: 520; wrapMode: Text.WordWrap
                    visible: root.featured && root.featured.assets.logo === ""
                    color: "white"; font.pixelSize: 54; font.bold: true
                    text: root.featured ? root.featured.title : "No games found"
                }
                Text {
                    x: 50; y: 210; width: 430; maximumLineCount: 2; elide: Text.ElideRight; wrapMode: Text.WordWrap
                    color: "white"; font.pixelSize: 20
                    text: root.featured ? root.featured.description : "Add games to Pegasus to see them here."
                }
                Rectangle {
                    x: 50; y: 300; width: 220; height: 64; radius: 8; color: root.accent
                    border.width: root.homeRow === 0 ? 3 : 0; border.color: "white"
                    Text { anchors.centerIn: parent; text: "\u25B6   Play"; color: "white"; font.pixelSize: 28; font.bold: true }
                }
            }

            Repeater {   // four tall tiles
                model: root.tileGames
                Cover {
                    x: 1032 + index * 206; y: 170; width: 190; height: 400
                    game: modelData
                    focused: root.homeRow === 1 && root.homeCol === index
                }
            }

            Text { x: 80; y: 610; text: "Recently Played"; color: "white"; font.pixelSize: 34; font.bold: true }
            Repeater {
                model: root.recent
                Cover {
                    x: 80 + index * 296; y: 670; width: 276; height: 190
                    mode: "banner"; game: modelData
                    focused: root.homeRow === 2 && root.homeCol === index
                }
            }
            Text {
                anchors { right: parent.right; rightMargin: 80 }
                y: 1010; color: root.accentSoft; font.pixelSize: 22
                text: "Play   \u2022   Explore   \u2022   Enjoy"
            }
        }

        // ===== LIBRARY =====
        Item {
            visible: root.tab === 1 && !root.showDetails
            anchors.fill: parent

            Rectangle {
                x: 80; y: 160; width: 300; height: 830; radius: 12
                color: root.panel; border.width: 2; border.color: root.line
                Repeater {
                    model: root.cats
                    Rectangle {
                        x: 12; y: 14 + index * 66; width: 276; height: 58; radius: 8
                        color: index === root.sideIndex ? root.accent : "transparent"
                        border.width: (index === root.sideIndex && root.libInSide) ? 3 : 0
                        border.color: "white"
                        Text { x: 18; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: "white"; font.pixelSize: 22 }
                        Text { anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                               text: root.countFor(index); color: root.textDim; font.pixelSize: 20 }
                    }
                }
                Rectangle {
                    x: 12; y: 760; width: 276; height: 56; radius: 8; color: "#0a1f47"
                    Text { x: 18; anchors.verticalCenter: parent.verticalCenter; text: "Sort: A-Z"; color: root.textDim; font.pixelSize: 20 }
                }
            }
            GridView {
                id: grid
                x: 420; y: 160; width: 1420; height: 830
                clip: true
                cellWidth: 355; cellHeight: 410
                model: root.libGames
                currentIndex: root.gridIndex
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                delegate: Item {
                    width: grid.cellWidth; height: grid.cellHeight
                    Cover {
                        x: 12; y: 12; width: 320; height: 340
                        game: modelData
                        focused: !root.libInSide && index === root.gridIndex
                    }
                    Text {
                        x: 12; y: 360; width: 320; elide: Text.ElideRight
                        color: "white"; font.pixelSize: 20; text: modelData.title
                    }
                }
            }
        }

        // ===== STORE (placeholder) =====
        Text {
            visible: root.tab === 2 && !root.showDetails
            anchors.centerIn: parent; color: root.textDim; font.pixelSize: 32
            text: "Store\nConnect Steam / Heroic / Lutris here"
            horizontalAlignment: Text.AlignHCenter
        }

        // ===== SETTINGS =====
        Item {
            visible: root.tab === 3 && !root.showDetails
            anchors.fill: parent

            Rectangle {
                x: 80; y: 160; width: 300; height: 830; radius: 12
                color: root.panel; border.width: 2; border.color: root.line
                Repeater {
                    model: root.setSides
                    Rectangle {
                        x: 12; y: 14 + index * 66; width: 276; height: 58; radius: 8
                        color: index === root.setSide ? root.accent : "transparent"
                        border.width: (index === root.setSide && root.setInSide) ? 3 : 0
                        border.color: "white"
                        Text { x: 18; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: "white"; font.pixelSize: 22 }
                    }
                }
            }
            Text { x: 430; y: 170; text: root.setSides[root.setSide] + " Settings"; color: "white"; font.pixelSize: 34; font.bold: true }
            Repeater {
                model: root.setSide === 0 ? root.setRows : []
                Rectangle {
                    x: 430; y: 240 + index * 90; width: 1400; height: 76; radius: 10
                    color: root.panel
                    border.width: (!root.setInSide && index === root.setRow) ? 3 : 1
                    border.color: (!root.setInSide && index === root.setRow) ? root.accentSoft : root.line
                    Text { x: 28; anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; color: "white"; font.pixelSize: 24 }
                    Text { anchors { right: parent.right; rightMargin: 60; verticalCenter: parent.verticalCenter }
                           text: modelData[1]; color: root.textDim; font.pixelSize: 22 }
                    Text { anchors { right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
                           text: "\u203A"; color: "white"; font.pixelSize: 30 }
                }
            }
            Rectangle {
                visible: root.setSide === 0
                x: 430; y: 640; width: 1400; height: 150; radius: 10
                color: root.panel; border.width: 1; border.color: root.line
                Column {
                    x: 28; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                    Text { text: "Console Info"; color: "white"; font.pixelSize: 24; font.bold: true }
                    Text { text: "CN-PLAY Software v0.2"; color: root.textDim; font.pixelSize: 20 }
                    Text { text: "Made for Gamers \u2665"; color: root.textDim; font.pixelSize: 20 }
                }
            }
            Text {
                visible: root.setSide !== 0
                x: 430; y: 250; color: root.textDim; font.pixelSize: 26
                text: "Coming soon"
            }
        }

        // ===== GAME DETAILS =====
        Rectangle {
            visible: root.showDetails && root.detailGame !== null
            anchors.fill: parent
            color: "#040b1d"

            Cover {
                x: 120; y: 170; width: 420; height: 600
                game: root.detailGame
            }
            Text { x: 600; y: 160; text: root.detailGame ? root.detailGame.title : ""; color: "white"; font.pixelSize: 56; font.bold: true }
            Text { x: 600; y: 235; text: root.detailGame ? root.detailGame.developer : ""; color: root.textDim; font.pixelSize: 24 }
            Text {
                x: 600; y: 278; color: "#ffc233"; font.pixelSize: 24
                text: root.detailGame && root.detailGame.rating > 0
                      ? "\u2605 " + (root.detailGame.rating * 5).toFixed(1) : ""
            }
            Row {
                x: 600; y: 330; spacing: 14
                Repeater {
                    model: root.detailGame ? (root.detailGame.genre || "").split(/[,\/]/).slice(0, 4) : []
                    Rectangle {
                        height: 40; width: chipText.width + 36; radius: 20
                        color: "#0a1f47"; border.width: 1; border.color: root.line
                        Text { id: chipText; anchors.centerIn: parent; text: modelData.trim(); color: "white"; font.pixelSize: 18 }
                    }
                }
            }
            Rectangle {
                x: 600; y: 400; width: 1000; height: 74; radius: 8; color: root.accent
                border.width: root.detailBtn === 0 ? 3 : 0; border.color: "white"
                Text { anchors.centerIn: parent; text: "\u25B6   Play"; color: "white"; font.pixelSize: 28; font.bold: true }
            }
            Rectangle {
                x: 600; y: 490; width: 490; height: 64; radius: 8; color: "#0a1f47"
                border.width: root.detailBtn === 1 ? 3 : 1
                border.color: root.detailBtn === 1 ? "white" : root.line
                Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 22
                       text: root.detailGame && root.detailGame.favorite ? "\u2665  Remove from Favorites" : "\u2661  Add to Favorites" }
            }
            Rectangle {
                x: 1110; y: 490; width: 490; height: 64; radius: 8; color: "#0a1f47"
                border.width: root.detailBtn === 2 ? 3 : 1
                border.color: root.detailBtn === 2 ? "white" : root.line
                Text { anchors.centerIn: parent; text: "\u22EF  More Options"; color: "white"; font.pixelSize: 22 }
            }
            Text {
                x: 600; y: 590; width: 1000; wrapMode: Text.WordWrap; maximumLineCount: 5; elide: Text.ElideRight
                color: root.textDim; font.pixelSize: 22
                text: root.detailGame ? root.detailGame.description : ""
            }
            Row {
                x: 600; y: 770; spacing: 20
                Repeater {
                    model: root.detailGame ? root.detailGame.assets.screenshots.slice(0, 3) : []
                    Rectangle {
                        width: 320; height: 180; radius: 8; color: "#0a1a3a"
                        Image { anchors { fill: parent; margins: 2 } source: modelData; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                    }
                }
            }
            Text { x: 120; y: 1010; color: root.textDim; font.pixelSize: 20; text: "B / Esc: back" }
        }
    }
}
