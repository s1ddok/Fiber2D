//
//  AppDelegate.swift
//  Fiber2D-demo-iOS
//
//  Created by Andrey Volodin on 30.12.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import UIKit
import SwiftBGFX
import Fiber2D

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Setup.shared.contentScale = 2.0
        //;2*[_view convertSizeToBacking:NSMakeSize(1, 1)].width;
        Setup.shared.assetScale = Setup.shared.contentScale
        Setup.shared.UIScale = 0.5
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else {
            fatalError("Window must be present at this time")
        }
        
        let rect: CGRect = window.bounds
        
        let view: MetalView = MetalView(frame: rect)

        let locator = FileLocator.shared
        locator.untaggedContentScale = 4
        locator.searchPaths = [ Bundle.main.resourcePath!, Bundle.main.resourcePath! + "/images" ]
        
        var pd = PlatformData()
        pd.nwh = UnsafeMutableRawPointer(Unmanaged.passRetained(view).toOpaque())
        pd.context = UnsafeMutableRawPointer(Unmanaged.passRetained(view.device!).toOpaque())
        bgfx.setPlatformData(pd)
        bgfx.renderFrame()
        bgfx.initialize(type: .metal)
        bgfx.reset(width: UInt16(rect.width), height: UInt16(rect.height), options: [.vsync, .flipAfterRender])
        
        let vc = UIViewController()
        vc.view = view
        window.rootViewController = vc
        window.makeKeyAndVisible()
        let director: Director = view.director
        Director.pushCurrentDirector(director)
        //director.present(scene: PhysicsScene(size: director.designSize))
        director.present(scene: MainScene(size: director.designSize))
        //director.present(scene: ViewportScene(size: director.designSize))
        Director.popCurrentDirector()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

