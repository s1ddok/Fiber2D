//
//  Node+Convertation.swift
//
//  Created by Andrey Volodin on 23.07.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

extension Node {
    // MARK: Position
    
    /** Converts the given position in points to position values converted based on the provided CCPositionType.
     
     @param positionInPoints The position in points to convert.
     @param type How the input position values should be converted.
     @returns The position values in the format specified by type.
     @see position
     @see CCPositionType, CCPositionUnit, CCPositionReferenceCorner */
    func convertPositionFromPoints(positionInPoints: CGPoint, type: CCPositionType) -> CGPoint {
        let setup: CCSetup = CCSetup.sharedSetup()
        let UIScale = CGFloat(setup.UIScale)
        var parentsContentSizeInPoints = CGSizeMake(0.0, 0.0)
        var gotParentSize: Bool = parent == nil
        var position = CGPointZero
        var x = positionInPoints.x
        var y = positionInPoints.y
        // Account for reference corner
        let corner = type.corner
        if corner == .BottomLeft {
            // Nothing needs to be done
            // Nothing needs to be done
        }
        else if corner == .TopLeft {
            // Reverse y-axis
            if !gotParentSize {
                parentsContentSizeInPoints = parent!.contentSizeInPoints
                gotParentSize = true
            }
            y = parentsContentSizeInPoints.height - y
        }
        else if corner == .TopRight {
            // Reverse x-axis and y-axis
            if !gotParentSize {
                parentsContentSizeInPoints = parent!.contentSizeInPoints
                gotParentSize = true
            }
            x = parentsContentSizeInPoints.width - x
            y = parentsContentSizeInPoints.height - y
        }
        else if corner == .BottomRight {
            // Reverse x-axis
            if !gotParentSize {
                parentsContentSizeInPoints = parent!.contentSizeInPoints
                gotParentSize = true
            }
            x = parentsContentSizeInPoints.width - x
        }
        
        // Convert position from points
        let xUnit = type.xUnit
        if xUnit == .Points {
            position.x = x
        }
        else if xUnit == .UIPoints {
            position.x = x / UIScale
        }
        else if xUnit == .Normalized {
            let parentWidth: CGFloat = gotParentSize ? parentsContentSizeInPoints.width : parent!.contentSizeInPoints.width
            if parentWidth > 0 {
                position.x = x / CGFloat(parentWidth)
            }
        }
        
        let yUnit = type.yUnit
        if yUnit == .Points {
            position.y = y
        }
        else if yUnit == .UIPoints {
            position.y = y / UIScale
        }
        else if yUnit == .Normalized {
            let parentHeight: CGFloat = gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height
            if parentHeight > 0 {
                position.y = y / CGFloat(parentHeight)
            }
        }
        
        return position
    }
    
