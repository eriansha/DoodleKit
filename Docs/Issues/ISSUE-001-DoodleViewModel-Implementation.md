# ISSUE-001: DoodleViewModel Implementation

**Phase**: 1 - Core ViewModel & State Management
**Priority**: HIGH
**Component**: ViewModels/DoodleViewModel.swift
**Status**: Open
**Created**: 2025-12-24

## Overview

Implement the core DoodleViewModel class that serves as the central state manager for the drawing canvas using the MVVM pattern. This ViewModel will manage drawing state, handle user interactions, and coordinate between the UI and business logic layers.

## Dependencies

- ✓ DrawingPoint model (completed)
- ✓ DrawingStroke model (completed)
- ✓ DoodleTool model (completed)
- ✓ DoodleConfiguration model (completed)
- ⏳ StrokeSmoothingService (to be implemented concurrently)
- ⏳ ExportService (Phase 4, not blocking)

## Requirements (EARS Notation)

### Ubiquitous Requirements

**REQ-VM-001**: The DoodleViewModel shall inherit from ObservableObject to enable SwiftUI reactive updates.

**REQ-VM-002**: The DoodleViewModel shall maintain a published array of completed DrawingStroke objects.

**REQ-VM-003**: The DoodleViewModel shall maintain a published optional DrawingStroke representing the stroke currently being drawn.

**REQ-VM-004**: The DoodleViewModel shall maintain a published DoodleTool representing the currently selected drawing tool.

**REQ-VM-005**: The DoodleViewModel shall maintain a published Color representing the currently selected stroke color.

**REQ-VM-006**: The DoodleViewModel shall maintain a published CGFloat representing the currently selected stroke width.

**REQ-VM-007**: The DoodleViewModel shall maintain published Boolean flags indicating whether undo and redo operations are available.

**REQ-VM-008**: The DoodleViewModel shall initialize with a DoodleConfiguration parameter that defaults to .full preset.

**REQ-VM-009**: The DoodleViewModel shall set initial tool, color, and stroke width values from the provided configuration.

**REQ-VM-010**: The DoodleViewModel shall maintain private undo and redo stacks for managing drawing history.

### Event-Driven Requirements

**REQ-VM-E001**: WHEN startStroke(at:) is called, the DoodleViewModel shall create a new DrawingPoint with the provided location, current timestamp, constant pressure of 1.0, and isEstimated set to false.

**REQ-VM-E002**: WHEN startStroke(at:) is called, the DoodleViewModel shall create a new DrawingStroke with the created point, current tool, current color, and current stroke width.

**REQ-VM-E003**: WHEN startStroke(at:) is called, the DoodleViewModel shall assign the new stroke to currentStroke property.

**REQ-VM-E004**: WHEN addPoint(_:) is called AND currentStroke is nil, the DoodleViewModel shall return early without performing any action.

**REQ-VM-E005**: WHEN addPoint(_:) is called AND currentStroke exists, the DoodleViewModel shall create a new DrawingPoint with the provided location, current timestamp, constant pressure of 1.0, and isEstimated set to false.

**REQ-VM-E006**: WHEN addPoint(_:) is called AND the distance from the last point is less than configuration.minimumStrokeDistance, the DoodleViewModel shall skip adding the point to optimize performance.

**REQ-VM-E007**: WHEN addPoint(_:) is called AND the distance requirement is met, the DoodleViewModel shall add the new point to the current stroke.

**REQ-VM-E008**: WHEN addPoint(_:) is called AND a point is added, the DoodleViewModel shall update the currentStroke property to trigger UI updates.

**REQ-VM-E009**: WHEN endStroke() is called AND currentStroke is nil, the DoodleViewModel shall return early without performing any action.

**REQ-VM-E010**: WHEN endStroke() is called AND currentStroke exists, the DoodleViewModel shall apply smoothing to the stroke points using StrokeSmoothingService.

**REQ-VM-E011**: WHEN endStroke() is called AND smoothing is complete, the DoodleViewModel shall append the smoothed stroke to the strokes array.

**REQ-VM-E012**: WHEN endStroke() is called, the DoodleViewModel shall set currentStroke to nil.

**REQ-VM-E013**: WHEN endStroke() is called, the DoodleViewModel shall append the stroke to the undo stack.

**REQ-VM-E014**: WHEN endStroke() is called, the DoodleViewModel shall clear the redo stack.

**REQ-VM-E015**: WHEN endStroke() is called, the DoodleViewModel shall update undo/redo availability flags.

**REQ-VM-E016**: WHEN undo() is called AND strokes array is not empty, the DoodleViewModel shall remove the last stroke from the strokes array.

