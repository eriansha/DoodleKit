//
//  DrawingPoint.swift
//  DoodleKit
//
//  Created by Muhamad Ivan Putra Eriansya on 24/12/25.
//

import Foundation
import CoreGraphics

public struct DrawingPoint: Codable, Equatable {
    public let location: CGPoint
    public let timestamp: TimeInterval
    public let pressure: CGFloat
    public let isEtimated: Bool
    
    public init(
        location: CGPoint,
        timestamp: TimeInterval = Date().timeIntervalSince1970,
        pressure: CGFloat = 1.0,
        isEstimated: Bool = false
    ) {
        self.location = location
        self.timestamp = timestamp
        self.pressure = pressure
        self.isEtimated = isEstimated
    }
    
    /** Using Pythagoras Theorem to calculate distance betwen two points */
    public func distance(to other: DrawingPoint) -> CGFloat {
        let dx = location.x - other.location.x
        let dy = location.y - other.location.y
        return sqrt(dx * dx + dy * dy)
    }
    
    public func velocity(from previous: DrawingPoint) -> CGFloat {
        let distance = self.distance(to: previous)
        let timeDelta = timestamp - previous.timestamp
        return timeDelta > 0 ? distance / CGFloat(timeDelta) : 0
    }
}
