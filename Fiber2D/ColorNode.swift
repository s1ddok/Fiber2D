//
//  ColorNode.swift
//
//  Created by Andrey Volodin on 06.07.16.
//  Copyright © 2016. All rights reserved.
//

import SwiftMath
import SwiftBGFX

/**
 Draws a rectangle filled with a solid color.
 */
open class ColorNode: Node {
    /**
     *  Creates a node with color, width and height in Points.
     *
     *  @param color Color of the node.
     *  @param size  Width and Height of the node.
     *
     *  @return An initialized ColorNode Object.
     *  @see Color
     */
    public init(color: Color = .clear, size: Size = .zero) {
        super.init()
        self.color = color
        self.contentSizeInPoints = size
        self.add(component: BackgroundColorRenderComponent())
    }
}

public class BackgroundColorRenderComponent: QuadRenderer {

    public init() {
        super.init(material: Material(technique: .positionColor))
    }

    public override func onAdd(to owner: Node) {
        super.onAdd(to: owner)

        self.update(for: owner.contentSizeInPoints)
        owner.onContentSizeInPointsChanged.subscribe(on: self) {
            self.update(for: $0)
        }

        self.geometry.color = owner.displayedColor.premultiplyingAlpha
        owner.onDisplayedColorChanged.subscribe(on: self) {
            self.geometry.color = $0.premultiplyingAlpha
        }
    }

    public override func onRemove() {
        // Do it before super, as it assigns owner to nil
        owner?.onContentSizeInPointsChanged.cancelSubscription(for: self)
        owner?.onDisplayedColorChanged.cancelSubscription(for: self)
        super.onRemove()
    }

    public func update(for size: Size) {
        geometry.positions = [vec4(0, 0, 0, 1),
                              vec4(size.width, 0, 0, 1),
                              vec4(size.width, size.height, 0, 1),
                              vec4(0, size.height, 0, 1)]
    }
}
