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
// This app also uses extensions from `Supporting Files/VisualRecognition+Helpers.swift`.
import VisualRecognitionV3

struct VisualRecognitionConstants {
    static let modelIds = ["YOUR_MODEL_ID"]
    static let version = "2018-07-24"
}

class CameraViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var heatmapView: UIImageView!
    @IBOutlet weak var outlineView: UIImageView!
    @IBOutlet weak var focusView: UIImageView!
    @IBOutlet weak var simulatorTextView: UITextView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var updateModelButton: UIButton!
    @IBOutlet weak var choosePhotoButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var alphaSlider: UISlider!
    
    // MARK: - Variable Declarations
    
    let visualRecognition: VisualRecognition = {
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
    
    let photoOutput = AVCapturePhotoOutput()
    lazy var captureSession: AVCaptureSession? = {
        guard let backCamera = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: backCamera) else {
                return nil
        }
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        captureSession.addInput(input)
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = CGRect(x: view.bounds.minX, y: view.bounds.minY, width: view.bounds.width, height: view.bounds.height)
            // `.resize` allows the camera to fill the screen on the iPhone X.
            previewLayer.videoGravity = .resize
            previewLayer.connection?.videoOrientation = .portrait
            cameraView.layer.addSublayer(previewLayer)
            return captureSession
        }
        return nil
    }()
    
    var editedImage = UIImage()
    var originalConfs = [ClassResult]()
    var heatmaps = [String: HeatmapImages]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession?.startRunning()
        resetUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var modelsToUpdate = [String]()
        
        let dispatchGroup = DispatchGroup()
        
        for modelId in VisualRecognitionConstants.modelIds {
            dispatchGroup.enter()
            /*
             `checkLocalModelStatus` is not part of the Watson SDK.
             `checkLocalModelStatus` is a convenient extension that checks if the local model
             is up to date. The actual SDK makes this check as well in `updateLocalModel`.
             However, we perfom this check purely for UI purposes.
             */
            visualRecognition.checkLocalModelStatus(classifierID: modelId) { modelUpToDate in
                defer { dispatchGroup.leave() }
                if !modelUpToDate {
                    modelsToUpdate.append(modelId)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.updateLocalModels(ids: modelsToUpdate)
        }
        
        guard let drawer = pulleyViewController?.drawerContentViewController as? ResultsTableViewController else {
            return
        }
        
        drawer.delegate = self
    }
    
    func updateLocalModels(ids modelIds: [String]) {
        // If the array is empty the dispatch group won't be notified, so we might end up with an endless spinner.
        if modelIds.count <= 0 { return }
        
        SwiftSpinner.show("Compiling model...")
        
        let dispatchGroup = DispatchGroup()
        
        for modelId in modelIds {
            dispatchGroup.enter()
            let failure = { (error: Error) in
                DispatchQueue.main.async {
                    self.modelUpdateFail(modelId: modelId, error: error)
                    dispatchGroup.leave()
                }
            }
            let success = {
                dispatchGroup.leave()
            }
            
            visualRecognition.updateLocalModel(classifierID: modelId, failure: failure, success: success)
        }
        
        dispatchGroup.notify(queue: .main) {
            SwiftSpinner.hide()
        }
    }
    
    // MARK: - Image Classification
    
    func classifyImage(_ image: UIImage, localThreshold: Double = 0.0) {
        editedImage = cropToCenter(image: image, targetSize: CGSize(width: 224, height: 224))
        
        showResultsUI(for: image)
        
        visualRecognition.classifyWithLocalModel(image: editedImage, classifierIDs: VisualRecognitionConstants.modelIds, threshold: localThreshold, failure: nil) { classifiedImages in

            // Make sure that an image was successfully classified.
            guard let classifiedImage = classifiedImages.images.first,
                let classifier = classifiedImage.classifiers.first else {
                    return
            }
            
            DispatchQueue.main.async {
                self.push(results: [classifier])
            }
        
            self.originalConfs = classifier.classes
        }
    }
    
    func startAnalysis(classToAnalyze: String, localThreshold: Double = 0.0) {
        if let heatmapImages = heatmaps[classToAnalyze] {
            heatmapView.image = heatmapImages.heatmap
            outlineView.image = heatmapImages.outline
            return
        }
        
        var confidences = [[Double]](repeating: [Double](repeating: -1, count: 17), count: 17)
 
        DispatchQueue.main.async {
            SwiftSpinner.show("analyzing")
        }
        
        let chosenClasses = originalConfs.filter({ return $0.className == classToAnalyze })
        guard let chosenClass = chosenClasses.first,
            let originalConf = chosenClass.score else {
                return
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        DispatchQueue.global(qos: .background).async {
            for down in 0 ..< 11 {
                for right in 0 ..< 11 {
                    confidences[down + 3][right + 3] = 0
                    dispatchGroup.enter()
                    let maskedImage = self.maskImage(image: self.editedImage, at: CGPoint(x: right, y: down))
                    self.visualRecognition.classifyWithLocalModel(image: maskedImage, classifierIDs: VisualRecognitionConstants.modelIds, threshold: localThreshold, failure: nil) { [down, right] classifiedImages in
                        
                        defer { dispatchGroup.leave() }
 
                        // Make sure that an image was successfully classified.
                        guard let classifiedImage = classifiedImages.images.first,
                            let classifier = classifiedImage.classifiers.first else {
                                return
                        }
                        
                        let usbClass = classifier.classes.filter({ return $0.className == classToAnalyze })
                        
                        guard let usbClassSingle = usbClass.first,
                            let score = usbClassSingle.score else {
                                return
                        }
                        
                        print(".", terminator:"")
                        
                        confidences[down + 3][right + 3] = score
                    }
                }
            }
            dispatchGroup.leave()
            
            dispatchGroup.notify(queue: .main) {
                print()
                print(confidences)
                
                guard let image = self.imageView.image else {
                    return
                }
                
                let heatmap = self.calculateHeatmap(confidences, originalConf)
                let heatmapImage = self.renderHeatmap(heatmap, color: .black, size: image.size)
                let outlineImage = self.renderOutline(heatmap, size: image.size)
                
                let heatmapImages = HeatmapImages(heatmap: heatmapImage, outline: outlineImage)
                self.heatmaps[classToAnalyze] = heatmapImages
                
                self.heatmapView.image = heatmapImage
                self.outlineView.image = outlineImage
                self.heatmapView.alpha = CGFloat(self.alphaSlider.value)
                
                self.heatmapView.isHidden = false
                self.outlineView.isHidden = false
                self.alphaSlider.isHidden = false
                
                SwiftSpinner.hide()
            }
        }
    }
    
    func maskImage(image: UIImage, at point: CGPoint) -> UIImage {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        image.draw(at: .zero)
        
        let rectangle = CGRect(x: point.x * 16, y: point.y * 16, width: 64, height: 64)
        
        UIColor(red: 1, green: 0, blue: 1, alpha: 1).setFill()
        UIRectFill(rectangle)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func cropToCenter(image: UIImage, targetSize: CGSize) -> UIImage {
        let offset = abs((image.size.width - image.size.height) / 2)
        let posX = image.size.width > image.size.height ? offset : 0.0
        let posY = image.size.width < image.size.height ? offset : 0.0
        let newSize = CGFloat(min(image.size.width, image.size.height))
        
        // crop image to square
        let cropRect = CGRect(x: posX, y: posY, width: newSize, height: newSize)
        
        guard let cgImage = image.cgImage,
            let cropped = cgImage.cropping(to: cropRect) else {
                return image
        }
        
        let image = UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
        
        let resizeRect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: resizeRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
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
    
    func showResultsUI(for image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        simulatorTextView.isHidden = true
        closeButton.isHidden = false
        captureButton.isHidden = true
        choosePhotoButton.isHidden = true
        updateModelButton.isHidden = true
        focusView.isHidden = true
    }
    
    func resetUI() {
        heatmaps = [String: HeatmapImages]()
        if captureSession != nil {
            simulatorTextView.isHidden = true
            imageView.isHidden = true
            captureButton.isHidden = false
            focusView.isHidden = false
        } else {
            imageView.image = UIImage(named: "Background")
            simulatorTextView.isHidden = false
            imageView.isHidden = false
            captureButton.isHidden = true
            focusView.isHidden = true
        }
        heatmapView.isHidden = true
        outlineView.isHidden = true
        alphaSlider.isHidden = true
        closeButton.isHidden = true
        choosePhotoButton.isHidden = false
        updateModelButton.isHidden = false
        dismissResults()
    }
    
    // MARK: - IBActions
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let currentValue = CGFloat(sender.value)
        self.heatmapView.alpha = currentValue
    }
    
    @IBAction func capturePhoto() {
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    @IBAction func updateModel(_ sender: Any) {
        updateLocalModels(ids: VisualRecognitionConstants.modelIds)
    }
    
    @IBAction func presentPhotoPicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    @IBAction func reset() {
        resetUI()
    }
    
    // MARK: - Structs
    
    struct HeatmapImages {
        let heatmap: UIImage
        let outline: UIImage
    }
}

// MARK: - Error Handling

extension CameraViewController {
    func showAlert(_ alertTitle: String, alertMessage: String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func modelUpdateFail(modelId: String, error: Error) {
        let error = error as NSError
        var errorMessage = ""
        
        // 0 = probably wrong api key
        // 404 = probably no model
        // -1009 = probably no internet
        
        switch error.code {
        case 0:
            errorMessage = "Please check your Visual Recognition API key in `Credentials.plist` and try again."
        case 404:
            errorMessage = "We couldn't find the model with ID: \"\(modelId)\""
        case 500:
            errorMessage = "Internal server error. Please try again."
        case -1009:
            errorMessage = "Please check your internet connection."
        default:
            errorMessage = "Please try again."
        }
        
        // TODO: Do some more checks, does the model exist? is it still training? etc.
        // The service's response is pretty generic and just guesses.
        
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
        
        classifyImage(image)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let photoData = photo.fileDataRepresentation(),
            let image = UIImage(data: photoData) else {
            return
        }
        
        classifyImage(image)
    }
}

// MARK: - TableViewControllerSelectionDelegate

extension CameraViewController: TableViewControllerSelectionDelegate {
    func didSelectItem(_ name: String) {
        startAnalysis(classToAnalyze: name)
    }
}


