//
//  AppDelegate.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 25.07.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Cocoa
import SwiftBGFX

class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    var director: Director!
    var renderer: Renderer!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Setup.shared.contentScale = 2.0
        //;2*[_view convertSizeToBacking:NSMakeSize(1, 1)].width;
        Setup.shared.assetScale = Setup.shared.contentScale
        Setup.shared.UIScale = 0.5
        let rect: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 768)
        window = NSWindow(contentRect: rect, styleMask: [NSClosableWindowMask, NSResizableWindowMask, NSTitledWindowMask], backing: .buffered, defer: false, screen: NSScreen.main())
        
        let view: MetalView = MetalView(frame: rect)
        view.wantsBestResolutionOpenGLSurface = true
        self.window.contentView = view
        
        let locator = FileLocator.shared
        locator.untaggedContentScale = 4
        locator.searchPaths = [ Bundle.main.resourcePath!, Bundle.main.resourcePath! + "/Resources" ]
            
        window.center()
        window.makeFirstResponder(view)
        window.makeKeyAndOrderFront(window)
        
        var pd = PlatformData()
        pd.nwh = UnsafeMutableRawPointer(Unmanaged.passRetained(view).toOpaque())
        pd.context = UnsafeMutableRawPointer(Unmanaged.passRetained(view.device!).toOpaque())
        bgfx.setPlatformData(pd)
        
        bgfx.renderFrame()
        bgfx.initialize(type: .metal)
        bgfx.reset(width: 1024, height: 768, options: [.vsync, .flipAfterRender])
        
        //bgfx.renderFrame()
        
        
        self.window.acceptsMouseMovedEvents = true
        let director: Director = view.director
//        director = Director(view: self)
        Director.pushCurrentDirector(director)
        director.present(scene: MainScene(size: director.designSize))
        //director.present(scene: ViewportScene(size: director.designSize))
        Director.popCurrentDirector()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

