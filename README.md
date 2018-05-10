# Watson Visual Recognition and Core ML

Classify images offline with [Watson Visual Recognition][vizreq] and [Core ML][core_ml].

A deep neural network model is trained on the cloud by Watson Visual Recognition. The app then downloads the model which can be used offline by Core ML to classify images. Everytime the app is opened it checks if there are any updates to the model and downloads them if it can.

![App Screenshot][screenshot_iphone]

## Before you begin
Make sure you have these software versions installed on your machine. **These versions are required to support Core ML**:

- **MacOS 10.11 El Capitan** or later
- **iOS 11** or later (on your iPhone or iPad if you want the application to be on your device)
- **[Xcode 9][xcode_download]** or later
- **[Carthage 0.29][carthage_instructions]** or later

> **Carthage installation**
>
> If you don’t have Homebrew on your computer, it’s easier to setup Carthage with the `.pkg` installer. You can download it [here][carthage_download].

## Getting the files
Use GitHub to clone the repository locally, or download the .zip file of the repository and extract the files.

## Setting up Visual Recognition in Watson Studio
1. Log in to Watson Studio ([dataplatform.ibm.com][watson_studio_url]). From this link you can create an IBM Cloud account, sign up for Watson Studio, or log in.

## Training a custom model
https://watson-developer-cloud.github.io/watson-vision-coreml-code-pattern/lessons/creating-your-custom-classifier.html

## Finding your Model ID and API Key
1. Go back to the Visual Recognition dashboard, where you trained your model.
    ![][screenshot_w16]
    
1. Click the **Credentials** tab.
    ![][screenshot_w17]
    
1. Click **View Credentials**. We’ll need to copy the `api_key`.
    ![][screenshot_w18]
    
1. Navigate back to the Visual Recognition dashboard once again, scroll down to the section labeled **Custom Models**.
    ![][screenshot_w19]
    
1. Click **Copy model ID**.

## Installing the Watson Swift SDK
The Watson Swift SDK makes it easy to keep track of your custom Core ML models and to download your custom classifiers from IBM Cloud to your device.

Use the Carthage dependency manager to download and build the Watson Swift SDK.

1. Open a terminal window and navigate to this project's directory.
1. Run the following command to download and build the Watson Swift SDK:

    ```bash
    carthage bootstrap --platform iOS
    ```

## Running the app
The app uses the Visual Recognition service and Core ML model on your device to classify the image. Then the app sends the classification to Watson Discovery service and displays more information about the cable.

When you run the app, the SDK makes sure that the version of the Visual Recognition model on your device is in sync with the latest version on IBM Cloud. If the local version is older, the SDK downloads the model to your device. With a local model, you can classify images offline. You need to be connected to the internet to communicate with the Discovery service.

1. In Xcode, select the `Core ML Vision` scheme.
1. Run the app in the simulator or on a device.
1. Classify an image by clicking the camera icon and selecting a photo from your photo library or by taking a picture of a USB or HDMI connector. To add your own images in the simulator, drag the image from Finder to the simulator window.
1. Pull new versions of the visual recognition model with the refresh button in the upper right.

    If you're online, the application queries the Discovery service and displays information about the classification results in the bottom panel.

    **Tip:** The visual recognition classifier status must be `Ready` to use it. Check the classifier status in Watson Studio on the Visual Recognition instance overview page.

## What to do next

Try using your own data: Train a Visual Recognition classifier with your own images. For details on the Visual Recognition service, see the links in the Resources section.

## Resources

- [Visual Recognition docs](https://console.bluemix.net/docs/services/visual-recognition/getting-started.html)
- [Watson Swift SDK](https://github.com/watson-developer-cloud/swift-sdk)
- [Apple machine learning][core_ml] and [Core ML documentation](https://developer.apple.com/documentation/coreml)
- [Watson console](https://bluemix.net/developer/watson) on IBM Cloud

[watson_studio_url]: https://dataplatform.ibm.com
[carthage_download]: https://github.com/Carthage/Carthage/releases
[carthage_instructions]: https://github.com/Carthage/Carthage#installing-carthage
[vizreq]: https://www.ibm.com/watson/services/visual-recognition/
[core_ml]: https://developer.apple.com/machine-learning/
[vizreq_with_coreml]: https://github.com/watson-developer-cloud/visual-recognition-coreml/
[vizreq_tooling]: https://watson-visual-recognition.ng.bluemix.net/
[xcode_download]: https://developer.apple.com/xcode/downloads/

[camera_view_controller]:  /Core%20ML%20Vision/CameraViewController.swift
