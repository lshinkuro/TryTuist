//
//  VisionTextRecognizer.swift
//  HomeFeature · Data
//
//  OCR on-device (Vision), tidak butuh Apple Intelligence.
//
import UIKit
import Vision

struct VisionTextRecognizer: TextRecognizer {
    func recognizeText(in imageData: Data) async -> String? {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else { return nil }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.automaticallyDetectsLanguage = true
                try? VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])
                let lines = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
                continuation.resume(returning: lines.isEmpty ? nil : lines.joined(separator: "\n"))
            }
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
