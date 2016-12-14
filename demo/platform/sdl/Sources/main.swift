import CSDL2
import SwiftMath
import SwiftBGFX
import Fiber2D

let window = Window(title: "Fiber2D-SDL", origin: .zero, size: Size(1024, 768), flags: [.shown])

var wmi = SDL_SysWMinfo()
SDL_GetWindowWMInfo(window.handle, &wmi)

#if os(OSX)
var pd = PlatformData()
pd.ndt = nil

// Hack around C anonymous structs, will see if it works...
var cocoa = wmi.info.cocoa
let pointer = UnsafeMutableRawPointer(&cocoa)
pd.nwh = pointer.assumingMemoryBound(to: UnsafeMutableRawPointer.self).pointee
    
bgfx.setPlatformData(pd)
#endif

let locator = FileLocator.shared
locator.untaggedContentScale = 4
locator.searchPaths = [ "/Users/s1ddok/Documents/Projects/GitHub/Fiber2D/demo/Resources"]

bgfx.renderFrame()
bgfx.initialize()
bgfx.reset(width: 1024, height: 768, options: [.vsync])

var event = SDL_Event()
var running = true

let director: Director = Director(view: window)
Director.pushCurrentDirector(director)
director.present(scene: MainScene(size: director.designSize))
Director.popCurrentDirector()

while running {
    director.mainLoopBody()
}
