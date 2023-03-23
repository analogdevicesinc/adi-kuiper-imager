/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright (C) 2020 Raspberry Pi (Trading) Limited
 */

import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.0
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ApplicationWindow {
    id: window
    visible: true

    signal cleanupCache();

    width:  640
    height: 480
    minimumWidth: 480
    minimumHeight: 400
    title: qsTr("ADI Kuiper Imager v%1").arg(imageWriter.constantVersion())

    FontLoader {id: roboto;      source: "fonts/Roboto-Regular.ttf"}
    FontLoader {id: robotoLight; source: "fonts/Roboto-Light.ttf"}
    FontLoader {id: robotoBold;  source: "fonts/Roboto-Bold.ttf"}

    onClosing: {
        if (progressBar.visible) {
            close.accepted = false
            quitpopup.openPopup()
        }
    }

    Shortcut {
        sequence: StandardKey.Quit
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!progressBar.visible) {
                Qt.quit()
            }
        }
    }

    Shortcut {
        sequences: ["Shift+Ctrl+X", "Shift+Meta+X"]
        context: Qt.ApplicationShortcut
        onActivated: {
            if (progressBar.visible == false)
                optionspopup.openPopup()
        }
    }

    ColumnLayout {
        id: bg
        height: 480
        anchors.fill: parent
        anchors.bottomMargin: 0
        spacing: 0

        Rectangle {
            id: logo
            y: 0
            width: 640
            height: 160
            Layout.preferredHeight: 120
            clip: false
            Layout.fillHeight: false
            Layout.fillWidth: true
            implicitHeight: window.height/2

            Image {
                id: imgLogo
                anchors.fill: parent
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                source: "icons/Kuiper.svg"
                fillMode: Image.PreserveAspectFit
                sourceSize.height: 126
                sourceSize.width: 805
                clip: false
            }
        }

        Rectangle {
            id: controls
            y: 160
            height: 260
            color: "#e67e22"
            Layout.preferredWidth: -1
            Layout.preferredHeight: -1
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            clip: false
            implicitWidth: window.width
            implicitHeight: window.height/2

            states: [
                State {
                    name: "storage_not_ok"
                    PropertyChanges {
                        target: btnWrite;
                        enabled: false;
                    }
                    PropertyChanges {
                        target: btnOs;
                        state: "not_configured";
                    }
                    PropertyChanges {
                        target: btnTarget;
                        enabled: false;
                    }
                    PropertyChanges {
                        target: btnStorage;
                        state: "not_selected"
                    }
                },
                State {
                    name: "storage_ok"
                    PropertyChanges {
                        target: btnWrite;
                        enabled: true;
                    }
                    PropertyChanges {
                        target: btnOs;
                        state: "not_configured";
                    }
                    PropertyChanges {
                        target: btnTarget;
                        enabled: true;
                    }
                    PropertyChanges {
                        target: btnStorage;
                        state: "selected"
                    }
                }
            ]

            ColumnLayout {
                id: columnLayout
                y: 14
                width: 100
                height: 200
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.leftMargin: 10
                spacing: 0
                clip: false

                Button {
                    id: btnStorage
                    height: 40
                    Layout.rightMargin: 0
                    Layout.bottomMargin: 0
                    Layout.leftMargin: 0
                    Layout.topMargin: 0
                    spacing: 6
                    flat: false
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    transformOrigin: Item.Center
                    Layout.fillHeight: true
                    Layout.preferredHeight: -1
                    highlighted: true
                    Layout.fillWidth: true
                    clip: true

                    states : [
                        State {
                            name: "not_selected"
                            PropertyChanges {
                                target: btnStorage
                                text: qsTr("Storage (unconfigured)")
                                highlighted: true
                                enabled: true
                                Material.background: btnStorage.highlighted ? Material.Pink : "#2ecc71"
                            }
                        },
                        State {
                            name: "selected"
                            PropertyChanges {
                                target: btnStorage
                                highlighted: false
                                enabled: true
                                Material.background: btnStorage.highlighted ? Material.Pink : "#2ecc71"
                            }
                        }
                    ]
                    state: "not_selected"

                    ToolTip.delay: 300
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Select the destination storage that should be written or modified")

                    onClicked: {
                        storagePopup.open()
                        btnWrite.enabled = false
                    }

                }

                Button {
                    id: btnOs
                    height: 40
                    enabled: false
                    Layout.rightMargin: 0
                    Layout.bottomMargin: 0
                    Layout.leftMargin: 0
                    Layout.topMargin: 0
                    spacing: 6
                    flat: false
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    transformOrigin: Item.Center
                    clip: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: -1
                    Layout.fillWidth: true

                    states : [
                        State {
                            name: "not_configured"
                            PropertyChanges {
                                target: btnOs
                                text: qsTr("Image Source (unconfigured)")
                                highlighted: true
                                enabled: true
                                Material.background: btnOs.highlighted ? Material.Pink : "#2ecc71"
                            }
                        },
                        State {
                            name: "configured"
                            PropertyChanges {
                                target: btnOs
                                highlighted: true
                                enabled:true
                                Material.background: btnOs.highlighted ? Material.Pink : "#2ecc71"
                            }
                        },
                        State {
                            name: "configure_existing"
                            PropertyChanges {
                                target: btnOs
                                text: (checkKuiperVersion()) ? qsTr("CONFIGURE EXISTING CONTENT") :
                                       qsTr("CONFIGURE EXISTING CONTENT" +
                                            "\n Warning: JSON version is different. Some features may not work properly!")
                                highlighted: false
                                enabled: true
                                Material.background: btnOs.highlighted ? Material.Pink : "#2ecc71"
                            }
                        }
                    ]
                    state: "not_configured"

                    ToolTip.delay: 300
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Select the desired content that should be written on the storage above")

                    onClicked: {
                        ospopup.open()
                        osswipeview.currentItem.forceActiveFocus()
                        btnOs.text = ""
                        btnOs.state = "configured"
                        btnWrite.enabled = false
                    }
                }

                Button {
                    id: btnTarget
                    height: 40
                    text: qsTr("Target (unconfigured)")
                    enabled: true
                    Layout.rightMargin: 0
                    Layout.bottomMargin: 0
                    Layout.leftMargin: 0
                    Layout.topMargin: 0
                    spacing: 6
                    flat: false
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    transformOrigin: Item.Center
                    clip: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: -1
                    Layout.fillWidth: true
                    highlighted: btnTarget.text == qsTr("Target (unconfigured)") ? true : false
                    Material.background: btnTarget.highlighted ? Material.Pink : "#2ecc71"
                    visible: false

                    ToolTip.delay: 300
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Select the project that will be booted on the SD card")

                    onClicked: {
                        projectpopup.open()
                    }
                }
            }

            Button {
                id: btnWrite
                property string contentType;
                x: 532
                y: 272
                text: qsTr("WRITE")
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                enabled: false
                clip: false
                anchors.bottomMargin: 8
                anchors.rightMargin: 10
                Layout.rightMargin: 10
                Layout.bottomMargin: 10
                Layout.topMargin: 0
                Layout.minimumWidth: 0
                Layout.preferredWidth: -1
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                hoverEnabled: true

                ToolTip.delay: 300
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Start writing or configuring the SD card content")

                onClicked: {
                    imageWriter.enableDriveListTimer(false);
                    if (btnOs.state != "configure_existing") {
                        if (!imageWriter.readyToWrite()) {
                            return
                        }
                        confirmwritepopup.askForConfirmation()
                    } else {
                        progressText.visible = true
                        progressText.text = qsTr("Writing project on the BOOT partition")
                        msgpopup.title = qsTr("Image configuration")
                        if(imageWriter.selectProject())
                            msgpopup.text = "Configuration complete!"
                        else
                            msgpopup.text = "Configuration failed!"
                        msgpopup.openPopup()
                        resetbtnWrite()
                    }
                    btnTarget.enabled = false
                }
                Accessible.onPressAction: clicked()
            }

            Button {
                id: cancelbtnWrite
                x: 532
                y: 272
                text: qsTr("CANCEL WRITE")
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                enabled: false
                clip: false
                anchors.bottomMargin: 8
                anchors.rightMargin: 10
                font.family: roboto.name
                visible: false
                Material.background: "#ffffff"
                Material.foreground: "#c51a4a"
                Layout.rightMargin: 10
                Layout.bottomMargin: 10
                Layout.topMargin: 0
                Layout.minimumWidth: 0
                Layout.preferredWidth: -1
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                Accessible.onPressAction: clicked()
                onClicked: {
                    enabled = false
                    progressText.text = qsTr("Cancelling...")
                    imageWriter.cancelWrite()
                }
            }

            Button {
                x: 532
                y: 272
                id: cancelverifybutton
                text: qsTr("CANCEL VERIFY")
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                enabled: false
                clip: false
                anchors.bottomMargin: 8
                anchors.rightMargin: 10
                visible: false
                font.family: roboto.name
                Layout.rightMargin: 10
                Layout.bottomMargin: 10
                Layout.topMargin: 0
                Layout.minimumWidth: 0
                Layout.preferredWidth: -1
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                Material.background: "#ffffff"
                Material.foreground: "#c51a4a"
                Accessible.onPressAction: clicked()
                onClicked: {
                    enabled = false
                    progressText.text = qsTr("Finalizing...")
                    imageWriter.setVerifyEnabled(false)
                }
            }

            RowLayout {
                id: rowLayout
                y: 272
                height: 40
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 190
                anchors.leftMargin: 8
                anchors.bottomMargin: 8

                Text {
                    id: progressText
                    text: qsTr("")
                    font.pixelSize: 12
                    visible: false
                }

                ProgressBar {
                    id: progressBar
                    Layout.fillWidth: true
                    visible: false
                    value: 0.5
                }
            }
        }
    }

    Popup {
        id: storagePopup
        x:50
        y:25
        width: parent.width-100
        height: parent.height-50    
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: {
            if (sourceList.count == 0) {
                controls.state = "storage_not_ok";
            }
            imageWriter.stopDriveListPolling()
            imageWriter.enableDriveListTimer(true)
        }
        onOpened: {
            imageWriter.enableDriveListTimer(false)
            imageWriter.startDriveListPolling()
        }

        DropShadow {
            width: storagePopup.width
            height: storagePopup.height
            anchors.fill: storagePopupBody
            source: storagePopupBody
            horizontalOffset:0
            verticalOffset: 0
            radius: storagePopupBody.radius
            samples: 15
            color: "black"
        }

        Rectangle {
            id: storagePopupBody
            color: "#f0f0f0"
            anchors.fill: parent
            anchors.rightMargin: - radius
            anchors.leftMargin: - radius
            radius: 10
            Rectangle {
                id: storagePopupMargin
                color: "#aaa5a6"
                height: 35
                width: parent.width
                radius: parent.radius - 4
                anchors.topMargin: - radius
            }
            Rectangle {
                y: storagePopupMargin.height - height
                color: storagePopupMargin.color
                height: storagePopupMargin.height/2
                width: parent.width
            }

            Text {
                text: "X"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 15
                anchors.topMargin: 10
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        storagePopup.close()
                    }
                }
            }

        }

        ColumnLayout {
            spacing: 10

            Text {
                text: qsTr("Storage")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                Layout.topMargin: 10
                font.family: roboto.name
                font.bold: true
            }

            Item {
                clip: true
                Layout.preferredWidth: sourceList.width
                Layout.preferredHeight: sourceList.height

                SwipeView {
                    interactive: false

                    ListView {
                        id: sourceList
                        model: driveListModel
                        delegate: sourceDelegate
                        width: window.width-100
                        height: window.height-100
                        boundsBehavior: Flickable.StopAtBounds
                        property variant selectedItem: currentItem;

                        highlight:
                            Rectangle {
                            color: "lightsteelblue"
                            radius: 5
                        }
                        ScrollBar.vertical: ScrollBar {
                            width: 10
                            policy: sourceList.contentHeight > sourceList.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                        }
                        Keys.onSpacePressed: {
                            if (currentIndex == -1) {
                                return
                            }
                            selectedItem = currentItem
                            selectDstItem(currentItem)
                            btnTarget.text = qsTr("Target (unconfigured)")
                            btnOs.state = "not_configured"
                        }
                        Accessible.onPressAction: {
                            if (currentIndex == -1) {
                                return
                            }
                            selectedItem = currentItem
                            selectDstItem(currentItem)

                            btnTarget.text = qsTr("Target (unconfigured)")
                            btnOs.state = "not_configured"
                        }
                        Connections {
                            target: driveListModel;
                        }
                    }
                }
            }
        }

        Component {
            id: sourceDelegate

            Item {
                width: window.width - (sourceList.contentHeight > sourceList.height ? 120 : 80)
                height: 80
                Accessible.name: {
                    var txt = description+" - "+(size/1000000000).toFixed(1)+" gigabytes"
                    if (mountpoints.length > 0) {
                        txt += qsTr("Mounted as %1").arg(mountpoints.join(", "))
                    }
                    return txt;
                }
                property string description: model.description
                property string device: model.device
                property string size: model.size

                Rectangle {
                    id: rectBg
                    radius: 5
                    anchors.fill: parent
                    anchors.rightMargin: (sourceList.contentHeight > sourceList.height ? 0 : 30) - radius
                    anchors.topMargin: 8 - radius
                    anchors.bottomMargin: 8 - radius
                    color: "#bdc3c7"
                    opacity: 0.4
                    border {
                        color: "black"
                        width: 1
                    }

                }

                Rectangle {
                    id: rectSelected
                    anchors.fill: rectBg
                    radius: rectBg.radius
                    opacity: 0.4
                    color: "#f39c00"
                    visible: mouseOver && parent.ListView.view.currentIndex !== index
                    property bool mouseOver: false
                }

                Row {
                    anchors.fill: parent
                    width: rectBg.width - (sourceList.contentHeight > sourceList.height ? 0 : 30)
                    leftPadding: 20
                    rightPadding: 40

                    Column {
                        width: 64

                        Image {
                            source: isUsb ? "icons/ic_usb_40px.svg" : isScsi ? "icons/ic_storage_40px.svg" : "icons/ic_sd_storage_40px.svg"
                            verticalAlignment: Image.AlignVCenter
                            height: parent.parent.parent.height
                            fillMode: Image.Pad
                        }

                    }

                    Column {
                        width: parent.width-64

                        Text {
                            textFormat: Text.StyledText
                            height: parent.parent.parent.height
                            verticalAlignment: Text.AlignVCenter
                            font.family: roboto.name
                            width: rectBg.width - 64 - (sourceList.contentHeight > sourceList.height ? 0 : 30)
                            text: {
                                var sizeStr = (size/1000000000).toFixed(1)+" GB";
                                var txt;
                                if (isReadOnly) {
                                    txt = "<p><font size='4' color='grey'>"+description+" - "+sizeStr+"</font></p>"
                                    txt += "<font color='grey'>"
                                    if (mountpoints.length > 0) {
                                        txt += qsTr("Mounted as %1").arg(mountpoints.join(", "))+" "
                                    }
                                    txt += qsTr("[WRITE PROTECTED]")+"</font>"
                                } else {
                                    txt = "<p><font size='4'>"+description+" - "+sizeStr+"</font></p>"
                                    if (mountpoints.length > 0) {
                                        txt += "<font color='grey'>"+qsTr("Mounted as %1").arg(mountpoints.join(", "))+"</font>"
                                    }
                                }
                                return qsTr(txt);
                            }
                            wrapMode: Text.WordWrap
                        }
                    }
                }


                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: rectSelected.mouseOver = true

                    onExited: rectSelected.mouseOver = false

                    onClicked: {
                        sourceList.selectedItem = model;
                        selectDstItem(model)
                        btnTarget.text = qsTr("Target (unconfigured)")
                    }
                }
            }
        }
    }

    Popup {
        id: ospopup
        x:50
        y:25
        width: parent.width-100
        height: parent.height-50
        padding: 0
        property string categorySelected : ""
        onClosed: {
            if (btnOs.text === qsTr("")) {
                btnOs.state = "not_configured"
                btnTarget.visible = false
            }
            osswipeview.currentIndex = 0
        }

        DropShadow {
            width: ospopup.width
            height: ospopup.height
            anchors.fill: ospopupBody
            source: ospopupBody
            horizontalOffset:0
            verticalOffset: 0
            radius: ospopupBody.radius
            samples: 15
            color: "black"
        }

        Rectangle {
            id: ospopupBody
            color: "#f0f0f0"
            anchors.fill: parent
            anchors.rightMargin: - radius
            anchors.leftMargin: - radius
            radius: 10
            Rectangle {
                id: ospopupMargin
                color: "#aaa5a6"
                height: 35
                width: parent.width
                radius: parent.radius - 4
                anchors.topMargin: - radius
            }
            Rectangle {
                y: ospopupMargin.height - height
                color: ospopupMargin.color
                height: ospopupMargin.height/2
                width: parent.width
            }

            Text {
                text: "X"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 15
                anchors.topMargin: 10
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        btnOs.state = "not_configured"
                        ospopup.close()
                    }
                }
            }
        }

        ColumnLayout {
            spacing: 10

            Text {
                text: qsTr("Image source select")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                Layout.topMargin: 10
                font.family: roboto.name
                font.bold: true
            }

            Item {
                clip: true
                Layout.preferredWidth: sourceList.width
                Layout.preferredHeight: sourceList.height

                SwipeView {
                    id: osswipeview
                    interactive: false

                    ListView {
                        id: oslist
                        model: osmodel
                        currentIndex: -1
                        delegate: osdelegate
                        width: window.width-100
                        height: window.height-100
                        boundsBehavior: Flickable.StopAtBounds
                        highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                        ScrollBar.vertical: ScrollBar {
                            width: 10
                            policy: oslist.contentHeight > oslist.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                        }
                        Keys.onSpacePressed: {
                            if (currentIndex != -1) {
                                selectOSitem(model.get(currentIndex), true)
                            }
                        }
                        Accessible.onPressAction: {
                            if (currentIndex != -1) {
                                selectOSitem(model.get(currentIndex), true)
                            }
                        }
                    }
                }
            }
        }

        ListModel {
            id: osmodel

            ListElement {
                name: qsTr("Configure existing content")
                icon: "icons/select.png"
                subitems_url : "internal://configure_existing"
                description: qsTr("Switch between existing projects located in the BOOT partition")
            }

            ListElement {
                url: ""
                icon: "icons/use_custom.png"
                name: qsTr("Use custom")
                description: qsTr("Select a custom .img from your computer")
            }

            ListElement {
                url: "internal://format"
                icon: "icons/erase.png"
                extract_size: 0
                image_download_size: 0
                extract_sha256: ""
                contains_multiple_files: false
                skip_format: false
                release_date: ""
                subitems_url: ""
                project_list: ""
                subitems: []
                multiple_files: "no"
                name: qsTr("Erase")
                description: qsTr("Format card as FAT32")
                tooltip: ""
            }

            Component.onCompleted: {
                if (imageWriter.isOnline()) {
                    fetchOSlist();
                }
            }
        }

        Component {
            id: osdelegate

            Item {
                width: window.width - (oslist.contentHeight > oslist.height ? 120 : 80)
                height: image_download_size ? 100 : 80
                Accessible.name: name+".\n"+description

                Rectangle {
                    id: rectBg
                    radius: 5
                    anchors.fill: parent
                    anchors.rightMargin: (oslist.contentHeight > oslist.height ? 0 : 30) - radius
                    anchors.topMargin: 8 - radius
                    anchors.bottomMargin: 8 - radius
                    // color: "transparent"
                    color: "white"
                    // opacity: 0.4
                    border {
                        color: "black"
                        width: 1
                    }
                }

                Rectangle {
                    id: rectSelected
                    anchors.fill: rectBg
                    radius: rectBg.radius
                    opacity: 0.4
                    color: "#f39c00"
                    visible: mouseOver && parent.ListView.view.currentIndex !== index
                    property bool mouseOver: false
                }

                Row {
                    leftPadding: 25
                    topPadding: 5
                    bottomPadding: 5

                    Column {
                        Image {
                            source: icon == "icons/ic_build_48px.svg" ? "icons/cat_misc_utility_images.png" : icon
                            verticalAlignment: Image.AlignVCenter
                            horizontalAlignment: Image.AlignHCenter
                            height: parent.parent.parent.height-10
                            width: parent.parent.parent.height-10
                            fillMode: {
                                if (icon) {
                                    if (icon.includes("http"))
                                        return Image.Stretch
                                    else
                                        return Image.Pad
                                }
                            }
                        }

                        Text {
                            text: " "
                            visible: !icon
                        }
                    }

                    Column {
                        width: parent.parent.width-64-50-25-10
                        leftPadding: 10

                        Text {
                            verticalAlignment: Text.AlignVCenter
                            height: parent.parent.parent.height
                            font.family: roboto.name
                            textFormat: Text.RichText
                            width: rectBg.width - 64 - 50 - 10 - (oslist.contentHeight > oslist.height ? 0 : 30)
                            text: {
                                var txt = "<p style='margin-bottom: 5px;'><b>"+name+"</b></p>"
                                txt += "<font color='#1a1a1a'>"+description+"</font><font style='font-weight: 200' color='#646464'>"
                                if (typeof(release_date) == "string" && release_date)
                                    txt += "<br>"+qsTr("Released: %1").arg(release_date)
                                if (typeof(url) == "string" && url != "" && url != "internal://format"  && url != "internal://configure_existing") {
                                    if (typeof(extract_sha256) != "undefined" && imageWriter.isCached(url,extract_sha256)) {
                                        txt += "<br>"+qsTr("Cached on your computer")
                                    } else if (url.startsWith("file://")) {
                                        txt += "<br>"+qsTr("Local file")
                                    } else {
                                        txt += "<br>"+qsTr("Online - %1 GB download").arg((image_download_size/1073741824).toFixed(1));
                                    }
                                }
                                txt += "</font>";

                                return txt;
                            }
                            wrapMode: Text.WordWrap

                            Accessible.role: Accessible.ListItem
                            Accessible.name: name+".\n"+description
                            Accessible.focusable: true
                            Accessible.focused: parent.parent.parent.ListView.view.currentIndex === index

                            ToolTip {
                                visible: osMouseArea.containsMouse && typeof(tooltip) == "string" && tooltip !== ""
                                delay: 1000
                                text: typeof(tooltip) == "string" ? tooltip : ""
                                clip: false
                            }
                        }
                    }
                    Column {
                        Image {
                            source: "icons/ic_chevron_right_40px.svg"
                            visible: (typeof(subitems) == "object" && subitems.count) || (typeof(subitems_url) == "string" && subitems_url !== "" && subitems_url !== "internal://back" && subitems_url !== "internal://configure_existing")
                            verticalAlignment: Image.AlignVCenter
                            horizontalAlignment: Image.AlignHCenter
                            height: parent.parent.parent.height
                            fillMode: Image.Pad
                        }
                    }
                }


                MouseArea {
                    id: osMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: rectSelected.mouseOver = true

                    onExited: rectSelected.mouseOver = false

                    onClicked: {
                        selectOSitem(model)
                    }
                }
            }
        }

        Component {
            id: suboslist

            ListView {
                model: ListModel {
                    ListElement {
                        url: ""
                        icon: "icons/ic_chevron_left_40px.svg"
                        extract_size: 0
                        image_download_size: 0
                        extract_sha256: ""
                        contains_multiple_files: false
                        skip_format: false
                        release_date: ""
                        project_list: ""
                        subitems_url: "internal://back"
                        subitems: []
                        name: qsTr("Back")
                        description: qsTr("Go back to main menu")
                        tooltip: ""
                    }
                }

                currentIndex: -1
                delegate: osdelegate
                width: window.width-100
                height: window.height-100
                boundsBehavior: Flickable.StopAtBounds
                highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                ScrollBar.vertical: ScrollBar {
                    width: 10
                    policy: suboslist.contentHeight > suboslist.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                }
                Keys.onSpacePressed: {
                    if (currentIndex != -1) {
                        selectOSitem(model.get(currentIndex))
                    }
                }
                Accessible.onPressAction: {
                    if (currentIndex != -1) {
                        selectOSitem(model.get(currentIndex))
                    }
                }
            }
        }
    }

    Popup {
        id: projectpopup
        x: 50
        y: 25
        width: parent.width-100
        height: parent.height-50
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property string categorySelected : ""

        onClosed: {
            projswipeview.removeItem(projswipeview.itemAt(5))
            projswipeview.removeItem(projswipeview.itemAt(4))
            projswipeview.removeItem(projswipeview.itemAt(3))
            projswipeview.removeItem(projswipeview.itemAt(2))
            projswipeview.removeItem(projswipeview.itemAt(1))
            projswipeview.setCurrentIndex(0);
        }

        DropShadow {
            width: projectpopup.width
            height: projectpopup.height
            anchors.fill: projectpopupBody
            source: projectpopupBody
            horizontalOffset:0
            verticalOffset: 0
            radius: projectpopupBody.radius
            samples: 15
            color: "black"
        }

        Rectangle {
            id: projectpopupBody
            color: "#f0f0f0"
            anchors.fill: parent
            anchors.rightMargin: - radius
            anchors.leftMargin: - radius
            radius: 10
            Rectangle {
                id: projectpopupMargin
                color: "#aaa5a6"
                height: 35
                width: parent.width
                radius: parent.radius - 4
                anchors.topMargin: - radius
            }
            Rectangle {
                y: projectpopupMargin.height - height
                color: projectpopupMargin.color
                height: projectpopupMargin.height/2
                width: parent.width
            }

            Text {
                text: "X"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 15
                anchors.topMargin: 10
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        projectpopup.close()
                    }
                }
            }
        }

        ColumnLayout {
            spacing: 10

            Text {
                id: targetWindow
                text: qsTr("Project list")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                Layout.topMargin: 10
                font.family: roboto.name
                font.bold: true
            }

            Item {
                clip: true
                Layout.preferredWidth: oslist.width
                Layout.preferredHeight: oslist.height

                SwipeView {
                    id: projswipeview
                    interactive: false

                    ListView {
                        id: projlist
                        model: projmodel
                        currentIndex: -1
                        delegate: projdelegate
                        width: window.width-100
                        height: window.height-100
                        boundsBehavior: Flickable.StopAtBounds
                        highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                        ScrollBar.vertical: ScrollBar {
                            width: 10
                            policy: projlist.contentHeight > projlist.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                        }
                    }
                }
            }
        }

        Component {
            id: subprojlist

            ListView {
                model: ListModel {
                    ListElement {
                        icon: "icons/ic_chevron_left_40px.svg"
                        name: "BACK"
                        type: "BACK"
                        description: ""
                        platforms: []
                        architectures: []
                        boards: []
                        platform: ""
                        architecture: "BACK"
                        board: "BACK"
                        kernel: ""
                        preloader: ""
                        files: []
                        isReadme: false
                    }
                }

                currentIndex: -1
                delegate: projdelegate

                width: window.width-100
                height: window.height-100
                boundsBehavior: Flickable.StopAtBounds
                highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                ScrollBar.vertical: ScrollBar {
                    width: 10
                    policy: parent.contentHeight > parent.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                }
            }
        }

        ListModel {
            id: projmodel

            ListElement {
                icon: "icons/rpi.png"
                name: "rpi"
                description: "Raspberry PI"
                type: "platforms"
                platform: ""
                architecture: ""
                board: ""
                kernel: ""
                preloader: ""
                files: []
                isReadme: false
            }

            ListElement {
                icon: "icons/xilinx.png"
                name: "xilinx"
                description: "Xilinx"
                type: "platforms"
                isReadme: false
            }

            ListElement {
                icon: "icons/intel.png"
                name: "intel"
                description: "Intel"
                type: "platforms"
                isReadme: false
            }
        }

        Component {
            id: projdelegate

            Item {
                width: window.width-100
                height: 70

                Rectangle {
                    id: projbgrect
                    visible: !isReadme
                    radius: 5
                    anchors.fill: parent
                    anchors.rightMargin: 30
                    anchors.topMargin: 8 - radius
                    anchors.bottomMargin: 8 - radius
                    color: "transparent"
                    opacity: 0.4
                    border {
                        color: "black"
                        width: 1
                    }

                }

                Rectangle {
                    id: rectSelected
                    anchors.fill: projbgrect
                    radius: projbgrect.radius
                    opacity: 0.4
                    color: "#f39c00"
                    visible: !isReadme && (mouseOver && parent.ListView.view.currentIndex !== index)
                    property bool mouseOver: false
                }

                Row {
                    visible: true
                    leftPadding: 25
                    width: parent.width

                    Column {
                        visible: !isReadme
                        width: 64
                        topPadding: 5
                        bottomPadding: 5

                        Image {
                            source: icon ? icon : "icons/adi.png"
                            verticalAlignment: Image.AlignVCenter
                            horizontalAlignment: Image.AlignHCenter
                            height: parent.parent.parent.height-10
                        }
                    }

                    Column {
                        visible: !isReadme
                        width: parent.width
                        Text {
                            textFormat: Text.StyledText
                            height: parent.parent.parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            font.family: roboto.name
                            text: {
                                var txt ="<b>";
                                if (type == "architectures") {
                                    txt += architecture;
                                } else if (type == "boards") {
                                    txt += board;
                                } else {
                                    txt += name;
                                }
                                txt += "</b>";
                                return txt;
                            }
                        }
                    }

                    ColumnLayout {
                        visible: isReadme
                        width: parent.width
                        Text {
                            textFormat: Text.PlainText
                            font.family: roboto.name
                            padding: 10
                            Layout.fillWidth: true
                            Layout.preferredWidth: rectSelected.width
                            wrapMode: Text.WordWrap;
                            text: {
                                var txt = ""
                                if (type !== "boards" && type !== "architectures") {
                                    txt += name
                                }
                                return txt
                            }
                        }
                    }
                }

                MouseArea {
                    enabled: !isReadme
                    anchors.fill: parent
                    cursorShape: !isReadme ? Qt.PointingHandCursor : Qt.ArrowCursor
                    hoverEnabled: true

                    onEntered: {
                        rectSelected.mouseOver = true
                    }

                    onExited: {
                        rectSelected.mouseOver = false
                    }

                    onClicked: {
                        selectProj(model)
                    }
                }
            }
        }
    }

    Popup {
        id: writeActionPopup
        x: 75
        y: (parent.height-height)/2
        width: parent.width-150
        height: writeActionPopupbody.implicitHeight+150
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Rectangle {
            radius: 10
            color: "#f5f5f5"
            anchors.right: parent.right
            anchors.top: parent.top
            height: 35
            width: parent.width
            visible: false
        }

        Rectangle {
            color: "#afafaf"
            width: parent.width
            y: 35
            implicitHeight: 1
        }

        Text {
            text: "X"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 25
            anchors.topMargin: 10
            font.family: roboto.name
            font.bold: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    writeActionPopup.close()
                }
            }
        }

        ColumnLayout {
            spacing: 20
            anchors.fill: parent

            Text {
                id: writeActionPopupheader
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                Layout.topMargin: 10
                font.family: roboto.name
                font.bold: true
                text: "Warning"
            }

            Text {
                id: writeActionPopupbody
                font.pointSize: 12
                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                font.family: roboto.name
                Layout.maximumWidth: writeActionPopup.width-50
                Layout.fillHeight: true
                Layout.leftMargin: 25
                Layout.topMargin: 25
                text: qsTr("Storage: <b>%1</b> contains a Kuiper project list.<br> Do you want to configure the current content?").arg(btnStorage.text)
                Accessible.name: text.replace(/<\/?[^>]+(>|$)/g, "")
            }

            RowLayout {
                Layout.alignment: Qt.AlignCenter | Qt.AlignBottom
                Layout.bottomMargin: 10
                spacing: 20

                Button {
                    text: qsTr("No")
                    onClicked: {
                        writeActionPopup.close()
                    }
                    Material.foreground: "#ffffff"
                    Material.background: "#c51a4a"
                    font.family: roboto.name
                    visible: true
                    Accessible.onPressAction: clicked()
                }

                Button {
                    text: qsTr("Yes")
                    onClicked: {
                        writeActionPopup.close()
                        btnOs.state = "configure_existing"
                        imageWriter.setProjectListUrl("")
                        btnTarget.highlighted = true;
                        btnTarget.visible = true;
                        btnTarget.enabled = true;
                        ospopup.close();

                    }
                    Material.foreground: "#ffffff"
                    Material.background: "#c51a4a"
                    font.family: roboto.name
                    visible: true
                    Accessible.onPressAction: clicked()
                }
                Text { text: " " }
            }
        }
    }

    MsgPopup {
        id: msgpopup
    }

    MsgPopup {
        id: quitpopup
        continueButton: false
        yesButton: true
        noButton: true
        title: qsTr("Are you sure you want to quit?")
        text: qsTr("Kuiper Imager is still busy.<br>Are you sure you want to quit?")
        onYes: {
            Qt.quit()
        }
    }

    MsgPopup {
        id: confirmwritepopup
        continueButton: false
        yesButton: true
        noButton: true
        title: qsTr("Warning")
        onYes: {
            btnWrite.enabled = false
            btnWrite.visible = false
            cancelbtnWrite.enabled = true
            cancelbtnWrite.visible = true
            cancelverifybutton.enabled = true
            progressText.text = qsTr("Preparing to write...");
            progressText.visible = true
            progressBar.visible = true
            progressBar.indeterminate = true
            progressBar.Material.accent = "#ffffff"
            btnOs.enabled = false
            btnStorage.enabled = false
            imageWriter.setVerifyEnabled(true)
            imageWriter.startWrite()
        }

        function askForConfirmation()
        {
            text = qsTr("All existing data on '%1' will be erased.<br>Are you sure you want to continue?").arg(btnStorage.text)
            openPopup()
        }
    }

    MsgPopup {
        id: updatepopup
        continueButton: false
        yesButton: true
        noButton: true
        property url url
        title: qsTr("Update available")
        text: qsTr("There is a newer version of Imager available.<br>Would you like to visit the website to download it?")
        onYes: {
            Qt.openUrlExternally(url)
        }
    }

    OptionsPopup {
        id: optionspopup
    }

    UseSavedSettingsPopup {
        id: usesavedsettingspopup
        onYes: {
            optionspopup.initialize()
            optionspopup.applySettings()
            confirmwritepopup.askForConfirmation()
        }
        onNo: {
            imageWriter.clearSavedCustomizationSettings()
            confirmwritepopup.askForConfirmation()
        }
        onEditSettings: {
            optionspopup.openPopup()
        }
    }

    /* Utility functions */
    // TBD all things are added in the main menu instead of their separate menus
    function httpReplyReady(url, type, response) {
        console.log("Reply url: " + url);
        console.log("Reply type: " + type);
        //console.log("Reply response: " + response);
        if (response == "") {
            return;
        }
        var list = JSON.parse(response)
        switch (type) {
            case "oslist":
                var oslist = oslistFromJson(list)
                if (oslist === false){
                    return
                }

                for (var i in oslist) {
                    osmodel.insert(osmodel.count-3, oslist[i])
                }

                if ("imager" in list) {
                    var imager = list["imager"]
                    if ("latest_version" in imager && "url" in imager) {
                        if (!imageWriter.isEmbeddedMode() && imageWriter.isVersionNewer(imager["latest_version"])) {
                            updatepopup.url = imager["url"]
                            updatepopup.openPopup()
                        }
                    }
                }
                break;
            case "ositem":
                var m = newSublist()
                var oslist = oslistFromJson(list)
                if (oslist === false)
                    return
                for (var i in oslist) {
                    m.append(oslist[i])
                }
                break;
            case "platforms":
                var archlist;
                var platformlist = list.platforms
                for (var i in platformlist) {
                    if (platformlist[i].platform == selectedProjectItem.name){
                        archlist = platformlist[i]["architectures"]
                    }
                }
                var newlist = subprojlist.createObject(projswipeview)
                projswipeview.addItem(newlist)
                var sublist = projswipeview.itemAt(projswipeview.currentIndex + 1).model
                for (var i in archlist){
                    archlist[i].type = "architectures"
                    sublist.append(archlist[i])
                }
                imageWriter.setProjectSearch(item.name,0)
                projswipeview.incrementCurrentIndex()
                break;
            case "projects":
                var newlist = subprojlist.createObject(projswipeview)
                projswipeview.addItem(newlist)
                var sublist = projswipeview.itemAt(projswipeview.currentIndex + 1).model
                var projlist = list.projects
                for (var i in projlist) {
                    if (projlist[i].platform == imageWriter.getProjectSearch(0) &&
                        projlist[i].architecture == imageWriter.getProjectSearch(1) &&
                        projlist[i].board == imageWriter.getProjectSearch(2)){
                        projlist[i].type = "project";
                        sublist.append(projlist[i])
                    }
                }
                break;
            default:
                break;
        }
    }

    function httpRequest(url, requestType) {
        console.log("[SENDING] httpRequest for" + requestType)
        networkRequestManager.getRequest(url, requestType);
    }

    /* Slots for signals imagewrite emits */
    function onDownloadProgress(now,total) {
        var newPos
        if (total) {
            newPos = now/(total+1)
        } else {
            newPos = 0
        }
        if (progressBar.value !== newPos) {
            if (progressText.text === qsTr("Cancelling..."))
                return

            progressText.text = qsTr("Writing... %1%").arg(Math.floor(newPos*100))
            progressBar.indeterminate = false
            progressBar.value = newPos
        }
    }

    function onVerifyProgress(now,total) {
        var newPos
        if (total) {
            newPos = now/total
        } else {
            newPos = 0
        }

        if (progressBar.value !== newPos) {
            if (cancelbtnWrite.visible) {
                cancelbtnWrite.visible = false
                cancelverifybutton.visible = true
            }

            if (progressText.text === qsTr("Finalizing..."))
                return

            progressText.text = qsTr("Verifying... %1%").arg(Math.floor(newPos*100))
            progressBar.Material.accent = "#6cc04a"
            progressBar.value = newPos
        }
    }

    function onPreparationStatusUpdate(msg) {
        progressText.text = qsTr("Preparing to write... (%1)").arg(msg)
    }

    function resetbtnWrite() {
        imageWriter.setDst("")
        btnTarget.highlighted = true
        btnTarget.text = "TARGET (UNCONFIGURED)"
        btnTarget.visible = false
        progressBar.visible = false
        progressText.visible = false
        progressText.text = qsTr("")
        btnWrite.visible = true
        btnWrite.enabled = imageWriter.readyToWrite()
        cancelbtnWrite.visible = false
        cancelverifybutton.visible = false
        controls.state = "storage_not_ok"
        btnOs.state = "not_configured"
    }

    function onError(msg) {
        msgpopup.title = qsTr("Error")
        msgpopup.text = msg
        msgpopup.openPopup()
        resetbtnWrite()
        storagePopup.close()
        ospopup.close()
        projectpopup.close()
    }

    function onSuccess() {
        msgpopup.title = qsTr("Write Successful")
        if (btnOs.text === qsTr("Erase")) {
            msgpopup.text = qsTr("<b>%1</b> has been erased<br><br>You can now remove the SD card from the reader").arg(btnStorage.text)
            resetbtnWrite()
        } else {
            msgpopup.text = qsTr("<b>%1</b> has been written to <b>%2</b>").arg(btnOs.text).arg(btnStorage.text)
            if (btnOs.text.toLowerCase().includes("kuiper")) {
                progressText.visible = false
                progressText.text = qsTr("")
                btnWrite.enabled = imageWriter.readyToWrite()
                cancelverifybutton.visible = false
                progressBar.visible = false
                cancelbtnWrite.visible = false
                resetbtnWrite()
            } else {
                resetbtnWrite()
            }
        }
        if (imageWriter.isEmbeddedMode()) {
            msgpopup.continueButton = false
            msgpopup.quitButton = true
        }
        btnWrite.visible = true
        btnTarget.enabled = true
        controls.state = "storage_not_ok"
        btnOs.state = "not_configured"
        msgpopup.openPopup()
    }

    function onFileSelected(file) {
        imageWriter.setSrc(file)
        btnOs.text = imageWriter.srcFileName()
        ospopup.close()
        if (imageWriter.readyToWrite()) {
            btnOs.highlighted = false
            btnWrite.enabled = true
        }
    }

    function onCancelled() {
        resetbtnWrite()
    }

    function onFinalizing() {
        progressText.text = qsTr("Finalizing...")
    }

    function oslistFromJson(o) {
        var lang_country = Qt.locale().name
        if ("os_list_"+lang_country in o) {
            return o["os_list_"+lang_country]
        }
        if (lang_country.includes("_")) {
            var lang = lang_country.substr(0, lang_country.indexOf("_"))
            if ("os_list_"+lang in o) {
                return o["os_list_"+lang]
            }
        }

        if (!"os_list" in o) {
            onError(qsTr("Error parsing os_list.json"))
            return false
        }

        return o["os_list"]
    }

    function fetchOSlist() {
        httpRequest(imageWriter.constantOsListUrl(), "oslist")
        console.log("[SENT] httpRequest for oslist")
    }

    function driveListUpdate() {
        imageWriter.startDriveListPolling()
        var d = sourceList.selectedItem
        if ((d && !d.isReadOnly) || !d) {
            selectDstItem(d)
        }

        imageWriter.stopDriveListPolling()
    }

    function newSublist() {
        if (osswipeview.currentIndex == (osswipeview.count-1))
        {
            var newlist = suboslist.createObject(osswipeview)
            osswipeview.addItem(newlist)
        }

        var m = osswipeview.itemAt(osswipeview.currentIndex+1).model

        if (m.count>1)
        {
            m.remove(1, m.count-1)
        }

        return m
    }

    function selectOSitem(d, selectFirstSubitem) {
        var url = d.project_list
        btnTarget.visible = false
        if (typeof(d.subitems) == "object" && d.subitems.count) {
            var m = newSublist()

            for (var i=0; i<d.subitems.count; i++)
            {
                m.append(d.subitems.get(i))
            }

            osswipeview.itemAt(osswipeview.currentIndex+1).currentIndex = (selectFirstSubitem === true) ? 0 : -1
            osswipeview.incrementCurrentIndex()
            ospopup.categorySelected = d.name
        } else if (typeof(d.subitems_url) == "string" && d.subitems_url !== "") {
            if (d.subitems_url === "internal://back")
            {
                osswipeview.decrementCurrentIndex()
                ospopup.categorySelected = ""
                btnOs.text = ""
            }
            else if (d.subitems_url === "internal://configure_existing")
            {
                btnOs.state = "configure_existing"
                btnTarget.text = qsTr("TARGET (UNCONFIGURED)")
                btnTarget.highlighted = true
                btnTarget.visible = true
                btnTarget.enabled = true
                ospopup.close()
            }
            else
            {
                ospopup.categorySelected = d.name
                var suburl = d.subitems_url

                httpRequest(suburl, "ositem")
                console.log("[SENT] httpRequest for ositem")

                osswipeview.itemAt(osswipeview.currentIndex+1).currentIndex = (selectFirstSubitem === true) ? 0 : -1
                osswipeview.incrementCurrentIndex()
                btnOs.text += d.name + " : "
            }
        } else if (d.url === "") {
            if (!imageWriter.isEmbeddedMode()) {
                imageWriter.openFileDialog()
            }
            else {
                if (imageWriter.mountUsbSourceMedia()) {
                    var m = newSublist()

                    var oslist = JSON.parse(imageWriter.getUsbSourceOSlist())
                    for (var i in oslist) {
                        m.append(oslist[i])
                    }
                    osswipeview.itemAt(osswipeview.currentIndex+1).currentIndex = (selectFirstSubitem === true) ? 0 : -1
                    osswipeview.incrementCurrentIndex()
                }
                else
                {
                    onError(qsTr("Connect an USB stick containing images first.<br>The images must be located in the root folder of the USB stick."))
                }
            }
        } else {
            imageWriter.setSrc(d.url, d.image_download_size, d.extract_size, typeof(d.extract_sha256) != "undefined" ? d.extract_sha256 : "", typeof(d.contains_multiple_files) != "undefined" ? d.contains_multiple_files : false, typeof(d.skip_format) != "undefined" ? d.skip_format : false, ospopup.categorySelected, d.name)
            btnOs.text += d.name
            ospopup.close()
            if (typeof(d.project_list) != "undefined") {
                imageWriter.setProjectListUrl(d.project_list)
                btnTarget.text = qsTr("TARGET (UNCONFIGURED)")
                btnTarget.highlighted = true
                if (d.url != qsTr("internal://format"))
                    btnTarget.visible = true
            }
            if (imageWriter.readyToWrite()) {
                btnOs.highlighted = false
            }
            if (btnOs.state != "configure_existing" && btnStorage.state == "selected") {
                btnWrite.enabled = true
            }
        }
    }

    function selectDstItem(d) {
        if (storagePopup.opened) {
            storagePopup.close()
        }
        if (!d) {
            imageWriter.setDst("")
            controls.state = "storage_not_ok";
            return;
        }

        if (d.isReadOnly) {
            imageWriter.setDst("")
            controls.state = "storage_not_ok";
            onError(qsTr("SD card is write protected.<br>Push the lock switch on the left side of the card upwards, and try again."))
            return;
        }

        var success = imageWriter.setDst(d.device, d.size, d.mountpoints)
        if (success) {
            btnOs.state = "not_configured"
            btnTarget.text = qsTr("Target (UNCONFIGURED)")
            btnTarget.visible = false
            btnStorage.state = "selected"
            btnStorage.text = d.description
            controls.state ="storage_ok";
            if (imageWriter.hasKuiper())
                writeActionPopup.open()
        }
    }

    function checkKuiperVersion() {
        if (btnOs.state == "configure_existing") {
            return imageWriter.compareKuiperJsonVersions()
        }
        return true;
    }

    function selectProj(item) {
        switch (item.type) {
            case "platforms":
                var archlist
                var listurl = imageWriter.getProjectListUrl()
                if (listurl != "") {
                    selectedProjectItem = item;
                    httpRequest(listurl, "platforms")
                    console.log("[SENT] httpRequest for platforms")
                } else if (imageWriter.hasKuiper()) {
                    archlist = JSON.parse(imageWriter.getPlatformList(item.name))
                    var newlist = subprojlist.createObject(projswipeview)
                    projswipeview.addItem(newlist)
                    var sublist = projswipeview.itemAt(projswipeview.currentIndex + 1).model
                    for (var i in archlist){
                        archlist[i].type = "architectures"
                        sublist.append(archlist[i])
                    }
                    imageWriter.setProjectSearch(item.name,0)
                    projswipeview.incrementCurrentIndex()
                } else {
                    onError("Can't configure selected platform. 
                    \nJSON file not found on BOOT partition.\n
                    JSON file not found online.")
                }

                btnTarget.text = item.name + ": "

                break;
            case "architectures":
                var newlist = subprojlist.createObject(projswipeview)
                projswipeview.addItem(newlist)
                var sublist = projswipeview.itemAt(projswipeview.currentIndex + 1).model
                for (i = 0; i < item.boards.count; i++) {
                    var it = JSON.parse(JSON.stringify(item.boards.get(i)));
                    it.type = "boards"
                    sublist.append(it)
                }
                imageWriter.setProjectSearch(item.architecture,1)
                btnTarget.text += item.architecture + ": "
                projswipeview.incrementCurrentIndex()
                break;

            case "project":
                var filelist = "";
                for (i = 0; i < item.files.count; i++) {
                    filelist+=item.files.get(i).path
                    if (i != item.files.count - 1)
                        filelist+='%'
                }
                btnWrite.enabled = true
                btnTarget.text += item.name
                btnTarget.highlighted  = false
                imageWriter.setProjectFiles(item.kernel, item.preloader, filelist)
                projswipeview.removeItem(projswipeview.itemAt(5))
                projswipeview.removeItem(projswipeview.itemAt(4))
                projswipeview.removeItem(projswipeview.itemAt(3))
                projswipeview.removeItem(projswipeview.itemAt(2))
                projswipeview.removeItem(projswipeview.itemAt(1))
                projectpopup.close()
                break

            case "BACK":
                var model = projswipeview.itemAt(projswipeview.currentIndex).model
                model.remove(1, model.count-1)
                projswipeview.decrementCurrentIndex()

                break

            default:
                imageWriter.setProjectSearch(item.board,2)
                item.type = "boards";

                listurl = imageWriter.getProjectListUrl()
                if (listurl != "") {
                    console.log("listurl:" + listurl + "test")
                    httpRequest(listurl, "projects")
                    console.log("[SENT] httpRequest for projects")
                } else if (imageWriter.hasKuiper()) {
                    var newlist = subprojlist.createObject(projswipeview)
                    projswipeview.addItem(newlist)
                    var sublist = projswipeview.itemAt(projswipeview.currentIndex + 1).model
                    var projlist = JSON.parse(imageWriter.getProjectList())
                    for (var i in projlist) {
                        projlist[i].type = "project";
                        sublist.append(projlist[i])

                    }
                } else {
                        onError("Can't configure list of supported projects. 
                    \nJSON file not found on BOOT partition.\n
                    JSON file not found online.")
                }
                btnTarget.text += item.board + ": "
                var strFindIdx = item.board.indexOf("rpi")
                if (strFindIdx === 0) {
                    newlist = subprojlist.createObject(projswipeview)
                    projswipeview.addItem(newlist)
                    sublist = projswipeview.itemAt(projswipeview.currentIndex + 1).model
                    var readme = {"name": KUIPER_RPI_README, "type": "BACK", "isReadme": true}
                    sublist.append(readme);
                }
                projswipeview.incrementCurrentIndex()
                break;
        }
    }
}

/*##^##
Designer {
    D{i:0;formeditorZoom:1.1;height:440;width:640}
}
##^##*/
