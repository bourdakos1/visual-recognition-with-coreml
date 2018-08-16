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
// This app also uses extensions from `Supporting Files/VisualRecognition+Extensions.swift`.
import VisualRecognitionV3

struct VisualRecognitionConstants {
    static let modelIds = ["DefaultCustomModel_936213647"]
    static let version = "2018-07-24"
}

protocol ImageClassificationViewControllerDelegate: class {
    func didSelectItem(_ name: String)
}

class ImageClassificationViewController: UIViewController, ImageClassificationViewControllerDelegate {

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
    
    // MARK: - Model Methods
    
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

    func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    // MARK: - Image Classification
    
    func classifyImage(_ image: UIImage, localThreshold: Double = 0.0) {
        rawImage = image
        
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
    
    func didSelectItem(_ name: String) {
        startAnalysis(classToAnalyze: name)
    }
    
    var rawImage = UIImage()
    var editedImage = UIImage()
    var originalConfs = [ClassResult]()
    
    func startAnalysis(classToAnalyze: String, localThreshold: Double = 0.0) {
        var confidences = [[Double]](repeating: [Double](repeating: -1, count: 17), count: 17)
 
        DispatchQueue.main.async {
            SwiftSpinner.show("analyzing")
        }
        
        let usbClasses = originalConfs.filter({ return $0.className == classToAnalyze })
        guard let usbClass = usbClasses.first,
            let originalConf = usbClass.score else {
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
                        
                        let usbClass = classifier.classes.filter({ return $0.className.uppercased() == classToAnalyze })
                        
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
                
                let heatmap = self.calculateHeatmap(confidences, originalConf)
                let heatmapImage = self.renderHeatmap(heatmap, color: .black, size: self.rawImage.size)
                let outlineImage = self.renderOutline(heatmap, size: self.rawImage.size)
                
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
    
    func calculateHeatmap(_ confidences: [[Double]], _ originalConf: Double) -> [[CGFloat]] {
        var minVal: CGFloat = 1.0
        
        var heatmap = [[CGFloat]](repeating: [CGFloat](repeating: -1, count: 14), count: 14)
        
        // loop through each confidence
        for down in 0 ..< 14 {
            for right in 0 ..< 14 {
                // A 4x4 slice of the confidences
                let kernel = confidences[down + 0...down + 3].map({ $0[right + 0...right + 3] })
                
                // loop through each confidence in the slice and get the average, ignoring -1
                var result = 0.0
                let weights = [
                    [0.1, 0.5, 0.5, 0.1],
                    [0.5, 1.0, 1.0, 0.5],
                    [0.5, 1.0, 1.0, 0.5],
                    [0.1, 0.5, 0.5, 0.1],
                    ]
                var count = weights.joined().reduce(0, +)
                for (down, row) in kernel.enumerated() {
                    for (right, score) in row.enumerated() {
                        if score == -1 {
                            count -= weights[down][right]
                        } else {
                            result += score * weights[down][right]
                        }
                    }
                }
                
                let mean = CGFloat(result / count)
                
                heatmap[down][right] = mean
                
                minVal = min(mean, minVal)
            }
        }
        
        for (down, row) in heatmap.enumerated() {
            for (right, mean) in row.enumerated() {
                let newalpha = 1 - max(CGFloat(originalConf) - mean, 0) / max(CGFloat(originalConf) - minVal, 0)
                let cappedAlpha = min(max(newalpha, 0), 1)
                heatmap[down][right] = cappedAlpha
            }
        }
        
        return heatmap
    }
    
    func renderHeatmap(_ heatmap: [[CGFloat]], color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        let scale = size.width / 14
        let offset = (size.height - size.width) / 2
        
        for (down, row) in heatmap.enumerated() {
            for (right, mean) in row.enumerated() {
                let rectangle = CGRect(x: CGFloat(right) * scale, y: CGFloat(down) * scale + offset, width: scale, height: scale)
                color.withAlphaComponent(mean).setFill()
                UIRectFillUsingBlendMode(rectangle, .normal)
            }
        }
        
        color.setFill()

        let topMargin = CGRect(x: 0, y: 0, width: size.width, height: offset)
        let bottomMargin = CGRect(x: 0, y: size.width + offset, width: size.width, height: offset)
        UIRectFillUsingBlendMode(topMargin, .normal)
        UIRectFillUsingBlendMode(bottomMargin, .normal)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func renderOutline(_ heatmap: [[CGFloat]], size: CGSize) -> UIImage  {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        let path = UIBezierPath()
        
        let scale = size.width / 14
        let offset = (size.height - size.width) / 2
        
        for (down, row) in heatmap.enumerated() {
            for (right, cappedAlpha) in row.enumerated() {
                let scaledDown = CGFloat(down) * scale
                let scaledRight = CGFloat(right) * scale
                
                let topLeft = CGPoint(x: scaledRight, y: scaledDown + offset)
                let topRight = CGPoint(x: scaledRight + scale, y: scaledDown + offset)
                let bottomRight = CGPoint(x: scaledRight + scale, y: scaledDown + scale + offset)
                let bottomLeft = CGPoint(x: scaledRight, y: scaledDown + scale + offset)
                
                if cappedAlpha < 0.5 {
                    path.move(to: bottomLeft)
                    
                    // check the block to the left
                    if right <= 0 || heatmap[down][right - 1] >= 0.5 {
                        path.addLine(to: topLeft)
                    } else {
                        path.move(to: topLeft)
                    }
                    // check the block above
                    if down <= 0 || heatmap[down - 1][right] >= 0.5 {
                        path.addLine(to: topRight)
                    } else {
                        path.move(to: topRight)
                    }
                    // check the block to the right
                    if right >= heatmap[down].count - 1 || heatmap[down][right + 1] >= 0.5 {
                        path.addLine(to: bottomRight)
                    } else {
                        path.move(to: bottomRight)
                    }
                    // check the block below
                    if down >= heatmap.count - 1 || heatmap[down + 1][right] >= 0.5 {
                        path.addLine(to: bottomLeft)
                    } else {
                        path.move(to: bottomLeft)
                    }
                }
            }
        }
        
        path.lineWidth = 8
        UIColor(red: 0 / 255, green: 0 / 255, blue: 0 / 255, alpha: 0.4).setStroke()
        path.stroke()
        
        path.lineWidth = 6
        UIColor(red: 255 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1).setStroke()
        path.stroke()
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
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
}

// MARK: - Error Handling

extension ImageClassificationViewController {
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

extension ImageClassificationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        classifyImage(image)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension ImageClassificationViewController: AVCapturePhotoCaptureDelegate {
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


