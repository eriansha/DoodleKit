# DoodleKit Implementation Plan

## Overview

DoodleKit is a shared Swift package for building Lovelee-like drawing/doodling functionality for iOS applications. The package provides a complete finger-based drawing system optimized for iPhone with customizable tools, smooth rendering, and export capabilities.

**Target Platform**: iPhone (iOS 13+)
**Input Method**: Finger touch (no Apple Pencil required)
**Architecture**: MVVM pattern with SwiftUI

## Current Status

### Completed Components
- **Data Models** (✓)
  - `DrawingPoint`: Core point data with location, timestamp, pressure, and velocity calculations
  - `DrawingStroke`: Collection of points with tool, color, and width information
  - `DoodleTool`: Enum defining available drawing tools (pen, pencil, marker, highlighter)
  - `DoodleConfiguration`: Comprehensive configuration system with presets
  - `DoodleResult`: Output structure with image, data, strokes, and metadata
  - `CodableColor`: Cross-platform color encoding/decoding support

### Known Issues to Fix
- Typo in `DrawingPoint.swift:15` - `isEtimated` should be `isEstimated`
- Typo in `DrawingPoint.swift:26` - property assignment uses wrong name
- Remove/simplify Apple Pencil-specific features (pressure sensitivity is optional for finger drawing)

## Architecture

### Package Structure
```
DoodleKit/
├── Sources/
│   └── DoodleKit/
│       ├── Models/              [✓ Completed]
│       │   ├── DrawingPoint.swift
│       │   ├── DrawingStroke.swift
│       │   ├── DoodleTool.swift
│       │   ├── DoodleConfiguration.swift
│       │   └── DoodleResult.swift
│       ├── ViewModels/          [TODO]
│       │   └── DoodleViewModel.swift
│       ├── Views/               [TODO]
│       │   ├── DoodleView.swift
│       │   ├── CanvasView.swift
│       │   ├── ToolbarView.swift
│       │   └── Components/
│       │       ├── ColorPickerView.swift
│       │       ├── ToolSelectorView.swift
│       │       └── StrokeWidthPicker.swift
│       ├── Services/            [TODO]
│       │   ├── RenderingService.swift
│       │   ├── ExportService.swift
│       │   └── StrokeSmoothingService.swift
│       └── Extensions/          [TODO]
│           ├── CGPoint+Extensions.swift
│           └── Color+Extensions.swift
├── Tests/
│   └── DoodleKitTests/
│       ├── ModelTests/          [TODO]
│       ├── ViewModelTests/      [TODO]
│       └── ServiceTests/        [TODO]
├── Examples/                    [TODO]
│   └── DoodleKitDemo/
│       └── DemoApp.swift
└── docs/
    ├── implementation-plan.md   [✓ Current Document]
    ├── api-reference.md         [TODO]
    └── integration-guide.md     [TODO]
```

## Implementation Phases

### Phase 1: Core ViewModel & State Management (Priority: HIGH)

#### 1.1 DoodleViewModel
**Purpose**: Central state manager using MVVM pattern (common iOS practice)

**Why ViewModel?**
- Standard iOS/SwiftUI pattern
- Easy to test
- Clear separation of concerns
- Familiar to iOS developers

