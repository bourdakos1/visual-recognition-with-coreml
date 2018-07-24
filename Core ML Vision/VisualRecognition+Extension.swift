//
//  File.swift
//  Core ML Vision
//
//  Created by Nicholas Bourdakos on 5/9/18.
//

import VisualRecognitionV3
import CoreML

extension VisualRecognition {
    /// Helper function for choosing the proper initializion (old / IAM) of `VisualRecognition`.
    static func easyInit(apiKey: String, version: String) -> VisualRecognition {
        // API keys from before May 23, 2018 should only contain hex values.
        let allowedChars = CharacterSet(charactersIn: "abcdef0123456789")
        
        // Check if the provided key contains only hex characters.
        let onlyHex = allowedChars.isSuperset(of: CharacterSet(charactersIn: apiKey))
        
        // Older keys generally have 40 characters, but may have less.
        if apiKey.count <= 40 && onlyHex {
            return VisualRecognition(apiKey: apiKey, version: version)
        }
        
        /*
         Default to IAM.
         IAM keys appear to have 44 characters and aren't restricted to hex values.
         */
        return VisualRecognition(version: version, apiKey: apiKey)
    }

    /// Helper function for checking if a model needs to be updated.
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
