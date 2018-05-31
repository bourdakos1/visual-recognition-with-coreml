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
For an in depth walkthrough of creating a custom model, check out the [Core ML & Watson Visual Recognition Code Pattern][code_pattern].

## Installing the Watson Swift SDK
The Watson Swift SDK makes it easy to keep track of your custom Core ML models and to download your custom classifiers from IBM Cloud to your device.

Use the Carthage dependency manager to download and build the Watson Swift SDK.

1. Open a terminal window and navigate to this project's directory.
1. Run the following command to download and build the Watson Swift SDK:

    ```bash
    carthage update --platform iOS
    ```

## Configure your app
1. Open the project in XCode.
1. Copy the **Model ID** of the model you trained and paste it into the `modelId` property in the [`CameraViewController.swift`][camera_view_controller] file.
1. Copy your **"apikey"** from your Visual Recognition service credentials and paste it into the `apiKey` property in the [`Credentials.plist`][credentials_plist] file.

## Running the app
1. In Xcode, select the `Core ML Vision` scheme.
1. You can run the app in the simulator or on your device.
> **Note:** The visual recognition classifier status must be **Ready** to use it. Check the classifier status in Watson Studio on the Visual Recognition instance overview page.

## What to do next

Try using your own data: Train a Visual Recognition classifier with your own images. For details on the Visual Recognition service, see the links in the Resources section.

## Resources

- [Visual Recognition docs](https://console.bluemix.net/docs/services/visual-recognition/getting-started.html)
- [Watson Swift SDK](https://github.com/watson-developer-cloud/swift-sdk)
- [Apple machine learning][core_ml] and [Core ML documentation](https://developer.apple.com/documentation/coreml)
- [Watson console](https://bluemix.net/developer/watson) on IBM Cloud

[code_pattern]: https://watson-developer-cloud.github.io/watson-vision-coreml-code-pattern/
[watson_studio_url]: https://dataplatform.ibm.com
[carthage_download]: https://github.com/Carthage/Carthage/releases
[carthage_instructions]: https://github.com/Carthage/Carthage#installing-carthage
[vizreq]: https://www.ibm.com/watson/services/visual-recognition/
[core_ml]: https://developer.apple.com/machine-learning/
[vizreq_with_coreml]: https://github.com/watson-developer-cloud/visual-recognition-coreml/
[vizreq_tooling]: https://watson-visual-recognition.ng.bluemix.net/
[xcode_download]: https://developer.apple.com/xcode/downloads/

[camera_view_controller]: /Core%20ML%20Vision/CameraViewController.swift
[credentials_plist]: /Core%20ML%20Vision/Credentials.plist

[screenshot_iphone]: /Screenshots/iPhone.png
