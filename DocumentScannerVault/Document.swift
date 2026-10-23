//
//  Item.swift
//  DocumentScannerVault
//
//  Created by ipeerless on 23/10/2026.
//


import Foundation
import SwiftData

@Model
final class Document {
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var pdfFilename: String
    var recognizedText: String

    init(
        title: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        pdfFilename: String,
        recognizedText: String = ""
    ) {
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pdfFilename = pdfFilename
        self.recognizedText = recognizedText
    }
}
