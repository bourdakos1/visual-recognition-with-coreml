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

### Setting up Visual Recognition in Watson Studio
1.  Log into [Watson Studio][watson_studio_visrec_tooling]. From this link you can create an IBM Cloud account, sign up for Watson Studio, or log in.
1.  After you sign up or log in, you'll be on the Visual Recognition instance overview page in Watson Studio.

### Training the model
1.  In Watson Studio on the Visual Recognition instance overview page, click **Create Model** in the Custom box.

    ![][screenshot_w0]

1.  If a project is not yet associated with the Visual Recognition instance you created, a project is created. Name your project 'Custom Core ML' and click the **Create**. 

    ![][screenshot_w1]

    **Tip**: If no storage is defined, click **refresh**.
1.  Upload each .zip file of sample images from the `Training Images` directory onto the data panel. Add the `hdmi_male.zip` file to your model by clicking the **Browse** button in the data panel. Also add the `usb_male.zip`, `thunderbolt_male.zip`, `vga_male.zip` file to your model.
1.  Click **Train Model**.

### Copy your Model ID and API Key
1.  In Watson Studio on the Visual Recognition instance overview page, click your Visual Recognition instance name (it's next to Associated Service). 
1.  Scroll down to find the **Custom Core ML** classifier you just created. 
1.  Copy the **Model ID** of the classifier.
1.  In the Visual Recognition instance overview page in Watson Studio. Click the **Credentials** tab, and then click **View credentials**. Copy the `api_key` of the service.

### Adding the classifierId and apiKey to the project
1.  Open the project in XCode.
1.  Copy the **Model ID** and paste it into the **classifierID** property in the [ImageClassificationViewController](../master/Core%20ML%20Vision%20With%20Discovery/Core%20ML%20Vision%Discovery/ImageClassificationViewController.swift) file.
1.  Copy your **api_key** and paste it into the **apiKey** property in the [ImageClassificationViewController](../master/Core%20ML%20Vision%20With%20Discovery/Core%20ML%20Vision%Discovery/ImageClassificationViewController.swift) file.

## Installing the Watson Swift SDK
The Watson Swift SDK makes it easy to keep track of your custom Core ML models and to download your custom classifiers from IBM Cloud to your device.

Use the Carthage dependency manager to download and build the Watson Swift SDK.

1.  Open a terminal window and navigate to this project's directory.
1.  Run the following command to download and build the Watson Swift SDK:

    ```bash
    carthage bootstrap --platform iOS
    ```
    
## Configuring the app

1.  In Xcode, open the [CameraViewController.swift][camera_view_controller] file.
1.  Paste the values that you saved earlier into properties near the top of the file and save it:
    - Visual Recognition API key > **apiKey**.
    - Visual Recognition Classifier ID > **classifierID**.

## Running the app
The app uses the Visual Recognition service and Core ML model on your device to classify the image. Then the app sends the classification to Watson Discovery service and displays more information about the cable.

When you run the app, the SDK makes sure that the version of the Visual Recognition model on your device is in sync with the latest version on IBM Cloud. If the local version is older, the SDK downloads the model to your device. With a local model, you can classify images offline. You need to be connected to the internet to communicate with the Discovery service.

1.  In Xcode, select the `Core ML Vision Discovery` scheme.
1.  Run the app in the simulator or on a device.
1.  Classify an image by clicking the camera icon and selecting a photo from your photo library or by taking a picture of a USB or HDMI connector. To add your own images in the simulator, drag the image from Finder to the simulator window.
1. Pull new versions of the visual recognition model with the refresh button in the upper right.

    If you're online, the application queries the Discovery service and displays information about the classification results in the bottom panel.

    **Tip:** The visual recognition classifier status must be `Ready` to use it. Check the classifier status in Watson Studio on the Visual Recognition instance overview page.

## What to do next

Try using your own data: Train a Visual Recognition classifier with your own images and add your own documents to Discovery. For details on those services, see the links in the Resources section.

## Resources

- [Visual Recognition docs](https://console.bluemix.net/docs/services/visual-recognition/getting-started.html) and [Discovery docs](https://console.bluemix.net/docs/services/discovery/getting-started-tool.html)
- [Watson Swift SDK](https://github.com/watson-developer-cloud/swift-sdk)
- [Apple machine learning][core_ml] and [Core ML documentation](https://developer.apple.com/documentation/coreml)
- [Watson console](https://bluemix.net/developer/watson) on IBM Cloud

[carthage_download]: https://github.com/Carthage/Carthage/releases
[carthage_instructions]: https://github.com/Carthage/Carthage#installing-carthage
[vizreq]: https://www.ibm.com/watson/services/visual-recognition/
[discovery]: https://www.ibm.com/watson/services/discovery/
[core_ml]: https://developer.apple.com/machine-learning/
[vizreq_with_coreml]: https://github.com/watson-developer-cloud/visual-recognition-coreml/
[vizreq_tooling]: https://watson-visual-recognition.ng.bluemix.net/
[xcode_download]: https://developer.apple.com/xcode/downloads/
[watson_studio_visrec_tooling]: https://dataplatform.ibm.com/registration/stepone?target=watson_vision_combined&context=wdp&apps=watson_studio&cm_sp=WatsonPlatform-WatsonPlatform-_-OnPageNavCTA-IBMWatson_VisualRecognition-_-CoreMLGithub

[camera_view_controller]:  /Core%20ML%20Vision/CameraViewController.swift

[screenshot_iphone]: /Screenshots/iPhone.png
[screenshot_w0]: /Screenshots/walkthrough_0.png
[screenshot_w1]: /Screenshots/walkthrough_1.png
