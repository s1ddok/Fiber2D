import SwiftMath

class Layout : Node {
    private var _needsLayout = false
    
    override init() {
        super.init()
        self.needsLayout()
    }
    
    func needsLayout() {
        self._needsLayout = true
    }
    
    func layout() {
        self._needsLayout = false
    }
    
    override var contentSize: Size {
        get {
            if _needsLayout {
                self.layout()
            }
            return super.contentSize
        }
        set {
            super.contentSize = newValue
        }
    }
    
    override func visit(_ renderer: Renderer, parentTransform: Matrix4x4f) {
        if _needsLayout {
            self.layout()
        }
        super.visit(renderer, parentTransform: parentTransform)
    }
    
    override func childWasAdded(child: Node) {
        self.sortAllChildren()
        self.layout()
    }
}