    /** Converts the given position values to a position in points.
     
     @param position The position values to convert.
     @param type How the input position values should be interpreted.
     @returns The converted position in points.
     @see positionInPoints
     @see CCPositionType, CCPositionUnit, CCPositionReferenceCorner */
    func convertPositionToPoints(position: CGPoint, type: CCPositionType) -> CGPoint {
        let setup: CCSetup = CCSetup.sharedSetup()
        let UIScale = CGFloat(setup.UIScale)
        var gotParentSize: Bool = parent == nil
        var parentsContentSizeInPoints = CGSizeMake(0.0, 0.0)
        var positionInPoints = CGPointZero
        var x: CGFloat = 0
        var y: CGFloat = 0
        // Convert position to points
        let xUnit = type.xUnit
        if xUnit == .Points {
            x = position.x
        }
        else if xUnit == .UIPoints {
            x = position.x * UIScale
        }
        else if xUnit == .Normalized {
            if !gotParentSize {
                parentsContentSizeInPoints = parent!.contentSizeInPoints
                gotParentSize = true
            }
            x = position.x * parentsContentSizeInPoints.width
        }
        
        let yUnit = type.yUnit
        if yUnit == .Points {
            y = position.y
        }
        else if yUnit == .UIPoints {
            y = position.y * UIScale
        }
        else if yUnit == .Normalized {
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
        if corner == .BottomLeft {
            // Nothing needs to be done
            // Nothing needs to be done
        }
        else if corner == .TopLeft {
            // Reverse y-axis
            y = gotParentSize ? parentsContentSizeInPoints.height - y : parent!.contentSizeInPoints.height - y
        }
        else if corner == .TopRight {
            // Reverse x-axis and y-axis
            x = gotParentSize ? parentsContentSizeInPoints.width - x : parent!.contentSizeInPoints.width - x
            y = gotParentSize ? parentsContentSizeInPoints.height - y : parent!.contentSizeInPoints.height - y
        }
        else if corner == .BottomRight {
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
     @see CCSizeType, CCSizeUnit */
    func convertContentSizeToPoints(contentSize: CGSize, type: CCSizeType) -> CGSize {
        var size: CGSize = CGSizeZero
        let setup: CCSetup = CCSetup.sharedSetup()
        let UIScale = CGFloat(setup.UIScale)
        let widthUnit = type.widthUnit
        let heightUnit = type.heightUnit
        var gotParentSize: Bool = parent == nil
        var parentsContentSizeInPoints = CGSizeMake(0.0, 0.0)
        // Width
        if widthUnit == .Points {
            size.width = contentSize.width
        }
        else if widthUnit == .UIPoints {
            size.width = UIScale * contentSize.width
        }
        else if widthUnit == .Normalized {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            size.width = contentSize.width * parentsContentSizeInPoints.width
        }
        else if widthUnit == .InsetPoints {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            size.width = parentsContentSizeInPoints.width - contentSize.width
        }
        else if widthUnit == .InsetUIPoints {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            size.width = parentsContentSizeInPoints.width - contentSize.width * UIScale
        }
        
        // Height
        if heightUnit == .Points {
            size.height = contentSize.height
        }
        else if heightUnit == .UIPoints {
            size.height = UIScale * contentSize.height
        }
        else if heightUnit == .Normalized {
            size.height = contentSize.height * (gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height)
        }
        else if heightUnit == .InsetPoints {
            size.height = (gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height) - contentSize.height
        }
        else if heightUnit == .InsetUIPoints {
            size.height = (gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height) - contentSize.height * UIScale
        }
        
        return size
    }
    /** Converts the given size in points to size values converted based on the provided CCSizeType.
     
     @param pointSize The size in points to convert.
     @param type How the input size values should be converted.
     @returns The size values in the format specified by type.
     @see contentSize
     @see CCSizeType, CCSizeUnit */
    func convertContentSizeFromPoints(pointSize: CGSize, type: CCSizeType) -> CGSize {
        var size: CGSize = CGSizeZero
        let setup: CCSetup = CCSetup.sharedSetup()
        let UIScale = CGFloat(setup.UIScale)
        let widthUnit = type.widthUnit
        let heightUnit = type.heightUnit
        var gotParentSize: Bool = parent == nil
        var parentsContentSizeInPoints = CGSizeMake(0.0, 0.0)
        // Width
        if widthUnit == .Points {
            size.width = pointSize.width
        }
        else if widthUnit == .UIPoints {
            size.width = pointSize.width / UIScale
        }
        else if widthUnit == .Normalized {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            let parentWidthInPoints = parentsContentSizeInPoints.width
            if parentWidthInPoints > 0 {
                size.width = pointSize.width / parentWidthInPoints
            }
            else {
                size.width = 0
            }
        }
        else if widthUnit == .InsetPoints {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            size.width = parentsContentSizeInPoints.width - pointSize.width
        }
        else if widthUnit == .InsetUIPoints {
            if !gotParentSize {
                gotParentSize = true
                parentsContentSizeInPoints = parent!.contentSizeInPoints
            }
            size.width = (parentsContentSizeInPoints.width - pointSize.width) / UIScale
        }
        
        // Height
        if heightUnit == .Points {
            size.height = pointSize.height
        }
        else if heightUnit == .UIPoints {
            size.height = pointSize.height / UIScale
        }
        else if heightUnit == .Normalized {
            let parentHeightInPoints = gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height
            if parentHeightInPoints > 0 {
                size.height = pointSize.height / parentHeightInPoints
            }
            else {
                size.height = 0
            }
        }
        else if heightUnit == .InsetPoints {
            size.height = (gotParentSize ? parentsContentSizeInPoints.height : parent!.contentSizeInPoints.height) - pointSize.height;
        } else if (heightUnit == .InsetUIPoints) {
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
    func convertToNodeSpace(worldPoint: CGPoint) -> CGPoint {
        return CGPointApplyGLKMatrix4(worldPoint, self.worldToNodeMatrix())
    }
    
    /**
     *  Converts a Point to world space coordinates. The result is in Points.
     *
     *  @param nodePoint Local position in points.
     *
     *  @return World position in points.
     */
    func convertToWorldSpace(nodePoint: CGPoint) -> CGPoint {
        return CGPointApplyGLKMatrix4(nodePoint, self.nodeToWorldMatrix())
    }
    /**
     *  Converts a Point to node (local) space coordinates. The result is in Points.
     *  Treats the returned/received node point as relative to the anchorPoint.
     *
     *  @param worldPoint World position in points.
     *
     *  @return Local position in points.
     */
    func convertToNodeSpaceAR(worldPoint: CGPoint) -> CGPoint {
        let nodePoint: CGPoint = self.convertToNodeSpace(worldPoint)
        return ccpSub(nodePoint, anchorPointInPoints)
    }
    
    /**
     *  Converts a local Point to world space coordinates. The result is in Points.
     *  Treats the returned/received node point as relative to the anchorPoint.
     *
     *  @param nodePoint Local position in points.
     *
     *  @return World position in points.
     */
    func convertToWorldSpaceAR(nodePoint: CGPoint) -> CGPoint {
        let np = ccpAdd(nodePoint, anchorPointInPoints)
        return self.convertToWorldSpace(np)
    }
    
    /**
     *  Converts a local Point to Window space (UIKit) coordinates. The result is in Points.
     *
     *  @param nodePoint Local position in points.
     *
     *  @return UI position in points.
     */
    func convertToWindowSpace(nodePoint: CGPoint) -> CGPoint {
        let wp = self.convertToWorldSpace(nodePoint)
        return Director.currentDirector()!.convertToUI(wp)
    }
}