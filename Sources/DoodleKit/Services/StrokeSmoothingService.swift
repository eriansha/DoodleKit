//
//  StrokeSmoothingService.swift
//  DoodleKit
//
//  Created by Muhamad Ivan Putra Eriansya on 24/12/25.
//

import Foundation
import CoreGraphics

/// Service responsible for smoothing drawing strokes to create natural-looking lines
///
/// This service applies a moving average algorithm to raw touch points,
/// resulting in smoother, more fluid strokes. Optimized for finger-based drawing.
public class StrokeSmoothingService {

    // MARK: - Properties

    /// The level of smoothing to apply (0.0 = no smoothing, 1.0 = maximum smoothing)
    private let smoothingLevel: CGFloat

    // MARK: - Initialization

    /// Initialize the smoothing service with a specified smoothing level
    /// - Parameter smoothingLevel: The smoothing intensity (0.0 to 1.0)
    public init(smoothingLevel: CGFloat) {
        self.smoothingLevel = smoothingLevel
    }

    // MARK: - Public Methods

    /// Apply smoothing to an array of drawing points
    ///
    /// Uses a moving average window to smooth the point locations while
    /// preserving original metadata (timestamp, pressure, isEstimated).
    ///
    /// - Parameter points: The raw drawing points to smooth
    /// - Returns: Smoothed array of drawing points (same count as input)
    public func smooth(points: [DrawingPoint]) -> [DrawingPoint] {
        // Return early if smoothing not needed
        guard points.count > 2, smoothingLevel > 0 else {
            return points
        }

        // Calculate window size based on smoothing level
        // Higher smoothing level = larger window
        let windowSize = max(2, Int(smoothingLevel * 4))

        var smoothedPoints: [DrawingPoint] = []

        // Process each point with moving average
        for i in 0..<points.count {
            // Calculate window boundaries (clamped to valid indices)
            let start = max(0, i - windowSize / 2)
            let end = min(points.count - 1, i + windowSize / 2)

            // Extract window of points
            let window = points[start...end]

            // Calculate average position
            let avgX = window.reduce(0.0) { $0 + $1.location.x } / CGFloat(window.count)
            let avgY = window.reduce(0.0) { $0 + $1.location.y } / CGFloat(window.count)

            // Create smoothed point with original metadata
            let smoothedPoint = DrawingPoint(
                location: CGPoint(x: avgX, y: avgY),
                timestamp: points[i].timestamp,
                pressure: points[i].pressure,
                isEstimated: points[i].isEstimated
            )

            smoothedPoints.append(smoothedPoint)
        }

        return smoothedPoints
    }
}
