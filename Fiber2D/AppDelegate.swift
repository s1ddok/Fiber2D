//
//  AppDelegate.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 25.07.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        CCSetup.createCustomSetup()
        CCSetup.sharedSetup().contentScale = 2.0
        //;2*[_view convertSizeToBacking:NSMakeSize(1, 1)].width;
        CCSetup.sharedSetup().assetScale = CCSetup.sharedSetup().contentScale
        CCSetup.sharedSetup().UIScale = 0.5
        let rect: CGRect = CGRectMake(0, 0, 1024, 768)
        window = NSWindow(contentRect: rect, styleMask: NSClosableWindowMask | NSResizableWindowMask | NSTitledWindowMask, backing: .Buffered, defer: false, screen: NSScreen.mainScreen())
        let view: MetalView = MetalView(frame: rect)
        view.wantsBestResolutionOpenGLSurface = true
        self.window.contentView = view
        let locator: CCFileLocator = CCFileLocator.sharedFileLocator()
        locator.untaggedContentScale = 4
        locator.searchPaths = [ NSBundle.mainBundle().resourcePath!, NSBundle.mainBundle().resourcePath! + "//Resources" ]
            
        window.center()
        window.makeFirstResponder(view)
        window.makeKeyAndOrderFront(window)
        
        self.window.acceptsMouseMovedEvents = true
        let director: Director = view.director
        Director.pushCurrentDirector(director)
        director.presentScene(MainScene())
        Director.popCurrentDirector()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

