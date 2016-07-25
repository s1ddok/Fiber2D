/**
 Declares the possible directions for laying out nodes in a CCLayoutBox.
 */
@objc enum CCLayoutBoxDirection : Int    /// The children will be horizontally aligned.
{
    case Horizontal
    /// The children will be vertically aligned.
    case Vertical
}
func roundUpToEven(f: Float) -> Float {
    return ceilf(f / 2.0) * 2.0
}
/**
 The box layout lays out its child nodes in a horizontal row or a vertical column. Optionally you can set a spacing between the child nodes.
 
 @note In order to layout nodes in a grid, you can add one or more CCLayoutBox as child node with the opposite layout direction, ie the parent
 box layout node uses vertical and the child box layout nodes use horizontal CCLayoutBoxDirection to create a grid of nodes.
 */

@objc class LayoutBox: Layout {
    /** @name Layout Options */
    /**
     The direction is either horizontal or vertical.
     @see CCLayoutBoxDirection
     */
    var direction: CCLayoutBoxDirection = .Horizontal {
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
        
        if direction == .Horizontal {
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
                let childSize: CGSize = child.contentSizeInPoints
                let offset: CGPoint = child.anchorPointInPoints
                let localPos: CGPoint = ccp(CGFloat(roundf(width)), CGFloat(roundf(Float(maxHeight - Float(childSize.height)) / 2.0)))
                let position: CGPoint = ccpAdd(localPos, offset)
                child.position = position
                child.positionType = CCPositionTypePoints
                width += Float(childSize.width)
                width += spacing
            }
            // Account for last added increment
            width -= spacing
            if width < 0 {
                width = 0
            }
            self.contentSizeType = CCSizeTypePoints
            self.contentSize = CGSizeMake(CGFloat(roundUpToEven(width)), CGFloat(roundUpToEven(maxHeight)))
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
                let childSize: CGSize = child.contentSizeInPoints
                let offset: CGPoint = child.anchorPointInPoints
                let localPos: CGPoint = ccp(CGFloat(roundf((maxWidth - Float(childSize.width)) / 2.0)), CGFloat(roundf(height)))
                let position: CGPoint = ccpAdd(localPos, offset)
                child.position = position
                child.positionType = CCPositionTypePoints
                height += Float(childSize.height)
                height += spacing
            }
            // Account for last added increment
            height -= spacing
            if height < 0 {
                height = 0
            }
            self.contentSizeType = CCSizeTypePoints
            self.contentSize = CGSizeMake(CGFloat(roundUpToEven(maxWidth)), CGFloat(roundUpToEven(height)))
        }
    }
    
    override func detachChild(child: Node, cleanup: Bool = true) {
        super.detachChild(child, cleanup: cleanup)
        self.needsLayout()
    }
}