//
//  DoodleResult.swift
//  DoodleKit
//
//  Created by Muhamad Ivan Putra Eriansya on 24/12/25.
//

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

import Foundation

public struct DoodleResult {
    public let image: PlatformImage
    public let imageData: Data
    public let strokes: [DrawingStroke]
    public let metadata: DoodleMetadata
    
    public init(
        image: PlatformImage,
        imageData: Data,
        strokes: [DrawingStroke],
        metadata: DoodleMetadata
    ) {
        self.image = image
        self.imageData = imageData
        self.strokes = strokes
        self.metadata = metadata
    }
    
    public struct DoodleMetadata {
        public let timestamp: Date
        public let bounds: CGRect
        public let strokeCount: Int
        public let pointCount: Int
        public let fileSize: Int
        public let format: String
        
        public init(
            timestamp: Date = Date(),
            bounds: CGRect,
            strokeCount: Int,
            pointCount: Int,
            fileSize: Int,
            format: String
        ) {
            self.timestamp = timestamp
            self.bounds = bounds
            self.strokeCount = strokeCount
            self.pointCount = pointCount
            self.fileSize = fileSize
            self.format = format
        }
    }
}

