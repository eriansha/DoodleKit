//
//  DoodleViewModel.swift
//  DoodleKit
//
//  Created by Muhamad Ivan Putra Eriansya on 24/12/25.
//

import SwiftUI
import Combine

/// ViewModel for managing doodling canvas state and interactions
///
/// This class follows the MVVM pattern and serves as the central state manager
/// for the drawing canvas. It handles stroke management, undo/redo operations,
/// and coordinates with services for smoothing and export functionality.
public class DoodleViewModel: ObservableObject {

    // MARK: - Published Properties (Observable State)

    /// Array of completed drawing strokes
    @Published public var strokes: [DrawingStroke] = []

    /// The stroke currently being drawn (nil when not drawing)
    @Published public var currentStroke: DrawingStroke?

    /// Currently selected drawing tool
    @Published public var selectedTool: DoodleTool

    /// Currently selected stroke color
    @Published public var selectedColor: Color

    /// Currently selected stroke width
    @Published public var strokeWidth: CGFloat

    /// Whether undo operation is available
    @Published public var canUndo: Bool = false

    /// Whether redo operation is available
    @Published public var canRedo: Bool = false

    // MARK: - Private Properties

    /// Stack of strokes for undo operation (not used in current implementation)
    private var undoStack: [DrawingStroke] = []

    /// Stack of strokes for redo operation
    private var redoStack: [DrawingStroke] = []

    /// Configuration settings for the doodle canvas
    private let configuration: DoodleConfiguration

    /// Service for smoothing stroke points
    private let smoothingService: StrokeSmoothingService

    // MARK: - Initialization

    /// Initialize the ViewModel with a configuration
    /// - Parameter configuration: The doodle configuration (defaults to .full preset)
    public init(configuration: DoodleConfiguration = .full) {
        self.configuration = configuration
        self.selectedTool = configuration.defaultTool
        self.selectedColor = configuration.defaultColor
        self.strokeWidth = configuration.defaultStrokeWidth
        self.smoothingService = StrokeSmoothingService(
            smoothingLevel: configuration.smoothingLevel
        )
    }

    // MARK: - Drawing Actions

    /// Start a new stroke at the given point
    /// - Parameter point: The starting location for the stroke
    public func startStroke(at point: CGPoint) {
        let drawingPoint = DrawingPoint(
            location: point,
            timestamp: Date().timeIntervalSince1970,
            pressure: 1.0, // Constant for finger drawing
            isEstimated: false
        )

        currentStroke = DrawingStroke(
            points: [drawingPoint],
            tool: selectedTool,
            color: selectedColor,
            width: strokeWidth
        )
    }

    /// Add a point to the current stroke
    /// - Parameter point: The point location to add
    public func addPoint(_ point: CGPoint) {
        guard var stroke = currentStroke else { return }

        let drawingPoint = DrawingPoint(
            location: point,
            timestamp: Date().timeIntervalSince1970,
            pressure: 1.0,
            isEstimated: false
        )

        // Only add if minimum distance reached (reduces point count and improves performance)
        if let lastPoint = stroke.points.last {
            let distance = drawingPoint.distance(to: lastPoint)
            guard distance >= configuration.minimumStrokeDistance else { return }
        }

        stroke.addPoint(drawingPoint)
        currentStroke = stroke
    }

    /// End the current stroke and save it
    public func endStroke() {
        guard var stroke = currentStroke else { return }

        // Apply smoothing before saving
        stroke.points = smoothingService.smooth(points: stroke.points)

        strokes.append(stroke)
        currentStroke = nil

        // Update undo/redo state
        undoStack.append(stroke)
        redoStack.removeAll()
        updateUndoRedoState()
    }

    // MARK: - Undo/Redo

    /// Undo the last stroke
    public func undo() {
        guard let lastStroke = strokes.popLast() else { return }
        redoStack.append(lastStroke)
        updateUndoRedoState()
    }

    /// Redo the last undone stroke
    public func redo() {
        guard let strokeToRedo = redoStack.popLast() else { return }
        strokes.append(strokeToRedo)
        updateUndoRedoState()
    }

    /// Update the undo/redo availability flags
    private func updateUndoRedoState() {
        canUndo = !strokes.isEmpty
        canRedo = !redoStack.isEmpty
    }

    // MARK: - Canvas Actions

    /// Clear all strokes from the canvas
    public func clear() {
        strokes.removeAll()
        currentStroke = nil
        undoStack.removeAll()
        redoStack.removeAll()
        updateUndoRedoState()
    }

    // MARK: - Export

    /// Export the current canvas as an image
    /// - Parameter size: The size of the output image
    /// - Returns: DoodleResult containing image data and metadata, or nil if export fails
    public func exportImage(size: CGSize) -> DoodleResult? {
        let exportService = ExportService(configuration: configuration)
        return exportService.generateResult(
            strokes: strokes,
            size: size
        )
    }

    // MARK: - Public Configuration Access

    /// Expose configuration for views to access
    public var doodleConfiguration: DoodleConfiguration {
        return configuration
    }
}
