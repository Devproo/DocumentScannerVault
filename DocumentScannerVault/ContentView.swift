//
//  ContentView.swift
//  DocumentScannerVault
//
//  Created by ipeerless on 23/10/2026.
//


import SwiftUI
import SwiftData
import VisionKit
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Document.createdAt, order: .reverse)
    private var documents: [Document]
    
    @State private var showingScanner = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var documentToRename: Document?
    @State private var newDocumentTitle = ""
    
    @State private var documentToDelete: Document?
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredDocuments.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Documents" : "No Results",
                        systemImage: searchText.isEmpty
                        ? "doc.text"
                        : "magnifyingglass",
                        description: Text(
                            searchText.isEmpty
                            ? "Scan a document to get started."
                            : "Try a different search term."
                        )
                    )
                } else {
                    List {
                        ForEach(filteredDocuments) { document in
                            HStack(spacing: 8) {
                                NavigationLink {
                                    PDFViewer(url: pdfURL(for: document))
                                } label: {
                                    VStack(
                                        alignment: .leading,
                                        spacing: 4
                                    ) {
                                        Text(document.title)
                                            .font(.headline)
                                        
                                        Text(
                                            document.createdAt,
                                            style: .date
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        
                                        if !document.recognizedText.isEmpty {
                                            Text(document.recognizedText)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                }
                                
                                Menu {
                                    Button(
                                        "Rename",
                                        systemImage: "pencil"
                                    ) {
                                        newDocumentTitle = document.title
                                        documentToRename = document
                                    }
                                    
                                    Button(
                                        "Delete",
                                        systemImage: "trash",
                                        role: .destructive
                                    ) {
                                        documentToDelete = document
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                    }
                    .searchable(
                        text: $searchText,
                        prompt: "Search documents"
                    )
                }
            }
            .navigationTitle("Document Vault")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingScanner = true
                    } label: {
                        Label(
                            "Scan Document",
                            systemImage: "doc.viewfinder"
                        )
                    }
                    .disabled(!VNDocumentCameraViewController.isSupported)
                }
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView(
                    onScan: { pages in
                        saveScannedDocument(pages)
                    },
                    onCancel: {}
                )
                .ignoresSafeArea()
            }
            .alert(
                "Rename Document",
                isPresented: Binding(
                    get: { documentToRename != nil },
                    set: {
                        if !$0 {
                            documentToRename = nil
                        }
                    }
                )
            ) {
                TextField("Document title", text: $newDocumentTitle)
                
                Button("Cancel", role: .cancel) {
                    documentToRename = nil
                }
                
                Button("Save") {
                    renameDocument()
                }
            } message: {
                Text("Enter a new title for this document.")
            }
            .alert(
                "Something Went Wrong",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: {
                        if !$0 {
                            errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .confirmationDialog(
                "Delete this document?",
                isPresented: Binding(
                    get: { documentToDelete != nil },
                    set: { if !$0 { documentToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let document = documentToDelete {
                        deleteDocument(document)
                    }
                    documentToDelete = nil
                }
                
                Button("Cancel", role: .cancel) {
                    documentToDelete = nil
                }
            } message: {
                Text("This permanently deletes the document and its PDF file.")
            }
        }
    }
    
    private func pdfURL(for document: Document) -> URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent(document.pdfFilename)
    }
    
    private var filteredDocuments: [Document] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard !query.isEmpty else {
            return documents
        }
        
        return documents.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.recognizedText.localizedCaseInsensitiveContains(query)
        }
    }
    
    private func renameDocument() {
        guard let document = documentToRename else { return }
        
        let title = newDocumentTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard !title.isEmpty else {
            documentToRename = nil
            return
        }
        
        document.title = title
        document.updatedAt = .now
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Could not rename the document: \(error.localizedDescription)"
        }
        
        documentToRename = nil
    }
    
    private func deleteDocument(_ document: Document) {
        let url = pdfURL(for: document)
        
        modelContext.delete(document)
        
        do {
            try modelContext.save()
            
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            errorMessage = "Could not delete the document: \(error.localizedDescription)"
        }
    }
    
    private func saveScannedDocument(_ pages: [UIImage]) {
        guard !pages.isEmpty else { return }
        
        var savedPDFURL: URL?
        
        do {
            let filename = "\(UUID().uuidString).pdf"
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            let pdfURL = documentsDirectory.appendingPathComponent(filename)
            
            let pageBounds = CGRect(
                x: 0,
                y: 0,
                width: 612,
                height: 792
            )
            let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
            
            let pdfData = renderer.pdfData { context in
                for image in pages {
                    context.beginPage()
                    
                    let scale = min(
                        pageBounds.width / image.size.width,
                        pageBounds.height / image.size.height
                    )
                    
                    let size = CGSize(
                        width: image.size.width * scale,
                        height: image.size.height * scale
                    )
                    
                    let origin = CGPoint(
                        x: (pageBounds.width - size.width) / 2,
                        y: (pageBounds.height - size.height) / 2
                    )
                    
                    image.draw(in: CGRect(origin: origin, size: size))
                }
            }
            
            try pdfData.write(to: pdfURL, options: .atomic)
            savedPDFURL = pdfURL
            
            let recognizedText = try pages
                .map { try TextRecognizer.recognizeText(in: $0) }
                .joined(separator: "\n\n")
            
            let suggestedTitle = recognizedText
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
            
            let fallbackTitle = "Scan - \(Date.now.formatted(date: .abbreviated, time: .shortened))"
            
            let document = Document(
                title: suggestedTitle ?? fallbackTitle,
                pdfFilename: filename,
                recognizedText: recognizedText
            )
            
            modelContext.insert(document)
            try modelContext.save()
        } catch {
            if let savedPDFURL {
                try? FileManager.default.removeItem(at: savedPDFURL)
            }
            
            errorMessage = "Could not save the document: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Document.self, inMemory: true)
}
