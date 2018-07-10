/**
 * Copyright IBM Corporation 2017, 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit
import AVFoundation

/**
 * This app uses several extensions from `VisualRecognition+Extension.swift`.
 * Be sure to include it in your project if you are reusing this code.
 **/
import VisualRecognitionV3

struct VisualRecognitionConstants {
    // Update this with your own model id.
    static let modelIds = ["YOUR_MODEL_ID"]
    static let version = "2017-11-10"
}

class CameraViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var tempImageView: UIImageView!
    @IBOutlet var noCameraView: UIView!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var retakeButton: UIButton!
    @IBOutlet var updateModelButton: UIButton!
    @IBOutlet var choosePhotoButton: UIButton!
    
    // MARK: - Variable Declarations
    
    var cameraAvailable = true
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var visualRecognition: VisualRecognition = {
        guard let path = Bundle.main.path(forResource: "Credentials", ofType: "plist") else {
            // Please create a Credentials.plist file with your Visual Recognition credentials.
            fatalError()
        }
        guard let apiKey = NSDictionary(contentsOfFile: path)?["apikey"] as? String else {
            // No Visual Recognition API key found. Make sure you add your API key to the Credentials.plist file.
            fatalError()
        }
        
        /*
         `easyInit` is not part of the Watson SDK.
         `easyInit` is a convenient extension that tries to detect whether the supplied apiKey is:
         - a Visual Recognition instance created before May 23, 2018
         - a new IAM API key
         It then returns the properly initialized VisualRecognition instance.
         */
        return VisualRecognition.easyInit(apiKey: apiKey, version: VisualRecognitionConstants.version)
    }()
    
    // MARK: - Override Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeCamera()
        resetUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for modelId in VisualRecognitionConstants.modelIds {
            /*
             `checkLocalModelStatus` is not part of the Watson SDK.
             `checkLocalModelStatus` is a convenient extension that checks if the local model
             is up to date. The actual SDK makes this check as well in `updateLocalModel`.
             However, we perfom this check purely for UI purposes.
             */
            visualRecognition.checkLocalModelStatus(classifierID: modelId) { modelUpToDate in
                if !modelUpToDate {
                    self.invokeModelUpdate(for: modelId)
                }
            }
        }
    }
    
    // MARK: - Functions

    func initializeCamera() {
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            cameraAvailable = false
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: backCamera) else {
            cameraAvailable = false
            return
        }
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        captureSession?.addInput(input)
        photoOutput = AVCapturePhotoOutput()
        
        if (captureSession?.canAddOutput(photoOutput!) != nil) {
            captureSession?.addOutput(photoOutput!)
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer?.videoGravity = .resize
            previewLayer?.connection?.videoOrientation = .portrait
            cameraView.layer.addSublayer(previewLayer!)
            captureSession?.startRunning()
        }
        
        previewLayer?.frame = view.bounds
    }
    
    func invokeModelUpdate(for modelId: String) {
        let failure = { (error: Error) in
            self.modelUpdateFail(error: error)
            SwiftSpinner.hide()
        }
        
        let success = {
            SwiftSpinner.hide()
        }
        // The spinner can only be hailed after viewDidAppear.
        SwiftSpinner.show("Updating...")
        visualRecognition.updateLocalModel(classifierID: modelId, failure: failure, success: success)
    }
    
    func classifyImage(for image: UIImage, localThreshold: Double = 0.0) {
        showClassifyUI(forImage: image)
        
        let failure = { (error: Error) in
            self.showAlert("Could not classify image", alertMessage: error.localizedDescription)
        }
        
        visualRecognition.classifyWithLocalModel(image: image, classifierIDs: VisualRecognitionConstants.modelIds, threshold: localThreshold, failure: failure) { classifiedImages in
            
            guard let classifiedImage = classifiedImages.images.first else {
                return
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.push(results: classifiedImage.classifiers)
            }
        }
    }
    
    func dismissResults() {
        push(results: [], position: .closed)
    }
    
    func push(results: [VisualRecognitionV3.ClassifierResult], position: PulleyPosition = .partiallyRevealed) {
        guard let drawer = pulleyViewController?.drawerContentViewController as? ResultsTableViewController else {
            return
        }
        drawer.classifications = results
        pulleyViewController?.setDrawerPosition(position: position, animated: true)
        drawer.tableView.reloadData()
    }
    
    func resetUI() {
        if (cameraAvailable) {
            noCameraView.isHidden = true
            tempImageView.isHidden = true
            captureButton.isHidden = false
        } else {
            tempImageView.image = UIImage(named: "background")
            noCameraView.isHidden = false
            tempImageView.isHidden = false
            captureButton.isHidden = true
        }
        retakeButton.isHidden = true
        choosePhotoButton.isHidden = false
        updateModelButton.isHidden = false
        dismissResults()
    }
    
    func showClassifyUI(forImage image: UIImage) {
        tempImageView.image = image
        tempImageView.isHidden = false
        captureButton.isHidden = true
        retakeButton.isHidden = false
        choosePhotoButton.isHidden = true
        updateModelButton.isHidden = true
        noCameraView.isHidden = true
    }
    
    // MARK: - IBActions
    
    @IBAction func takePhoto() {
        photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    @IBAction func retake() {
        resetUI()
    }
    
    @IBAction func updateModel() {
        for modelId in VisualRecognitionConstants.modelIds {
            invokeModelUpdate(for: modelId)
        }
    }
    
    @IBAction func presentPhotoPicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
}

// MARK: - Error Handling

extension CameraViewController {
    func showAlert(_ alertTitle: String, alertMessage: String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func modelUpdateFail(error: Error) {
        let error = error as NSError
        var errorMessage = ""
        
        switch error.code {
        case 403:
            errorMessage = "Please check your Visual Recognition API key and try again."
        case 401:
            errorMessage = "Invalid credentials. Please check your Visual Recognition credentials and try again."
        case 500:
            errorMessage = "Internal server error. Please try again."
        default:
            errorMessage = "Please try again."
        }
        
        // TODO: Do some more checks, does the model exist? is it still training?
        // The services response is pretty generic.
        
        showAlert("Unable to download model", alertMessage: errorMessage)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        classifyImage(for: image)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let photoData = photo.fileDataRepresentation() else {
            return
        }
        guard let image = UIImage(data: photoData) else {
            return
        }
        classifyImage(for: image)
    }
}