**Implementation**:
```swift
import SwiftUI
import Combine

public class DoodleViewModel: ObservableObject {
    // MARK: - Published Properties (Observable State)
    @Published public var strokes: [DrawingStroke] = []
    @Published public var currentStroke: DrawingStroke?
    @Published public var selectedTool: DoodleTool
    @Published public var selectedColor: Color
    @Published public var strokeWidth: CGFloat
    @Published public var canUndo: Bool = false
    @Published public var canRedo: Bool = false

    // MARK: - Private Properties
    private var undoStack: [DrawingStroke] = []
    private var redoStack: [DrawingStroke] = []
    private let configuration: DoodleConfiguration
    private let smoothingService: StrokeSmoothingService

    // MARK: - Initialization
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
    public func startStroke(at point: CGPoint) {
        let drawingPoint = DrawingPoint(
            location: point,
            timestamp: Date().timeIntervalSince1970,
            pressure: 1.0, // Constant for finger
            isEstimated: false
        )

        currentStroke = DrawingStroke(
            points: [drawingPoint],
            tool: selectedTool,
            color: selectedColor,
            width: strokeWidth
        )
    }

    public func addPoint(_ point: CGPoint) {
        guard var stroke = currentStroke else { return }

        let drawingPoint = DrawingPoint(
            location: point,
            timestamp: Date().timeIntervalSince1970,
            pressure: 1.0,
            isEstimated: false
        )

        // Only add if minimum distance reached (reduces point count)
        if let lastPoint = stroke.points.last {
            let distance = drawingPoint.distance(to: lastPoint)
            guard distance >= configuration.minimumStrokeDistance else { return }
        }

        stroke.addPoint(drawingPoint)
        currentStroke = stroke
    }

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
    public func undo() {
        guard let lastStroke = strokes.popLast() else { return }
        redoStack.append(lastStroke)
        updateUndoRedoState()
    }

    public func redo() {
        guard let strokeToRedo = redoStack.popLast() else { return }
        strokes.append(strokeToRedo)
        updateUndoRedoState()
    }

    private func updateUndoRedoState() {
        canUndo = !strokes.isEmpty
        canRedo = !redoStack.isEmpty
    }

    // MARK: - Canvas Actions
    public func clear() {
        strokes.removeAll()
        currentStroke = nil
        undoStack.removeAll()
        redoStack.removeAll()
        updateUndoRedoState()
    }

    // MARK: - Export
    public func exportImage(size: CGSize) -> DoodleResult? {
        let exportService = ExportService(configuration: configuration)
        return exportService.generateResult(
            strokes: strokes,
            size: size
        )
    }
}
```

### Phase 2: Rendering Service (Priority: HIGH)

#### 2.1 RenderingService
**Purpose**: Handle stroke rendering efficiently for finger drawing

**Key Features**:
```swift
public class RenderingService {
    private let configuration: DoodleConfiguration

    public init(configuration: DoodleConfiguration) {
        self.configuration = configuration
    }

    // Render stroke to SwiftUI Path
    public func createPath(from stroke: DrawingStroke) -> Path {
        var path = Path()

        guard stroke.points.count > 1 else { return path }

        // Move to first point
        path.move(to: stroke.points[0].location)

        // Draw lines between points
        for i in 1..<stroke.points.count {
            path.addLine(to: stroke.points[i].location)
        }

        return path
    }

    // Render smoothed stroke (Catmull-Rom spline)
    public func createSmoothedPath(from stroke: DrawingStroke) -> Path {
        var path = Path()

        guard stroke.points.count > 2 else {
            return createPath(from: stroke)
        }

        let locations = stroke.points.map { $0.location }
        path.move(to: locations[0])

        for i in 0..<locations.count - 1 {
            let current = locations[i]
            let next = locations[i + 1]

            // Use quadratic curves for smoothing
            let midPoint = CGPoint(
                x: (current.x + next.x) / 2,
                y: (current.y + next.y) / 2
            )

            path.addQuadCurve(to: midPoint, control: current)
        }

        // Add final point
        if let last = locations.last {
            path.addLine(to: last)
        }

        return path
    }

    // Get stroke style for tool
    public func strokeStyle(for tool: DoodleTool, width: CGFloat) -> StrokeStyle {
        StrokeStyle(
            lineWidth: width,
            lineCap: tool.lineCapStyle == .round ? .round : .square,
            lineJoin: .round
        )
    }
}
```

#### 2.2 StrokeSmoothingService
**Purpose**: Smooth finger strokes for natural appearance

