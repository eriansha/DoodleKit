//
//  DrawingStroke.swift
//  DoodleKit
//
//  Created by Muhamad Ivan Putra Eriansya on 24/12/25.
//
import Foundation
import SwiftUI

public struct DrawingStroke: Identifiable, Codable, Equatable {
    public let id: UUID
    public var points: [DrawingPoint]
    public let tool: DoodleTool
    public let color: CodableColor
    public let width: CGFloat
    public let timestamp: Date
    
    @available(macOS 10.15, *)
    public init(
        id: UUID = UUID(),
        points: [DrawingPoint] = [],
        tool: DoodleTool,
        color: Color,
        width: CGFloat,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.points = points
        self.tool = tool
        self.color = CodableColor(color: color)
        self.width = width
        self.timestamp = timestamp
    }
    
    public var isEmpty: Bool {
        points.isEmpty
    }
    
    public var bounds: CGRect {
        guard !points.isEmpty else { return .zero }
        
        let xs = points.map { $0.location.x }
        let ys = points.map { $0.location.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    @available(macOS 10.15, *)
    public var swiftUIColor: Color {
        color.toColor()
    }
    
    public mutating func addPoint(_ point: DrawingPoint) {
        points.append(point)
    }
}

@available(macOS 10.15, *)
public struct CodableColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    @available(macOS 10.15, *)
    public init(color: Color) {
        #if canImport(UIKit)
        let platformColor = UIColor(color)
        #elseif canImport(AppKit)
        let platformColor = NSColor(color)
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        platformColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }

    public func toColor() -> Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}