**REQ-VM-E017**: WHEN undo() is called AND a stroke is removed, the DoodleViewModel shall append the removed stroke to the redo stack.

**REQ-VM-E018**: WHEN undo() is called, the DoodleViewModel shall update undo/redo availability flags.

**REQ-VM-E019**: WHEN redo() is called AND redo stack is not empty, the DoodleViewModel shall remove the last stroke from the redo stack.

**REQ-VM-E020**: WHEN redo() is called AND a stroke is retrieved, the DoodleViewModel shall append the stroke to the strokes array.

**REQ-VM-E021**: WHEN redo() is called, the DoodleViewModel shall update undo/redo availability flags.

**REQ-VM-E022**: WHEN clear() is called, the DoodleViewModel shall remove all strokes from the strokes array.

**REQ-VM-E023**: WHEN clear() is called, the DoodleViewModel shall set currentStroke to nil.

**REQ-VM-E024**: WHEN clear() is called, the DoodleViewModel shall clear both undo and redo stacks.

**REQ-VM-E025**: WHEN clear() is called, the DoodleViewModel shall update undo/redo availability flags.

**REQ-VM-E026**: WHEN exportImage(size:) is called, the DoodleViewModel shall create an ExportService instance with the current configuration.

**REQ-VM-E027**: WHEN exportImage(size:) is called, the DoodleViewModel shall invoke generateResult on ExportService with current strokes and provided size.

**REQ-VM-E028**: WHEN exportImage(size:) is called, the DoodleViewModel shall return the DoodleResult or nil if export fails.

### State-Driven Requirements

**REQ-VM-S001**: WHILE strokes array is empty, the DoodleViewModel shall set canUndo to false.

**REQ-VM-S002**: WHILE strokes array is not empty, the DoodleViewModel shall set canUndo to true.

**REQ-VM-S003**: WHILE redo stack is empty, the DoodleViewModel shall set canRedo to false.

**REQ-VM-S004**: WHILE redo stack is not empty, the DoodleViewModel shall set canRedo to true.

### Unwanted Behaviors

**REQ-VM-U001**: IF addPoint(_:) is called with currentStroke being nil, THEN the DoodleViewModel shall safely return without crashing.

**REQ-VM-U002**: IF endStroke() is called with currentStroke being nil, THEN the DoodleViewModel shall safely return without crashing.

**REQ-VM-U003**: IF undo() is called when strokes array is empty, THEN the DoodleViewModel shall safely return without performing any operation.

**REQ-VM-U004**: IF redo() is called when redo stack is empty, THEN the DoodleViewModel shall safely return without performing any operation.

**REQ-VM-U005**: IF StrokeSmoothingService is not initialized, THEN the DoodleViewModel shall handle the error gracefully without crashing.

## Implementation Checklist

### File Structure
- [ ] Create `Sources/DoodleKit/ViewModels/` directory
- [ ] Create `DoodleViewModel.swift` file
- [ ] Add proper file header with copyright and creation date

### Class Definition
- [ ] Declare DoodleViewModel class with ObservableObject conformance
- [ ] Add public access modifier for library usage
- [ ] Import required frameworks (SwiftUI, Combine, Foundation)

### Properties - Published
- [ ] `@Published public var strokes: [DrawingStroke]`
- [ ] `@Published public var currentStroke: DrawingStroke?`
- [ ] `@Published public var selectedTool: DoodleTool`
- [ ] `@Published public var selectedColor: Color`
- [ ] `@Published public var strokeWidth: CGFloat`
- [ ] `@Published public var canUndo: Bool`
- [ ] `@Published public var canRedo: Bool`

### Properties - Private
- [ ] `private var undoStack: [DrawingStroke]`
- [ ] `private var redoStack: [DrawingStroke]`
- [ ] `private let configuration: DoodleConfiguration`
- [ ] `private let smoothingService: StrokeSmoothingService`

### Initialization
- [ ] Implement `init(configuration:)` with default parameter
- [ ] Initialize selectedTool from configuration.defaultTool
- [ ] Initialize selectedColor from configuration.defaultColor
- [ ] Initialize strokeWidth from configuration.defaultStrokeWidth
- [ ] Initialize smoothingService with configuration.smoothingLevel
- [ ] Initialize empty arrays for undoStack and redoStack
- [ ] Initialize canUndo and canRedo to false

### Drawing Methods
- [ ] Implement `startStroke(at:)` method
  - [ ] Create DrawingPoint with location and constant pressure
  - [ ] Create DrawingStroke with current tool/color/width
  - [ ] Assign to currentStroke
