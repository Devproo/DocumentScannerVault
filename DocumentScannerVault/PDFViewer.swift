//
//  PDFViewer.swift
//  DocumentScannerVault
//
//  Created by ipeerless on 23/10/2026.
//

import SwiftUI
import PDFKit
import UIKit

struct PDFViewer: View {
    let url: URL

    @State private var shareURL: URL?
    @State private var showingShareSheet = false
    @State private var shareError: String?

    var body: some View {
        PDFKitView(url: url)
            .navigationTitle(url.deletingPathExtension().lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        preparePDFForSharing()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share PDF")
                }
            }
            .sheet(
                isPresented: $showingShareSheet,
                onDismiss: removeTemporaryPDF
            ) {
                if let shareURL {
                    ActivityViewController(items: [shareURL])
                }
            }
            .alert(
                "Unable to Share PDF",
                isPresented: Binding(
                    get: { shareError != nil },
                    set: { if !$0 { shareError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    shareError = nil
                }
            } message: {
                Text(shareError ?? "")
            }
    }

    private func preparePDFForSharing() {
        guard FileManager.default.fileExists(atPath: url.path) else {
            shareError = "The original PDF file could not be found."
            return
        }

        do {
            let temporaryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("pdf")

            try FileManager.default.copyItem(
                at: url,
                to: temporaryURL
            )

            shareURL = temporaryURL
            showingShareSheet = true
        } catch {
            shareError = "Could not prepare the PDF for sharing: \(error.localizedDescription)"
        }
    }

    private func removeTemporaryPDF() {
        if let shareURL {
            try? FileManager.default.removeItem(at: shareURL)
        }

        shareURL = nil
    }
}

private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePage
        view.displayDirection = .vertical
        view.usePageViewController(true)
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: url)
    }
}

private struct ActivityViewController: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ controller: UIActivityViewController,
        context: Context
    ) {}
}
