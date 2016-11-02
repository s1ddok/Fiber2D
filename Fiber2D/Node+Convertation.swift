//
//  Node+Convertation.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath

public extension Node {
    // MARK: Position
    
    /** Converts the given position in points to position values converted based on the provided PositionType.
     
     @param positionInPoints The position in points to convert.
     @param type How the input position values should be converted.
     @returns The position values in the format specified by type.
     @see position
     @see PositionType, PositionUnit, PositionReferenceCorner */
    public func convertPositionFromPoints(_ positionInPoints: Point, type: PositionType) -> Point {
        let setup = Setup.shared
        let UIScale = setup.UIScale
        var parentsContentSizeInPoints = Size.zero
        var gotParentSize: Bool = parent == nil
        var position = Point.zero
        var x = positionInPoints.x
        var y = positionInPoints.y
        // Account for reference corner
        let corner = type.corner
        if corner == .bottomLeft {
            // Nothing needs to be done
            // Nothing needs to be done
        } else if corner == .topLeft {
            // Reverse y-axis
            if !gotParentSize {
                parentsContentSizeInPoints = parent!.contentSizeInPoints
                gotParentSize = true
            }
            y = parentsContentSizeInPoints.height - y
        } else if corner == .topRight {
            // Reverse x-axis and y-axis
            if !gotParentSize {
                parentsContentSizeInPoints = parent!.contentSizeInPoints
                gotParentSize = true
            }
            x = parentsContentSizeInPoints.width - x
            y = parentsContentSizeInPoints.height - y
        } else if corner == .bottomRight {
            // Reverse x-axis
            if !gotParentSize {
                parentsContentSizeInPoints = parent!.contentSizeInPoints
                gotParentSize = true
            }
            x = parentsContentSizeInPoints.width - x
        }
        
        // Convert position from points
        let xUnit = type.xUnit
        if xUnit == .points {
            position.x = x
        } else if xUnit == .uiPoints {
            position.x = x / UIScale
        } else if xUnit == .normalized {
            let parentWidth = gotParentSize ? parentsContentSizeInPoints.width : parent!.contentSizeInPoints.width
            if parentWidth > 0 {
                position.x = x / parentWidth
            }
        }
        
        let yUnit = type.yUnit
        if yUnit == .points {
            position.y = y
        } else if yUnit == .uiPoints {
            position.y = y / UIScale
        } else if yUnit == .normalized {
            let parentHeight = gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height
            if parentHeight > 0 {
                position.y = y / parentHeight
            }
        }
        
        return position
    }
    
    /** Converts the given position values to a position in points.
     
     @param position The position values to convert.
     @param type How the input position values should be interpreted.
     @returns The converted position in points.
     @see positionInPoints
     @see PositionType, PositionUnit, PositionReferenceCorner */
    public func convertPositionToPoints(_ position: Point, type: PositionType) -> Point {
        let setup = Setup.shared
        let UIScale = setup.UIScale
        var gotParentSize: Bool = parent == nil
        var parentsContentSizeInPoints = Size(width: 0.0, height: 0.0)
        var positionInPoints = Point.zero
        var x: Float = 0
        var y: Float = 0
        // Convert position to points
        let xUnit = type.xUnit
        if xUnit == .points {
            x = position.x
        } else if xUnit == .uiPoints {
            x = position.x * UIScale
        } else if xUnit == .normalized {
            if !gotParentSize {
                parentsContentSizeInPoints = parent!.contentSizeInPoints
                gotParentSize = true
            }
            x = position.x * parentsContentSizeInPoints.width
        }
        
        let yUnit = type.yUnit
        if yUnit == .points {
            y = position.y
        } else if yUnit == .uiPoints {
            y = position.y * UIScale
        } else if yUnit == .normalized {
            if gotParentSize {
                y = position.y * parentsContentSizeInPoints.height
            }
            else {
                parentsContentSizeInPoints = parent!.contentSizeInPoints
                gotParentSize = true
                y = position.y * parentsContentSizeInPoints.height
            }
        }
        
        // Account for reference corner
        let corner = type.corner
        if corner == .bottomLeft {
            // Nothing needs to be done
            // Nothing needs to be done
        } else if corner == .topLeft {
            // Reverse y-axis
            y = gotParentSize ? parentsContentSizeInPoints.height - y : parent!.contentSizeInPoints.height - y
        } else if corner == .topRight {
            // Reverse x-axis and y-axis
            x = gotParentSize ? parentsContentSizeInPoints.width - x : parent!.contentSizeInPoints.width - x
            y = gotParentSize ? parentsContentSizeInPoints.height - y : parent!.contentSizeInPoints.height - y
        } else if corner == .bottomRight {
            // Reverse x-axis
            x = gotParentSize ? parentsContentSizeInPoints.width - x : parent!.contentSizeInPoints.width - x
        }
        
        positionInPoints.x = x
        positionInPoints.y = y
        return positionInPoints
    }
    
