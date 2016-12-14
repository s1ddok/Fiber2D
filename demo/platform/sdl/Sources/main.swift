import CSDL2
import SwiftMath
import SwiftBGFX

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

bgfx.renderFrame()

var event = SDL_Event()
var running = true
while running {
    SDL_WaitEvent(&event)
}