```swift
public class StrokeSmoothingService {
    private let smoothingLevel: CGFloat

    public init(smoothingLevel: CGFloat) {
        self.smoothingLevel = smoothingLevel
    }

    public func smooth(points: [DrawingPoint]) -> [DrawingPoint] {
        guard points.count > 2, smoothingLevel > 0 else {
            return points
        }

        // Simple moving average smoothing
        var smoothedPoints: [DrawingPoint] = []
        let windowSize = max(2, Int(smoothingLevel * 4))

        for i in 0..<points.count {
            let start = max(0, i - windowSize / 2)
            let end = min(points.count - 1, i + windowSize / 2)

            let window = points[start...end]
            let avgX = window.reduce(0.0) { $0 + $1.location.x } / CGFloat(window.count)
            let avgY = window.reduce(0.0) { $0 + $1.location.y } / CGFloat(window.count)

            var smoothedPoint = points[i]
            smoothedPoint = DrawingPoint(
                location: CGPoint(x: avgX, y: avgY),
                timestamp: smoothedPoint.timestamp,
                pressure: smoothedPoint.pressure,
                isEstimated: smoothedPoint.isEtimated
            )

            smoothedPoints.append(smoothedPoint)
        }

        return smoothedPoints
    }
}
```

### Phase 3: SwiftUI Views (Priority: HIGH)

#### 3.1 Main DoodleView
**Purpose**: Complete doodling interface

```swift
public struct DoodleView: View {
    @StateObject private var viewModel: DoodleViewModel
    @Environment(\.dismiss) private var dismiss

    private let onSave: (DoodleResult) -> Void

    public init(
        configuration: DoodleConfiguration = .full,
        onSave: @escaping (DoodleResult) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: DoodleViewModel(configuration: configuration))
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar at top (optional)
            if viewModel.configuration.toolbarPosition == .top {
                ToolbarView(viewModel: viewModel)
            }

            // Canvas
            CanvasView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Toolbar at bottom (default)
            if viewModel.configuration.toolbarPosition == .bottom {
                ToolbarView(viewModel: viewModel)
            }
        }
        .background(viewModel.configuration.backgroundColor)
    }

    private func handleSave() {
        // Get canvas size from screen
        let size = UIScreen.main.bounds.size

        if let result = viewModel.exportImage(size: size) {
            onSave(result)
        }
    }
}
```

#### 3.2 CanvasView
**Purpose**: Drawing surface with gesture handling

```swift
struct CanvasView: View {
    @ObservedObject var viewModel: DoodleViewModel
    private let renderingService: RenderingService

    init(viewModel: DoodleViewModel) {
        self.viewModel = viewModel
        self.renderingService = RenderingService(
            configuration: viewModel.configuration
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                viewModel.configuration.canvasBackgroundColor
                    .ignoresSafeArea()

                // Grid overlay (if enabled)
                if viewModel.configuration.showGrid {
                    GridOverlay(
                        color: viewModel.configuration.gridColor,
                        spacing: 20
                    )
                }

                // Completed strokes
                Canvas { context, size in
                    for stroke in viewModel.strokes {
                        let path = renderingService.createSmoothedPath(from: stroke)
                        let style = renderingService.strokeStyle(
                            for: stroke.tool,
                            width: stroke.width
                        )

                        context.stroke(
                            path,
                            with: .color(stroke.swiftUIColor.opacity(stroke.tool.opacity)),
                            style: style
                        )
                    }

                    // Current stroke being drawn
                    if let currentStroke = viewModel.currentStroke {
                        let path = renderingService.createSmoothedPath(from: currentStroke)
                        let style = renderingService.strokeStyle(
                            for: currentStroke.tool,
                            width: currentStroke.width
                        )

                        context.stroke(
                            path,
                            with: .color(currentStroke.swiftUIColor.opacity(currentStroke.tool.opacity)),
                            style: style
                        )
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if viewModel.currentStroke == nil {
                            viewModel.startStroke(at: value.location)
                        } else {
                            viewModel.addPoint(value.location)
                        }
                    }
                    .onEnded { _ in
                        viewModel.endStroke()
                    }
            )
        }
    }
}

struct GridOverlay: View {
    let color: Color
    let spacing: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Vertical lines
                for x in stride(from: 0, through: geometry.size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }

                // Horizontal lines
                for y in stride(from: 0, through: geometry.size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(color, lineWidth: 0.5)
        }
    }
}
```

