//
//  AppDelegate.swift
//  Escape Noise
//
//  The MIT License (MIT) Copyright (c) 2016 bunnyhero labs

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import AVFoundation
import Cocoa
import CoreFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var clickPlayer:AVAudioPlayer!

    @IBOutlet weak var statusMenu: NSMenu!
    var statusItem: NSStatusItem!
    
    var windowController: NSWindowController!
    
    let statusItemImageName = NSImage.Name(rawValue: "icon-Template")
    let mainStoryboardName = NSStoryboard.Name(rawValue: "Main")
    let prefsWindowSceneId = NSStoryboard.SceneIdentifier(rawValue: "prefswindow")
    let clickSoundName = "click"
    let volumeBindingName = NSBindingName(rawValue: "volume")
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        UserDefaults.standard.register(defaults: ["volume": 1.0])
        
        let statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.menu = statusMenu
        statusItem.image = NSImage(named: statusItemImageName)
        
        windowController = NSStoryboard(name: mainStoryboardName, bundle: nil).instantiateController(withIdentifier: prefsWindowSceneId) as! NSWindowController
        
        let options = NSDictionary(object: kCFBooleanTrue,
                                   forKey: kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString) as CFDictionary
        
        //  We need permission to listen to keyboard events
        
        if AXIsProcessTrustedWithOptions(options) {
            setUpPlayer()
            startMonitoringKeyEvents()
        }
        else {
            checkPermissionsTillAccepted()
        }
    }



    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    
    @objc func checkPermissionsTillAccepted() {
        //  This method of polling for permission, then automatically relaunching when granted, is
        //  from here: http://stackoverflow.com/a/35714641/107980
        
        let options = NSDictionary(object: kCFBooleanFalse,
                                   forKey: kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString) as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            //  relaunch!
            Process.launchedProcess(launchPath: "/bin/sh",
                                    arguments: ["-c", "sleep 3; /usr/bin/open '\(Bundle.main.bundlePath)'"])
            NSApplication.shared.terminate(self)
        }
        else {
            //  check again in 1 second
            perform(#selector(AppDelegate.checkPermissionsTillAccepted), with: nil, afterDelay: 1.0)
        }
    }

    
    func setUpPlayer() {
        guard let clickUrl = Bundle.main.url(forResource: clickSoundName, withExtension: "aiff") else {
            NSLog("Could not get click audio file")
            return
        }

        do {
            try clickPlayer = AVAudioPlayer(contentsOf: clickUrl)
            clickPlayer.prepareToPlay()
            clickPlayer.volume = UserDefaults.standard.float(forKey: "volume")
            NSLog("Created and prepared AVAudioPlayer")
            
            //  listen for volume setting changes
            clickPlayer.bind(volumeBindingName, to: NSUserDefaultsController.shared, withKeyPath: "values.volume", options: nil)
        }
        catch {
            clickPlayer = nil
            NSLog("Could not create AVAudioPlayer")
        }
    }
    
    func startMonitoringKeyEvents() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        if let eventTap = CGEvent.tapCreate(tap: .cghidEventTap,
                                         place: .headInsertEventTap,
                                         options: .listenOnly, eventsOfInterest: CGEventMask(eventMask),
                                         callback: handleCGEvent, userInfo: &clickPlayer) {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    @IBAction func openPrefs(_ sender: Any) {
        windowController.showWindow(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}


//  global function for the event tap callback

func handleCGEvent(proxy: OpaquePointer, type: CGEventType, eventRef: CGEvent,
                   refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    if type == .keyDown {
        let keycode = eventRef.getIntegerValueField(.keyboardEventKeycode)
        if keycode == 53 {  //  should use a constant here. this is the ESC keyCode on my computer
            if let refcon = refcon {
                //  converting these unsafe raw pointers to swift objects is ugly!
                let audioPlayerPtr = refcon.assumingMemoryBound(to: AVAudioPlayer.self)
                let audioPlayer = audioPlayerPtr.pointee
                audioPlayer.currentTime = 0 //  restart sound if it was playing
                audioPlayer.play()
            }
        }
    }
    return Unmanaged<CGEvent>.passUnretained(eventRef)
}



