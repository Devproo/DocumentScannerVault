//
//  TextRecognizer.swift
//  DocumentScannerVault
//
//  Created by ipeerless on 23/10/2026.
//

import UIKit
import Vision

enum TextRecognizer {
    static func recognizeText(in image: UIImage) throws -> String {
        guard let cgImage = image.cgImage else {
            return ""
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])

        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}

