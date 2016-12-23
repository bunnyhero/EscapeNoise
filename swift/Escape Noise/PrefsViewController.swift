//
//  PrefsViewController.swift
//  Escape Noise
//
//  Created by bunnyhero on 2016-12-23.
//  Copyright © 2016 bunnyhero labs. All rights reserved.
//

import Cocoa

class PrefsViewController: NSViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func volumeSliderChanged(_ sender: Any) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.clickPlayer.currentTime = 0
            appDelegate.clickPlayer.play()
        }
    }
}
