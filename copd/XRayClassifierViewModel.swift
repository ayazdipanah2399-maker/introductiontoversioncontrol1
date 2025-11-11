//
//  XRayClassifierViewModel.swift
//  copd
//
//  Created by alireza yazdipanah on 11/11/25.
//

import Foundation
import SwiftUI
import Vision
import CoreML

@MainActor
final class XRayClassifierViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var resultText: String = "No prediction yet"
    @Published var confidence: Double = 0
    @Published var isLoading: Bool = false

    private var vnModel: VNCoreMLModel?

    init() {
        // Load VN model once
        do {
            let config = MLModelConfiguration()
            // Prefer Neural Engine when available
            config.computeUnits = .all
            let coreMLModel = try ChestXRayClassifier(configuration: config).model
            self.vnModel = try VNCoreMLModel(for: coreMLModel)
        } catch {
            print("Model load error: \(error)")
            self.resultText = "Model failed to load"
        }
    }

    func classify(_ uiImage: UIImage?) {
        guard let uiImage, let cgImage = uiImage.cgImage else {
            self.resultText = "No image selected"
            return
        }
        guard let vnModel else {
            self.resultText = "Model not ready"
            return
        }

        isLoading = true
        resultText = "Analyzing..."
        confidence = 0

        // Vision request
        let request = VNCoreMLRequest(model: vnModel) { [weak self] req, _ in
            Task { @MainActor in
                self?.handle(request: req)
            }
        }
        // Center-crop square for many image classifiers (Vision handles resize)
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: uiImage.cgImageOrientation, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                Task { @MainActor in
                    self.resultText = "Prediction failed"
                    self.isLoading = false
                }
            }
        }
    }

    private func handle(request: VNRequest) {
        defer { isLoading = false }
        guard let results = request.results as? [VNClassificationObservation],
              let top = results.first else {
            resultText = "No result"
            return
        }
        // Map labels to display text (match your class names exactly)
        let label = top.identifier.lowercased()
        let pct = Double(top.confidence)
        confidence = pct

        if label.contains("abnormal") || label.contains("abn") || label == "abnormal" {
            resultText = "Abnormal (\(formatPct(pct)))"
        } else if label.contains("normal") {
            resultText = "Normal (\(formatPct(pct)))"
        } else {
            resultText = "\(top.identifier) (\(formatPct(pct)))"
        }
    }

    private func formatPct(_ v: Double) -> String {
        String(format: "%.1f%%", v * 100.0)
    }

    func clear() {
        image = nil
        resultText = "No prediction yet"
        confidence = 0
    }
}

// Helper: bridge UIImageOrientation to CGImagePropertyOrientation
extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