- [ ] Implement `addPoint(_:)` method
  - [ ] Guard check for currentStroke existence
  - [ ] Create new DrawingPoint
  - [ ] Check minimum distance requirement
  - [ ] Add point to stroke if distance met
  - [ ] Update currentStroke
- [ ] Implement `endStroke()` method
  - [ ] Guard check for currentStroke existence
  - [ ] Apply smoothing to points
  - [ ] Append to strokes array
  - [ ] Clear currentStroke
  - [ ] Update undo stack
  - [ ] Clear redo stack
  - [ ] Update undo/redo state

### Undo/Redo Methods
- [ ] Implement `undo()` method
  - [ ] Pop last stroke from strokes array
  - [ ] Push to redo stack
  - [ ] Update state flags
- [ ] Implement `redo()` method
  - [ ] Pop last stroke from redo stack
  - [ ] Push to strokes array
  - [ ] Update state flags
- [ ] Implement `updateUndoRedoState()` private method
  - [ ] Set canUndo based on strokes.isEmpty
  - [ ] Set canRedo based on redoStack.isEmpty

### Canvas Actions
- [ ] Implement `clear()` method
  - [ ] Remove all strokes
  - [ ] Clear currentStroke
  - [ ] Clear both stacks
  - [ ] Update state flags

### Export Methods
- [ ] Implement `exportImage(size:)` method
  - [ ] Create ExportService instance
  - [ ] Call generateResult
  - [ ] Return DoodleResult?

### Code Quality
- [ ] Add MARK comments for section organization
- [ ] Add inline documentation for public methods
- [ ] Add parameter documentation
- [ ] Add return value documentation
- [ ] Ensure consistent naming conventions
- [ ] Ensure proper access control (public/private)

## Acceptance Criteria

### Functionality
1. ViewModel initializes successfully with configuration
2. Starting a stroke creates a new DrawingStroke with correct properties
3. Adding points to stroke respects minimum distance threshold
4. Ending a stroke applies smoothing and updates state
5. Undo removes the last stroke and enables redo
6. Redo restores the last undone stroke
7. Clear removes all strokes and resets state
8. Export creates a valid DoodleResult

### State Management
1. canUndo is true only when strokes exist
2. canRedo is true only when redo stack has items
3. Published properties trigger SwiftUI updates
4. Redo stack clears when new stroke is added

### Error Handling
1. No crashes when calling methods with invalid state
2. Graceful handling of nil currentStroke
3. Safe array operations (no index out of bounds)

### Performance
1. Adding points to stroke completes in < 5ms
2. Smoothing operation completes in < 50ms for typical strokes
3. Memory usage remains stable during continuous drawing

## Testing Requirements

### Unit Tests to Implement
1. `testInitialization()` - Verify default values from configuration
2. `testStartStroke()` - Verify stroke creation with correct properties
3. `testAddPoint()` - Verify point addition and distance filtering
4. `testAddPointWithoutCurrentStroke()` - Verify safe handling
5. `testEndStroke()` - Verify stroke completion and state updates
6. `testUndo()` - Verify undo operation and state changes
7. `testUndoWhenEmpty()` - Verify safe handling
8. `testRedo()` - Verify redo operation
9. `testRedoWhenEmpty()` - Verify safe handling
10. `testClear()` - Verify all state is reset
11. `testUndoRedoSequence()` - Verify multiple undo/redo operations
12. `testMinimumDistanceFiltering()` - Verify point filtering logic
13. `testPublishedPropertiesUpdate()` - Verify SwiftUI reactivity

## Related Issues

- ISSUE-002: StrokeSmoothingService Implementation (blocking)
- ISSUE-003: ExportService Implementation (non-blocking)
- ISSUE-004: DoodleViewModel Unit Tests

## Notes

- DoodleViewModel follows the MVVM pattern, which is the iOS standard for SwiftUI apps
- Uses ObservableObject with @Published properties for reactive UI updates
- Constant pressure (1.0) for all points since this is finger-based drawing (no Apple Pencil)
- StrokeSmoothingService must be implemented before ViewModel can be fully functional
- ExportService is required for exportImage() but not for core drawing functionality

## References

- Implementation Plan: `docs/implementation-plan.md` (Phase 1, Section 1.1)
- EARS Notation: https://alistairmavin.com/ears/
- Apple SwiftUI Documentation: ObservableObject
- Apple Combine Documentation: @Published

## Estimated Effort

- Implementation: 4-6 hours
- Unit Testing: 2-3 hours
- Code Review: 1 hour
- **Total**: 7-10 hours
