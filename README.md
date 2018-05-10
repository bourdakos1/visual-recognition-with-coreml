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
1. Log in to Watson Studio, [dataplatform.ibm.com][watson_studio_visrec_tooling]. From this link you can create an IBM Cloud account, sign up for Watson Studio, or log in.

## Training a custom model
1. Navigate to [Watson Studio][watson_studio_url].

1. Once in Watson Studio, click **New project**.
    ![][screenshot_w0]

1. Select the option for **Complete** and hit _OK_.
    ![][screenshot_w1]
    
1. Name your project Connectors and click **add** on the right hand side under _Define Storage_ and follow the prompts.
    ![][screenshot_w2]
    
1. Select the **Lite** option for your storage service and click **Create**.
    ![][screenshot_w3]
    
1. Once your storage service is created, you will be redirected to the **new project** page, you will need to hit **Refresh** for your service to be assigned to the project.
    ![][screenshot_w4]
    
1. Click **Create** to finish creating your project.

1. From the project dashboard, select the **Settings** tab.
    ![][screenshot_w5]

1. Scroll down until you see the option to **Add service**.
    ![][screenshot_w6]
    
1. Select **Watson**.
    ![][screenshot_w7]
    
1. Click **Add** in the **Visual Recognition** box.
    ![][screenshot_w8]

1. When prompted, select the option for the **Lite** plan and click **Create**.
    ![][screenshot_w9]
    
1. Return to the Watson Studio homepage, [https://dataplatform.ibm.com][watson_studio_url], where you should see your new Visual Recognition service listed, hit the **Launch Tool** button.
    ![][screenshot_w10]
    
1. Next you will select the **Create Model** button within the box labeled **Custom**, this is where we begin to create our custom model.
    ![][screenshot_w11]

### Copy your Model ID and API Key
1. In Watson Studio on the Visual Recognition instance overview page, click your Visual Recognition instance name (it's next to Associated Service). 
1. Scroll down to find the **Custom Core ML** classifier you just created. 
1. Copy the **Model ID** of the classifier.
1. In the Visual Recognition instance overview page in Watson Studio. Click the **Credentials** tab, and then click **View credentials**. Copy the `api_key` of the service.

### Adding the classifierId and apiKey to the project
1. Open the project in XCode.
1. Copy the **Model ID** and paste it into the **classifierID** property in the [ImageClassificationViewController](../master/Core%20ML%20Vision%20With%20Discovery/Core%20ML%20Vision%Discovery/ImageClassificationViewController.swift) file.
1. Copy your **api_key** and paste it into the **apiKey** property in the [ImageClassificationViewController](../master/Core%20ML%20Vision%20With%20Discovery/Core%20ML%20Vision%Discovery/ImageClassificationViewController.swift) file.

## Installing the Watson Swift SDK
The Watson Swift SDK makes it easy to keep track of your custom Core ML models and to download your custom classifiers from IBM Cloud to your device.

Use the Carthage dependency manager to download and build the Watson Swift SDK.

1. Open a terminal window and navigate to this project's directory.
1. Run the following command to download and build the Watson Swift SDK:

    ```bash
    carthage bootstrap --platform iOS
    ```
    
## Configuring the app

1. In Xcode, open the [CameraViewController.swift][camera_view_controller] file.
1. Paste the values that you saved earlier into properties near the top of the file and save it:
    - Visual Recognition API key > **apiKey**.
    - Visual Recognition Classifier ID > **classifierID**.

## Running the app
The app uses the Visual Recognition service and Core ML model on your device to classify the image. Then the app sends the classification to Watson Discovery service and displays more information about the cable.

When you run the app, the SDK makes sure that the version of the Visual Recognition model on your device is in sync with the latest version on IBM Cloud. If the local version is older, the SDK downloads the model to your device. With a local model, you can classify images offline. You need to be connected to the internet to communicate with the Discovery service.

1. In Xcode, select the `Core ML Vision Discovery` scheme.
1. Run the app in the simulator or on a device.
1. Classify an image by clicking the camera icon and selecting a photo from your photo library or by taking a picture of a USB or HDMI connector. To add your own images in the simulator, drag the image from Finder to the simulator window.
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

[watson_studio_url]: https://dataplatform.ibm.com
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
[screenshot_w2]: /Screenshots/walkthrough_2.png
[screenshot_w3]: /Screenshots/walkthrough_3.png
[screenshot_w4]: /Screenshots/walkthrough_4.png
[screenshot_w5]: /Screenshots/walkthrough_5.png
[screenshot_w6]: /Screenshots/walkthrough_6.png
[screenshot_w7]: /Screenshots/walkthrough_7.png
[screenshot_w8]: /Screenshots/walkthrough_8.png
[screenshot_w9]: /Screenshots/walkthrough_9.png
[screenshot_w10]: /Screenshots/walkthrough_10.png
[screenshot_w11]: /Screenshots/walkthrough_11.png
[screenshot_w12]: /Screenshots/walkthrough_12.png
[screenshot_w13]: /Screenshots/walkthrough_13.png
[screenshot_w14]: /Screenshots/walkthrough_14.png
[screenshot_w15]: /Screenshots/walkthrough_15.png
[screenshot_w16]: /Screenshots/walkthrough_16.png
[screenshot_w17]: /Screenshots/walkthrough_17.png
[screenshot_w18]: /Screenshots/walkthrough_18.png
[screenshot_w19]: /Screenshots/walkthrough_19.png