#### 3.3 ToolbarView
**Purpose**: Tool selection and actions

```swift
struct ToolbarView: View {
    @ObservedObject var viewModel: DoodleViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Tool selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.configuration.availableTools) { tool in
                        ToolButton(
                            tool: tool,
                            isSelected: viewModel.selectedTool == tool
                        ) {
                            viewModel.selectedTool = tool
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Color picker
            ColorPickerView(
                colors: viewModel.configuration.availableColors,
                selectedColor: $viewModel.selectedColor
            )

            // Stroke width slider
            StrokeWidthPicker(
                width: $viewModel.strokeWidth,
                minWidth: viewModel.configuration.minStrokeWidth,
                maxWidth: viewModel.configuration.maxStrokeWidth,
                color: viewModel.selectedColor
            )

            // Action buttons
            HStack(spacing: 16) {
                if viewModel.configuration.showUndoButton {
                    Button(action: { viewModel.undo() }) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(!viewModel.canUndo)
                }

                if viewModel.configuration.showClearButton {
                    Button(action: { /* show confirmation */ }) {
                        Text(viewModel.configuration.clearButtonTitle)
                    }
                }

                if viewModel.configuration.showSaveButton {
                    Button(action: { /* handle save */ }) {
                        Text(viewModel.configuration.saveButtonTitle)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.95))
    }
}

struct ToolButton: View {
    let tool: DoodleTool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tool.iconName)
                    .font(.title3)
                Text(tool.displayName)
                    .font(.caption)
            }
            .frame(width: 60, height: 60)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### Phase 4: Export Service (Priority: MEDIUM)

#### 4.1 ExportService
**Purpose**: Generate images from strokes

```swift
public class ExportService {
    private let configuration: DoodleConfiguration

    public init(configuration: DoodleConfiguration) {
        self.configuration = configuration
    }

    public func generateResult(
        strokes: [DrawingStroke],
        size: CGSize
    ) -> DoodleResult? {
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
    }

    private func renderImage(strokes: [DrawingStroke], size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Fill background
            UIColor(configuration.canvasBackgroundColor).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Render each stroke
            let renderingService = RenderingService(configuration: configuration)

            for stroke in strokes {
                let path = renderingService.createSmoothedPath(from: stroke)
                let style = renderingService.strokeStyle(for: stroke.tool, width: stroke.width)

                // Convert to UIBezierPath for rendering
                let uiPath = UIBezierPath(cgPath: path.cgPath)

                UIColor(stroke.swiftUIColor.opacity(stroke.tool.opacity)).setStroke()
                uiPath.lineWidth = style.lineWidth
                uiPath.lineCapStyle = stroke.tool.lineCapStyle
                uiPath.lineJoinStyle = .round
                uiPath.stroke()
            }
        }
    }

    private func generateImageData(image: UIImage) -> Data? {
        switch configuration.exportFormat {
        case .png:
            return image.pngData()
        case .jpeg(let quality):
            return image.jpegData(compressionQuality: quality)
        }
    }

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
```

### Phase 5: Additional Features (Priority: LOW)

#### 5.1 Eraser Tool
- Add `.eraser` case to `DoodleTool` enum
- Implement stroke intersection detection
- Remove intersecting strokes when eraser is used

#### 5.2 Stroke Persistence
- Save/load drawings as JSON
- Auto-save functionality
- Recovery from crashes

#### 5.3 Share Sheet Integration
- Export to Photos
- Share via Messages, Mail, etc.
- Copy to clipboard

#### 5.4 Haptic Feedback
- Vibration on tool change
- Feedback on undo/clear
- Configurable intensity

## Testing Strategy

### Unit Tests
```swift
class DoodleViewModelTests: XCTestCase {
    var viewModel: DoodleViewModel!

    override func setUp() {
        super.setUp()
        viewModel = DoodleViewModel(configuration: .simple)
    }

