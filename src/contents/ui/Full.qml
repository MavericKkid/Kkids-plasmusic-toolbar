import "./components"
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import Qt5Compat.GraphicalEffects


Item {
    id: root
    
    property string albumPlaceholder: plasmoid.configuration.albumPlaceholder
    property string desktopBackground: plasmoid.configuration.desktopWidgetBg
    property real volumeStep: plasmoid.configuration.volumeStep
    property bool albumCoverBackground: plasmoid.configuration.fullAlbumCoverAsBackground
    property int roundedCornerRadius: plasmoid.configuration.radiusSpinbox

    Layout.preferredHeight: column.implicitHeight
    Layout.preferredWidth: column.implicitWidth
    Layout.minimumWidth: column.implicitWidth
    Layout.minimumHeight: column.implicitHeight


    readonly property color foregroundColor: albumCoverBackground ? imageColors.contrastColor : Kirigami.Theme.textColor
    readonly property color highlightColor: albumCoverBackground ? imageColors.hlColor : Kirigami.Theme.highlightColor

    Item {
        visible: albumCoverBackground
        Layout.margins: 0
        anchors.centerIn: parent
        height: column.height
        width: column.width


        Rectangle {
            id: mask
            topLeftRadius : desktopBackground != PlasmaCore.Types.StandardBackground ? roundedCornerRadius : 0
            topRightRadius: desktopBackground != PlasmaCore.Types.StandardBackground ? roundedCornerRadius : 0
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height * 0.7
            width: parent.width

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    x: mask.x; y: mask.y
                    width: mask.width
                    height: mask.height
                    topLeftRadius : mask.topLeftRadius
                    topRightRadius: mask.topRightRadius
                }
            }

            ImageWithPlaceholder {
                id: albumArtFull
                opacity: 1
                smooth: false
                anchors.fill: parent
                placeholderSource: albumPlaceholder
                fillMode: Image.PreserveAspectCrop
                imageSource: player.artUrl

                onStatusChanged: {
                    if (status === Image.Ready) {
                        imageColors.update()
                    }
                }

                Kirigami.ImageColors {
                    id: imageColors
                    source: albumArtFull


                    readonly property color realbgColor: average

                    readonly property real startval: 0.7
                    readonly property real endval: 0.85
                    readonly property real startsat: 0.1
                    readonly property real endsat: 0.7

                    // create linear equation y=ax+b.
                    // have no changes to value/saturation until startsat/-val
                    // and then scale linearly with endpoint at x=1 y=endval/-sat

                    readonly property real aval: (startval - endval)/(startval - 1)
                    readonly property real bval:  startval* (endval -1)/(startval-1)
                    readonly property real asat: (startsat - endsat)/(startsat - 1)
                    readonly property real bsat:  startsat* (endsat -1)/(startsat-1)

                    readonly property color newVal: Qt.hsva(realbgColor.hsvHue,realbgColor.hsvSaturation,(realbgColor.hsvValue*aval+bval),1)
                    readonly property color bgColor: realbgColor.hsvValue>startval ? newVal : realbgColor
                    readonly property color contrastColor: Kirigami.ColorUtils.brightnessForColor(bgColor) === Kirigami.ColorUtils.Dark ? "white" : "black"
                    readonly property real hsvSat: realbgColor.hsvValue>startval ? asat*realbgColor.hsvSaturation+bsat : realbgColor.hsvSaturation
                    readonly property color hlColor: bgColor.hsvSaturation<startsat ? Qt.hsva(bgColor.hsvHue ,0.1,1,1) : Qt.hsva(bgColor.hsvHue,hsvSat,1,1)
                }
            }
        }

        Rectangle {
            id: bottomRect
            anchors.fill: parent
            radius: desktopBackground != PlasmaCore.Types.StandardBackground ? roundedCornerRadius : 0
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.4; color: "transparent" }
                GradientStop { position: 0.7; color: imageColors.bgColor }
                GradientStop { position: 1; color: imageColors.bgColor }
            }
        }
    }


    ColumnLayout {
        id: column

        spacing: 0
        anchors.fill: parent

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: 10
            width: 300
            height: width
            color: 'transparent'

            PlasmaComponents3.ToolTip {
                id: raisePlayerTooltip
                anchors.centerIn: parent
                text: player.canRaise ? i18n("Bring player to the front") : i18n("This player can't be raised")
                visible: coverMouseArea.containsMouse
            }

            MouseArea {
                id: coverMouseArea
                anchors.fill: parent
                cursorShape: player.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (player.canRaise) player.raise()
                }
                hoverEnabled: true
            }

            ImageWithPlaceholder {
                visible: !albumCoverBackground
                id: albumArtNormal
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit

                placeholderSource: albumPlaceholder
                imageSource: player.artUrl
            }
        }

        TrackPositionSlider {
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            textColor:  root.foregroundColor
            highlightColor: root.highlightColor
            songPosition: player.songPosition
            songLength: player.songLength
            playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
            enableChangePosition: player.canSeek
            onRequireChangePosition: (position) => {
                player.setPosition(position)
            }
            onRequireUpdatePosition: () => {
                player.updatePosition()
            }
        }

        SongAndArtistText {
            Layout.alignment: Qt.AlignHCenter
            scrollingSpeed: plasmoid.configuration.fullViewTextScrollingSpeed
            title: player.title
            artists: player.artists
            album: player.album
            textFont: baseFont
            color: root.foregroundColor
            maxWidth: 250
            titlePosition: plasmoid.configuration.fullTitlePosition
            artistsPosition: plasmoid.configuration.fullArtistsPosition
            albumPosition: plasmoid.configuration.fullAlbumPosition
        }

        VolumeBar {
            Layout.leftMargin: 40
            Layout.rightMargin: 40
            Layout.topMargin: 10
            textColor:  root.foregroundColor
            highlightColor: root.highlightColor
            volume: player.volume
            onSetVolume: (vol) => {
                player.setVolume(vol)
            }
            onVolumeUp: {
                player.changeVolume(volumeStep / 100, false)
            }
            onVolumeDown: {
                player.changeVolume(-volumeStep / 100, false)
            }
        }

        Item {
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.bottomMargin: 10
            Layout.fillWidth: true
            Layout.preferredHeight: row.implicitHeight
            RowLayout {
                id: row

                anchors.fill: parent

                CommandIcon {
                    enabled: player.canChangeShuffle
                    textColor:  root.foregroundColor
                    highlightColor: root.highlightColor
                    Layout.alignment: Qt.AlignHCenter
                    size: Kirigami.Units.iconSizes.medium
                    source: "media-playlist-shuffle"
                    onClicked: player.setShuffle(player.shuffle === Mpris.ShuffleStatus.Off ? Mpris.ShuffleStatus.On : Mpris.ShuffleStatus.Off)
                    active: player.shuffle === Mpris.ShuffleStatus.On
                }

                CommandIcon {
                    enabled: player.canGoPrevious
                    textColor:  root.foregroundColor
                    highlightColor: root.highlightColor
                    Layout.alignment: Qt.AlignHCenter
                    size: Kirigami.Units.iconSizes.medium
                    source: "media-skip-backward"
                    onClicked: player.previous()
                }

                CommandIcon {
                    enabled: player.playbackStatus === Mpris.PlaybackStatus.Playing ? player.canPause : player.canPlay
                    textColor:  root.foregroundColor
                    highlightColor: root.highlightColor
                    Layout.alignment: Qt.AlignHCenter
                    size: Kirigami.Units.iconSizes.large
                    source: player.playbackStatus === Mpris.PlaybackStatus.Playing ? "media-playback-pause" : "media-playback-start"
                    onClicked: player.playPause()
                }

                CommandIcon {
                    enabled: player.canGoNext
                    textColor:  root.foregroundColor
                    highlightColor: root.highlightColor
                    Layout.alignment: Qt.AlignHCenter
                    size: Kirigami.Units.iconSizes.medium
                    source: "media-skip-forward"
                    onClicked: player.next()
                }

                CommandIcon {
                    enabled: player.canChangeLoopStatus
                    textColor:  root.foregroundColor
                    highlightColor: root.highlightColor
                    Layout.alignment: Qt.AlignHCenter
                    size: Kirigami.Units.iconSizes.medium
                    source: player.loopStatus === Mpris.LoopStatus.Track ? "media-playlist-repeat-song" : "media-playlist-repeat"
                    active: player.loopStatus != Mpris.LoopStatus.None
                    onClicked: () => {
                        let status = Mpris.LoopStatus.None;
                        if (player.loopStatus == Mpris.LoopStatus.None)
                            status = Mpris.LoopStatus.Track;
                        else if (player.loopStatus === Mpris.LoopStatus.Track)
                            status = Mpris.LoopStatus.Playlist;
                        player.setLoopStatus(status);
                    }
                }

            }

        }

    }
}