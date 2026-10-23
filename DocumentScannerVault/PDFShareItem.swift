//
//  PDFShareItem.swift
//  DocumentScannerVault
//
//  Created by ipeerless on 23/10/2026.
//


import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct PDFShareItem: FileDocument {
    static var readableContentTypes: [UTType] {
        [.pdf]
    }

    var data: Data

    init(url: URL) throws {
        data = try Data(contentsOf: url)
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