    func testStartStroke() {
        viewModel.startStroke(at: CGPoint(x: 10, y: 10))
        XCTAssertNotNil(viewModel.currentStroke)
        XCTAssertEqual(viewModel.currentStroke?.points.count, 1)
    }

    func testUndoRedo() {
        // Create a stroke
        viewModel.startStroke(at: CGPoint(x: 10, y: 10))
        viewModel.addPoint(CGPoint(x: 20, y: 20))
        viewModel.endStroke()

        XCTAssertEqual(viewModel.strokes.count, 1)
        XCTAssertTrue(viewModel.canUndo)

        viewModel.undo()
        XCTAssertEqual(viewModel.strokes.count, 0)
        XCTAssertTrue(viewModel.canRedo)

        viewModel.redo()
        XCTAssertEqual(viewModel.strokes.count, 1)
    }

    func testClear() {
        viewModel.startStroke(at: CGPoint(x: 10, y: 10))
        viewModel.endStroke()

        viewModel.clear()
        XCTAssertEqual(viewModel.strokes.count, 0)
        XCTAssertFalse(viewModel.canUndo)
    }
}
```

### Performance Tests
- Measure rendering time for 1000+ points
- Memory usage with large drawings
- Touch response latency

## Integration Example

### Basic Usage
```swift
import SwiftUI
import DoodleKit

struct ContentView: View {
    @State private var showDoodle = false
    @State private var savedImage: UIImage?

    var body: some View {
        VStack {
            if let image = savedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }

            Button("Start Drawing") {
                showDoodle = true
            }
        }
        .fullScreenCover(isPresented: $showDoodle) {
            DoodleView(configuration: .kidFriendly) { result in
                savedImage = result.image
                showDoodle = false
            }
        }
    }
}
```

### Custom Configuration
```swift
let customConfig = DoodleConfiguration(
    availableTools: [.pen, .marker],
    defaultTool: .pen,
    availableColors: [.black, .blue, .red, .green],
    defaultColor: .black,
    backgroundColor: .white,
    canvasBackgroundColor: Color(.systemGray6),
    defaultStrokeWidth: 4,
    minStrokeWidth: 2,
    maxStrokeWidth: 15,
    smoothingLevel: 0.6,
    toolbarPosition: .bottom,
    showClearButton: true,
    confirmBeforeClear: true
)

DoodleView(configuration: customConfig) { result in
    // Save result
}
```

## Development Roadmap

### Version 1.0.0 (MVP)
- ✓ Core data models
- DoodleViewModel with state management
- CanvasView with finger drawing
- Basic rendering (smooth paths)
- Tool selection (pen, pencil, marker, highlighter)
- Color picker
- Stroke width adjustment
- Undo functionality
- Clear canvas
- PNG export
- Basic UI components

### Version 1.1.0
- Eraser tool
- Redo functionality
- Stroke persistence (save/load)
- Share sheet integration
- Haptic feedback
- Performance optimizations

### Version 1.2.0
- Background images
- Grid overlay options
- Custom stroke styles
- JPEG export
- Dark mode support
- Accessibility improvements

## Success Criteria

1. **Usability**: Developer can integrate in < 30 minutes
2. **Performance**: Smooth 60 FPS drawing on iPhone 8+
3. **Quality**: Natural-looking strokes with finger input
4. **Reliability**: No crashes during normal use
5. **Documentation**: Complete API docs and examples

## Next Steps

1. **Fix existing typos** in model files
2. **Implement DoodleViewModel** with basic state management
3. **Build CanvasView** with DragGesture handling
4. **Create RenderingService** for smooth path generation
5. **Develop UI components** (toolbar, color picker, etc.)
6. **Add export functionality** (PNG/JPEG)
7. **Write unit tests** for ViewModel
8. **Create demo app** showcasing integration

## Notes

- **No Apple Pencil**: Simplified touch handling, constant pressure
- **iPhone optimized**: Larger touch targets, clear UI
- **MVVM pattern**: Industry standard, easy to understand
- **SwiftUI native**: Modern iOS development approach
