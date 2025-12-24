//
//  ExportService.swift
//  DoodleKit
//
//  Created by Muhamad Ivan Putra Eriansya on 24/12/25.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import Foundation
import SwiftUI

/// Service responsible for exporting drawings to various image formats
///
/// This service renders strokes to images and generates DoodleResult
/// objects containing image data and metadata.
public class ExportService {

    // MARK: - Properties

    private let configuration: DoodleConfiguration

    // MARK: - Initialization

    /// Initialize the export service with configuration
    /// - Parameter configuration: The doodle configuration
    public init(configuration: DoodleConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Public Methods

    /// Generate a complete result from drawing strokes
    /// - Parameters:
    ///   - strokes: The strokes to export
    ///   - size: The size of the output image
    /// - Returns: DoodleResult containing image and metadata, or nil if export fails
    public func generateResult(
        strokes: [DrawingStroke],
        size: CGSize
    ) -> DoodleResult? {
        #if canImport(UIKit)
        guard let image = renderImage(strokes: strokes, size: size),
              let imageData = generateImageData(image: image) else {
            return nil
        }

        let metadata = DoodleResult.DoodleMetadata(
            timestamp: Date(),
            bounds: calculateBounds(strokes: strokes),
            strokeCount: strokes.count,
            pointCount: strokes.reduce(0) { $0 + $1.points.count },
            fileSize: imageData.count,
            format: configuration.exportFormat.fileExtension
        )

        return DoodleResult(
            image: image,
            imageData: imageData,
            strokes: strokes,
            metadata: metadata
        )
        #else
        // macOS support placeholder
        return nil
        #endif
    }

    // MARK: - Private Methods

    #if canImport(UIKit)
    private func renderImage(strokes: [DrawingStroke], size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Fill background
            UIColor(configuration.canvasBackgroundColor).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Render each stroke
            for stroke in strokes {
                let path = createPath(from: stroke)

                UIColor(stroke.swiftUIColor.opacity(stroke.tool.opacity)).setStroke()
                path.lineWidth = stroke.width
                path.lineCapStyle = stroke.tool.lineCapStyle
                path.lineJoinStyle = .round
                path.stroke()
            }
        }
    }

    private func createPath(from stroke: DrawingStroke) -> UIBezierPath {
        let path = UIBezierPath()

        guard stroke.points.count > 1 else { return path }

        // Move to first point
        path.move(to: stroke.points[0].location)

        // Create smooth curves between points
        for i in 1..<stroke.points.count {
            let current = stroke.points[i - 1].location
            let next = stroke.points[i].location

            // Use quadratic curves for smoothing
            let midPoint = CGPoint(
                x: (current.x + next.x) / 2,
                y: (current.y + next.y) / 2
            )

            if i == 1 {
                path.addLine(to: midPoint)
            } else {
                path.addQuadCurve(to: midPoint, controlPoint: current)
            }
        }

        // Add final point
        if let last = stroke.points.last?.location {
            path.addLine(to: last)
        }

        return path
    }

    private func generateImageData(image: UIImage) -> Data? {
        switch configuration.exportFormat {
        case .png:
            return image.pngData()
        case .jpeg(let quality):
            return image.jpegData(compressionQuality: quality)
        }
    }
    #endif

    private func calculateBounds(strokes: [DrawingStroke]) -> CGRect {
        guard !strokes.isEmpty else { return .zero }

        let bounds = strokes.map { $0.bounds }
        let minX = bounds.map { $0.minX }.min() ?? 0
        let minY = bounds.map { $0.minY }.min() ?? 0
        let maxX = bounds.map { $0.maxX }.max() ?? 0
        let maxY = bounds.map { $0.maxY }.max() ?? 0

        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
}
