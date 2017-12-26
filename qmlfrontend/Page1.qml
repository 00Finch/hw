import QtQuick 2.7
import Hedgewars.Engine 1.0

Page1Form {
  button1.onClicked: {
    console.log("Button clicked")
    HWEngine.getPreview()
  }

  Connections {
      target: HWEngine
      onPreviewImageChanged: {
          previewImage.source = "image://preview/image"
      }
      onPreviewIsRendering: {
        console.log("==========")
          previewImage.source = "qrc:/res/iconTime.png"
      }
      onPreviewHogCountChanged: {
      }
  }

}
