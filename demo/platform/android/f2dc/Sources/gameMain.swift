import CSDL2
import SwiftMath
import SwiftBGFX
import Fiber2D
import CAndroidAppGlue
import Foundation

@_cdecl("SDL_main")
public func SDL_main(argc: Int32, argv: OpaquePointer) -> Int32 {
    var pd = PlatformData()

    #if os(OSX)

    pd.ndt = nil
    // Hack around C anonymous structs, will see if it works...
    var cocoa = wmi.info.cocoa
    let pointer = UnsafeMutableRawPointer(&cocoa)
    pd.nwh = pointer.assumingMemoryBound(to: UnsafeMutableRawPointer.self).pointee

    #endif

    #if os(Linux)

    let window = Window(title: "Fiber2D-SDL", origin: .zero, size: Size(1024, 768), flags: [.shown])

    var wmi = SDL_SysWMinfo()
    SDL_SysWMinfo_init_version(&wmi)
    print(SDL_GetWindowWMInfo(window.handle, &wmi))


    pd.ndt = SDL_SysWMinfo_get_x11_display(&wmi)
    pd.nwh = SDL_SysWMinfo_get_x11_window(&wmi)

    #endif

    #if os(Android)
    let _window = Window(title: "Fiber2D-SDL", origin: .zero, size: Size(1280, 720), flags: [.shown, .resizable])
    //pd.nwh = SDL_SysWMinfo_get_android_window(&wmi)
    pd.nwh = CAPG_GetNativeWindow()

    #endif

    SDL_Init(SDL_INIT_EVENTS)

    bgfx.setPlatformData(pd)
    let locator = FileLocator.shared
    locator.untaggedContentScale = 4
    locator.searchPaths = [ "/Users/s1ddok/Documents/Projects/GitHub/Fiber2D/demo/Resources"]

    let window = WindowMock()

    bgfx.renderFrame()
    bgfx.initialize()
    bgfx.reset(width: UInt16(window.sizeInPixels.width), height: UInt16(window.sizeInPixels.height), options: [.vsync])

    let director: Director = Director(view: window)
    Director.pushCurrentDirector(director)
    //let scene = PhysicsScene(size: director.designSize)
    let scene = InputScene(size: director.designSize)
    scene.color = .red
    director.present(scene: scene)
    Director.popCurrentDirector()

    var running = true
    var event = SDL_Event()
    while running {
        Director.pushCurrentDirector(director)
        while SDL_PollEvent(&event) != 0 {
            switch EventType.from(event: event) {
            case EventType.fingerDown:
                let innerEvent = event.tfinger
                director.responderManager.fingerDown(event: innerEvent)
            case EventType.fingerUp:
                let innerEvent = event.tfinger
                director.responderManager.fingerUp(event: innerEvent)
            case EventType.fingerMotion:
                let innerEvent = event.tfinger
                director.responderManager.fingerMoved(event: innerEvent)
            case EventType.quit:
                running = true
            default:
                break
            }
        }
        Director.popCurrentDirector()

        director.mainLoopBody()
    }

    return 0
}
