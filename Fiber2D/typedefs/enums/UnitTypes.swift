//
//  UnitTypes.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 29.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

/** Scale types alter how a node's scale property values are interpreted. Used by, for instance, [Node setScaleType:]. */
public enum ScaleType {
    /** Scale is assumed to be in points */
    case points,
    /** Scale is assumed to be in UI points */
    scaled
}

/** Position unit types alter how a node's position property values are interpreted. Used by, for instance, Node.positionType */
public enum PositionUnit {
    /// Position is set in points (this is the default)
    case points,
    /// Position is UI points, on iOS this corresponds to the native point system
    uiPoints,
    
    /// Position is a normalized value multiplied by the content size of the parent's container
    normalized
}

/** Size unit types alter how a node's contentSize property values are interpreted. Used by, for instance, Node.contentSizeType */
public enum SizeUnit {
    /// Content size is set in points (this is the default)
    case points,
    
    /// Position is UI points, on iOS this corresponds to the native point system
    uiPoints,
    
    /// Content size is a normalized value (percentage) multiplied by the content size of the parent's container
    normalized,
    
    /// Content size is the size of the parents container inset by the supplied value
    insetPoints,
    
    /// Content size is the size of the parents container inset by the supplied value multiplied by the UIScaleFactor (as defined by Director)
    insetUIPoints
}

/** Reference corner determines a node's origin and affects how the position property values are interpreted. Used by, for instance, Node.positionType. */
public enum PositionReferencePoint {
    /// Position is relative to the bottom left corner of the parent container (this is the default)
    case bottomLeft,
    
    /// Position is relative to the top left corner of the parent container
    topLeft,
    
    /// Position is relative to the top right corner of the parent container
    topRight,
    
    /// Position is relative to the bottom right corner of the parent container
    bottomRight
}

/** Position type compines PositionUnit and PositionReferenceCorner. */
public struct PositionType {
    public let xUnit: PositionUnit
    public let yUnit: PositionUnit
    public let corner: PositionReferencePoint
    
    public var isBasicPoints: Bool {
        return xUnit  == .points
            && yUnit  == .points
            && corner == .bottomLeft
    }
    
    public static let points     = PositionType(xUnit: .points, yUnit: .points, corner: .bottomLeft)
    public static let uiPoints   = PositionType(xUnit: .uiPoints, yUnit: .uiPoints, corner: .bottomLeft)
    public static let normalized = PositionType(xUnit: .normalized, yUnit: .normalized, corner: .bottomLeft)
}

/** Position type compines SizeUnit. */
public struct SizeType {
    public let xUnit: SizeUnit
    public let yUnit: SizeUnit
    
    public var isBasicPoints: Bool {
        return xUnit  == .points
            && yUnit  == .points
    }

    public static let points     = SizeType(xUnit: .points, yUnit: .points)
    public static let uiPoints   = SizeType(xUnit: .uiPoints, yUnit: .uiPoints)
    public static let normalized = SizeType(xUnit: .normalized, yUnit: .normalized)
}
