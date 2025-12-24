//
//  DrawingTool.swift
//  DoodleKit
//
//  Created by Muhamad Ivan Putra Eriansya on 24/12/25.
//

import Foundation
import CoreGraphics

public enum DoodleTool: String, Codable, CaseIterable, Identifiable, Sendable {
    case pen
    case pencil
    case marker
    case highlighter
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .pen: return "pencil.tip"
        case .pencil: return "pencil"
        case .marker: return "highlighter"
        case .highlighter: return "paintbrush.fill"
        }
    }
    
    public var displayName: String {
        rawValue.capitalized
    }
    
    public var opacity: Double {
        switch self {
        case .pen: return 1.0
        case .pencil: return 0.8
        case .marker: return 0.7
        case .highlighter: return 0.3
        }
    }
    
    public var lineCapStyle: CGLineCap {
        switch self {
        case .pen: return .round
        case .pencil: return .round
        case .marker: return .round
        case .highlighter: return .butt
        }
    }
}
