//
//  DoodleConfiguration.swift
//  DoodleKit
//
//  Created by Muhamad Ivan Putra Eriansya on 24/12/25.
//

import SwiftUI

public struct DoodleConfiguration : Sendable{
    // MARK: Tool Settings
    public let availableTools: [DoodleTool]
    public let defaultTool: DoodleTool
    public let allowEraser: Bool
    public let allowUndo: Bool
    
    // MARK: Color Settings
    public let availableColors: [Color]
    public let defaultColor: Color
    public let allowColorPicker: Bool
    
    // MARK: Canvas Settings
    public let backgroundColor: Color
    public let canvasBackgroundColor: Color
    public let showGrid: Bool
    public let gridColor: Color
    
    // MARK: Storke Settings
    public let defaultStrokeWidth: CGFloat
    public let minStrokeWidth: CGFloat
    public let maxStrokeWidth: CGFloat
    
    // MARK: Touch Settings
    public let touchSensitivity: CGFloat
    public let smoothingLevel: CGFloat
    public let minimumStrokeDistance: CGFloat
    public let palmRejectionRadius: CGFloat
    
    // MARK: - Export Settings
    public let exportFormat: ExportFormat
    public let exportQuality: CGFloat
    public let maxExportSize: CGSize?
    
    // MARK: - UI Customization
    public let toolbarPosition: ToolbarPosition
    public let showSaveButton: Bool
    public let showClearButton: Bool
    public let showUndoButton: Bool
    public let saveButtonTitle: String
    public let clearButtonTitle: String
    
    // MARK: - Behavior
    public let confirmBeforeClear: Bool
    public let confirmBeforeCancel: Bool
    public let hapticFeedback: Bool
    public let renderQuality: RenderQuality
    public let maxPointsPerStroke: Int
    
    // MARK: - Initialization
    public init(
        availableTools: [DoodleTool] = DoodleTool.allCases,
        defaultTool: DoodleTool = .pen,
        allowEraser: Bool = true,
        allowUndo: Bool = true,
        availableColors: [Color] = [.black, .red, .blue, .green, .purple, .orange, .pink, .yellow],
        defaultColor: Color = .black,
        allowColorPicker: Bool = false,
        backgroundColor: Color = .white,
        canvasBackgroundColor: Color = .white,
        showGrid: Bool = false,
        gridColor: Color = .gray.opacity(0.3),
        defaultStrokeWidth: CGFloat = 3,
        minStrokeWidth: CGFloat = 1,
        maxStrokeWidth: CGFloat = 20,
        touchSensitivity: CGFloat = 1.0,
        smoothingLevel: CGFloat = 0.5,
        minimumStrokeDistance: CGFloat = 2,
        palmRejectionRadius: CGFloat = 50,
        exportFormat: ExportFormat = .png,
        exportQuality: CGFloat = 1.0,
        maxExportSize: CGSize? = nil,
        toolbarPosition: ToolbarPosition = .bottom,
        showSaveButton: Bool = true,
        showClearButton: Bool = true,
        showUndoButton: Bool = true,
        saveButtonTitle: String = "Save",
        clearButtonTitle: String = "Clear",
        confirmBeforeClear: Bool = true,
        confirmBeforeCancel: Bool = false,
        hapticFeedback: Bool = true,
        renderQuality: RenderQuality = .high,
        maxPointsPerStroke: Int = 10000
    ) {
        self.availableTools = availableTools
        self.defaultTool = defaultTool
        self.allowEraser = allowEraser
        self.allowUndo = allowUndo
        self.availableColors = availableColors
        self.defaultColor = defaultColor
        self.allowColorPicker = allowColorPicker
        self.backgroundColor = backgroundColor
        self.canvasBackgroundColor = canvasBackgroundColor
        self.showGrid = showGrid
        self.gridColor = gridColor
        self.defaultStrokeWidth = defaultStrokeWidth
        self.minStrokeWidth = minStrokeWidth
        self.maxStrokeWidth = maxStrokeWidth
        self.touchSensitivity = touchSensitivity
        self.smoothingLevel = smoothingLevel
        self.minimumStrokeDistance = minimumStrokeDistance
        self.palmRejectionRadius = palmRejectionRadius
        self.exportFormat = exportFormat
        self.exportQuality = exportQuality
        self.maxExportSize = maxExportSize
        self.toolbarPosition = toolbarPosition
        self.showSaveButton = showSaveButton
        self.showClearButton = showClearButton
        self.showUndoButton = showUndoButton
        self.saveButtonTitle = saveButtonTitle
        self.clearButtonTitle = clearButtonTitle
        self.confirmBeforeClear = confirmBeforeClear
        self.confirmBeforeCancel = confirmBeforeCancel
        self.hapticFeedback = hapticFeedback
        self.renderQuality = renderQuality
        self.maxPointsPerStroke = maxPointsPerStroke
    }
    
    // MARK: Presents
    public static let minimal = DoodleConfiguration(
        availableTools: [.pen],
        allowEraser: false,
        availableColors: [.black],
        allowColorPicker: false,
        showClearButton: false,
        confirmBeforeClear: false
    )
    
    public static let full = DoodleConfiguration()
    
    public static let kidFriendly = DoodleConfiguration(
         availableTools: [.marker],
         availableColors: [.red, .blue, .green, .yellow, .purple, .orange, .pink],
         defaultStrokeWidth: 8,
         smoothingLevel: 0.7,
         confirmBeforeClear: true,
         hapticFeedback: true
     )
     
     public static let simple = DoodleConfiguration(
         availableTools: [.pen, .marker],
         allowEraser: true,
         availableColors: [.black, .red, .blue],
         showClearButton: true,
         confirmBeforeClear: false
     )
}

// MARK: - Supporting Types
public enum ExportFormat: Sendable {
    case png
    case jpeg(quality: CGFloat)
    
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }
}

public enum ToolbarPosition: Sendable {
    case top
    case bottom
    case hidden
}

public enum RenderQuality : Sendable{
    case low
    case medium
    case high
    
    var scale: CGFloat {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 3.0
        }
    }
}
