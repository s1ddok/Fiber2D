
import SwiftMath
import Fiber2D

class WindowMock: DirectorView {
    let a = 0

    public func add(frameCompletionHandler handler: @escaping () -> ()) { }

    public var sizeInPixels: Size {
        return Size(1280, 720)
    }

    public var size: Size {
        return Size(1280, 720)
    }

    // Prepare the view to render a new frame.
    public func beginFrame() {}

    // Present the current frame to the display.
    public func presentFrame() {}
}
