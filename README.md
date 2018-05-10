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
1. Navigate to Watson Studio, [dataplatform.ibm.com][watson_studio_url].

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
    
1. Return to the Watson Studio homepage, [dataplatform.ibm.com][watson_studio_url], where you should see your new Visual Recognition service listed, hit the **Launch Tool** button.
    ![][screenshot_w10]
    
1. Next you will select the **Create Model** button within the box labeled **Custom**, this is where we begin to create our custom model.
    ![][screenshot_w11]
    
1. On the right side, click **browse** to upload our [training data][training_data]. Click the open button.
    ![][screenshot_w13]
    
1. It will take a moment for the zips to be uploaded, once they are ready, click the three dot menu next to the files and choose **Add to model** for each .zip file.
    ![][screenshot_w14]

1. Allow a few moments for the files to be added to the model. The tooling will automatically create a class for the set of images based on the names of the .zip files. Once the images are done loading you can click **Train Model** in the upper right corner. Please allow a few minutes for the model to train. 
    ![][screenshot_w15]
    
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
[discovery]: https://www.ibm.com/watson/services/discovery/
[core_ml]: https://developer.apple.com/machine-learning/
[vizreq_with_coreml]: https://github.com/watson-developer-cloud/visual-recognition-coreml/
[vizreq_tooling]: https://watson-visual-recognition.ng.bluemix.net/
[xcode_download]: https://developer.apple.com/xcode/downloads/
[watson_studio_visrec_tooling]: https://dataplatform.ibm.com/registration/stepone?target=watson_vision_combined&context=wdp&apps=watson_studio&cm_sp=WatsonPlatform-WatsonPlatform-_-OnPageNavCTA-IBMWatson_VisualRecognition-_-CoreMLGithub

[camera_view_controller]:  /Core%20ML%20Vision/CameraViewController.swift
[training_data]:/Training%20Data

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
