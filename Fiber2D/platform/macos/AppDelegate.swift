//
//  AppDelegate.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 25.07.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        CCSetup.createCustomSetup()
        CCSetup.shared().contentScale = 2.0
        //;2*[_view convertSizeToBacking:NSMakeSize(1, 1)].width;
        CCSetup.shared().assetScale = CCSetup.shared().contentScale
        CCSetup.shared().uiScale = 0.5
        let rect: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 768)
        window = NSWindow(contentRect: rect, styleMask: [NSClosableWindowMask, NSResizableWindowMask, NSTitledWindowMask], backing: .buffered, defer: false, screen: NSScreen.main())
        let view: MetalView = MetalView(frame: rect)
        view.wantsBestResolutionOpenGLSurface = true
        self.window.contentView = view
        let locator: CCFileLocator = CCFileLocator.shared()
        locator.untaggedContentScale = 4
        locator.searchPaths = [ Bundle.main.resourcePath!, Bundle.main.resourcePath! + "//Resources" ]
            
        window.center()
        window.makeFirstResponder(view)
        window.makeKeyAndOrderFront(window)
        
        self.window.acceptsMouseMovedEvents = true
        let director: Director = view.director
        Director.pushCurrentDirector(director)
        //director.presentScene(MainScene(size: director.designSize))
        director.presentScene(ViewportScene(size: director.designSize))
        Director.popCurrentDirector()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

