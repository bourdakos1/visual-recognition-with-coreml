//
//  File.swift
//  Core ML Vision
//
//  Created by Nicholas Bourdakos on 5/9/18.
//

import VisualRecognitionV3
import CoreML

extension VisualRecognition {
    func checkLocalModelStatus(classifierID: String, modelUpToDate: @escaping (Bool) -> Void) {
        // setup date formatter '2017-12-04T19:44:27.419Z'
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        // load model from disk
        guard let model = try? getLocalModel(classifierID: classifierID) else {
            // There is no local model so it can't be up to date.
            modelUpToDate(false)
            return
        }
        
        // parse the date on which the local model was last updated
        let description = model.modelDescription
        let metadata = description.metadata[MLModelMetadataKey.creatorDefinedKey] as? [String: String] ?? [:]
        guard let updated = metadata["retrained"] ?? metadata["created"], let modelDate = dateFormatter.date(from: updated) else {
            modelUpToDate(false)
            return
        }
        
        // parse the date on which the classifier was last updated
        getClassifier(classifierID: classifierID, failure: nil) { classifier in
            guard let dateString = classifier.retrained ?? classifier.created, let classifierDate = dateFormatter.date(from: dateString) else {
                DispatchQueue.main.async {
                    modelUpToDate(false)
                }
                return
            }
            
            if classifierDate > modelDate && classifier.status == "ready" {
                DispatchQueue.main.async {
                    modelUpToDate(false)
                }
            } else {
                DispatchQueue.main.async {
                    modelUpToDate(true)
                }
            }
        }
    }
}
