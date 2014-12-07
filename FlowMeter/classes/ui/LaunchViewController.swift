//
//  LaunchViewController.swift
//  FlowMeter
//
//  Created by Simon Bogutzky on 06.12.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

import UIKit

class LaunchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = true;
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: Selector("showTabBar"), userInfo: nil, repeats: false)
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    func showTabBar() {
        let storyboard = UIStoryboard(name: "MainStoryboard", bundle: nil)
        let tabBarController = storyboard.instantiateViewControllerWithIdentifier("TabBar") as UITabBarController
        
        tabBarController.selectedIndex = 1
        tabBarController.tabBar.translucent = false
        self.presentViewController(tabBarController, animated: false) { () -> Void in
            
            // Global apperance
            UINavigationBar.appearance().tintColor = UIColor.whiteColor()
            UIApplication.sharedApplication().statusBarStyle = .LightContent
            UIApplication.sharedApplication().statusBarHidden = false
        }
            
    }

}