    // MARK: Content Size
    /** Converts the given content size values to a size in points.
     
     @param contentSize The contentSize values to convert.
     @param type How the input contentSize values should be interpreted.
     @returns The converted size in points.
     @see contentSizeInPoints
     @see SizeType, SizeUnit */
    public func convertContentSizeToPoints(_ contentSize: Size, type: SizeType) -> Size {
        var size: Size = Size.zero
        let setup = Setup.shared
        let UIScale = Float(setup.UIScale)
        let widthUnit = type.xUnit
        let heightUnit = type.yUnit
        var gotParentSize: Bool = parent == nil
        var parentsContentSizeInPoints = Size.zero
        // Width
        if widthUnit == .points {
            size.width = contentSize.width
        } else if widthUnit == .uiPoints {
            size.width = UIScale * contentSize.width
        } else if widthUnit == .normalized {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            size.width = contentSize.width * parentsContentSizeInPoints.width
        } else if widthUnit == .insetPoints {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            size.width = parentsContentSizeInPoints.width - contentSize.width
        } else if widthUnit == .insetUIPoints {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            size.width = parentsContentSizeInPoints.width - contentSize.width * UIScale
        }
        
        // Height
        if heightUnit == .points {
            size.height = contentSize.height
        } else if heightUnit == .uiPoints {
            size.height = UIScale * contentSize.height
        } else if heightUnit == .normalized {
            size.height = contentSize.height * (gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height)
        } else if heightUnit == .insetPoints {
            size.height = (gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height) - contentSize.height
        } else if heightUnit == .insetUIPoints {
            size.height = (gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height) - contentSize.height * UIScale
        }
        
        return size
    }
    /** Converts the given size in points to size values converted based on the provided SizeType.
     
     @param pointSize The size in points to convert.
     @param type How the input size values should be converted.
     @returns The size values in the format specified by type.
     @see contentSize
     @see SizeType, SizeUnit */
    public func convertContentSizeFromPoints(_ pointSize: Size, type: SizeType) -> Size {
        var size: Size = Size.zero
        let setup = Setup.shared
        let UIScale = Float(setup.UIScale)
        let widthUnit = type.xUnit
        let heightUnit = type.yUnit
        var gotParentSize: Bool = parent == nil
        var parentsContentSizeInPoints = Size.zero
        // Width
        if widthUnit == .points {
            size.width = pointSize.width
        } else if widthUnit == .uiPoints {
            size.width = pointSize.width / UIScale
        } else if widthUnit == .normalized {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            let parentWidthInPoints = parentsContentSizeInPoints.width
            if parentWidthInPoints > 0 {
                size.width = pointSize.width / parentWidthInPoints
            } else {
                size.width = 0
            }
        } else if widthUnit == .insetPoints {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            size.width = parentsContentSizeInPoints.width - pointSize.width
        } else if widthUnit == .insetUIPoints {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            size.width = (parentsContentSizeInPoints.width - pointSize.width) / UIScale
        }
        
        // Height
        if heightUnit == .points {
            size.height = pointSize.height
        } else if heightUnit == .uiPoints {
            size.height = pointSize.height / UIScale
        } else if heightUnit == .normalized {
            let parentHeightInPoints = gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height
            if parentHeightInPoints > 0 {
                size.height = pointSize.height / parentHeightInPoints
            } else {
                size.height = 0
            }
        } else if heightUnit == .insetPoints {
            size.height = (gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height) - pointSize.height;
        } else if (heightUnit == .insetUIPoints) {
            size.height = ((gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height) - pointSize.height) / UIScale;
        }
        return size;
    }
    
    // MARK: Other
    /**
     *  Converts a Point to node (local) space coordinates. The result is in Points.
     *
     *  @param worldPoint World position in points.
     *
     *  @return Local position in points.
     */
    public func convertToNodeSpace(_ worldPoint: Point) -> Point {
        return worldToNodeMatrix * worldPoint
    }
    
    /**
     *  Converts a Point to world space coordinates. The result is in Points.
     *
     *  @param nodePoint Local position in points.
     *
     *  @return World position in points.
     */
    public func convertToWorldSpace(_ nodePoint: Point) -> Point {
        return self.nodeToWorldMatrix * nodePoint
    }
    /**
     *  Converts a Point to node (local) space coordinates. The result is in Points.
     *  Treats the returned/received node point as relative to the anchorPoint.
     *
     *  @param worldPoint World position in points.
     *
     *  @return Local position in points.
     */
    public func convertToNodeSpaceAR(_ worldPoint: Point) -> Point {
        let nodePoint = convertToNodeSpace(worldPoint)
        return nodePoint - anchorPointInPoints
    }
    
    /**
     *  Converts a local Point to world space coordinates. The result is in Points.
     *  Treats the returned/received node point as relative to the anchorPoint.
     *
     *  @param nodePoint Local position in points.
     *
     *  @return World position in points.
     */
    public func convertToWorldSpaceAR(_ nodePoint: Point) -> Point {
        let np = nodePoint + anchorPointInPoints
        return self.convertToWorldSpace(np)
    }
    
    /**
     *  Converts a local Point to Window space (UIKit) coordinates. The result is in Points.
     *
     *  @param nodePoint Local position in points.
     *
     *  @return UI position in points.
     */
    public func convertToWindowSpace(_ nodePoint: Point) -> Point {
        let wp = self.convertToWorldSpace(nodePoint)
        return Director.currentDirector!.convertToUI(wp)
    }
}
