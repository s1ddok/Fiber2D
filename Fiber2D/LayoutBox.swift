import SwiftMath

/**
 Declares the possible directions for laying out nodes in a LayoutBox.
 */
enum LayoutBoxDirection {    /// The children will be horizontally aligned.
    case horizontal
    /// The children will be vertically aligned.
    case vertical
}
func roundUpToEven(_ f: Float) -> Float {
    return ceilf(f / 2.0) * 2.0
}
/**
 The box layout lays out its child nodes in a horizontal row or a vertical column. Optionally you can set a spacing between the child nodes.
 
 @note In order to layout nodes in a grid, you can add one or more LayoutBox as child node with the opposite layout direction, ie the parent
 box layout node uses vertical and the child box layout nodes use horizontal LayoutBoxDirection to create a grid of nodes.
 */

class LayoutBox: Layout {
    /** @name Layout Options */
    /**
     The direction is either horizontal or vertical.
     @see CCLayoutBoxDirection
     */
    var direction: LayoutBoxDirection = .horizontal {
        didSet {
            needsLayout()
        }
    }
    /**
     The spacing in points between the child nodes.
     */
    var spacing: Float = 0.0 {
        didSet {
            needsLayout()
        }
    }
    
    override func layout() {
        super.layout()
        
        guard children.count > 0 else {
            return
        }
        
        if direction == .horizontal {
            // Get the maximum height
            var maxHeight: Float = 0
            for child in self.children {
                let height = Float(child.contentSizeInPoints.height)
                if height > maxHeight {
                    maxHeight = height
                }
            }
            // Position the nodes
            var width: Float = 0
            for child in self.children {
                let childSize: Size = child.contentSizeInPoints
                let offset: Point = child.anchorPointInPoints
                let localPos: Point = p2d(roundf(width), roundf(maxHeight - childSize.height / 2.0))
                let position: Point = localPos + offset
                child.position = position
                child.positionType = PositionType.points
                width += Float(childSize.width)
                width += spacing
            }
            // Account for last added increment
            width -= spacing
            if width < 0 {
                width = 0
            }
            self.contentSizeType = SizeType.points
            self.contentSize = Size(width: Float(roundUpToEven(width)), height: Float(roundUpToEven(maxHeight)))
        }
        else {
            // Get the maximum width
            var maxWidth: Float = 0
            for child in self.children {
                let width = Float(child.contentSizeInPoints.width)
                if width > maxWidth {
                    maxWidth = width
                }
            }
            // Position the nodes
            var height: Float = 0
            for child in self.children {
                let childSize: Size = child.contentSizeInPoints
                let offset: Point = child.anchorPointInPoints
                let localPos: Point = p2d(Float(roundf((maxWidth - Float(childSize.width)) / 2.0)), Float(roundf(height)))
                let position: Point = localPos + offset
                child.position = position
                child.positionType = PositionType.points
                height += Float(childSize.height)
                height += spacing
            }
            // Account for last added increment
            height -= spacing
            if height < 0 {
                height = 0
            }
            self.contentSizeType = SizeType.points
            self.contentSize = Size(width: Float(roundUpToEven(maxWidth)), height: Float(roundUpToEven(height)))
        }
    }
    
    override func childWasRemoved(child: Node) {
        needsLayout()
    }
}
