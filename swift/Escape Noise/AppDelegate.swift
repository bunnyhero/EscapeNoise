//
//  AppDelegate.swift
//  Escape Noise
//
//  Created by bunnyhero on 2016-12-03.
//  Copyright © 2016 bunnyhero labs. All rights reserved.
//

import AVFoundation
import Cocoa
import CoreFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var clickPlayer:AVAudioPlayer!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        let options = NSDictionary(object: kCFBooleanTrue,
                                   forKey: kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString) as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            setUpPlayer()
            startMonitoring()
        }
        else {
            checkPermissionsTillAccepted()
        }
    }



    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    func checkPermissionsTillAccepted() {
        let options = NSDictionary(object: kCFBooleanFalse,
                                   forKey: kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString) as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            //  relaunch!
            Process.launchedProcess(launchPath: "/bin/sh",
                                    arguments: ["-c", "sleep 3; /usr/bin/open '\(Bundle.main.bundlePath)'"])
            NSApplication.shared().terminate(self)
        }
        else {
            //  check again in 3 seconds
            perform(#selector(AppDelegate.checkPermissionsTillAccepted), with: nil, afterDelay: 3.0)
        }
    }

    func setUpPlayer() {
        guard let clickUrl = Bundle.main.url(forResource: "click", withExtension: "aiff") else {
            print("Could not get click audio file")
            return
        }

        do {
            try clickPlayer = AVAudioPlayer(contentsOf: clickUrl)
            clickPlayer.prepareToPlay()
            print("Created and prepared AVAudioPlayer")
        }
        catch {
            clickPlayer = nil
            print("Could not create AVAudioPlayer")
        }
    }
    
    
    func startMonitoring() {
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
}


//  global function for the event tap callback

func handleCGEvent(proxy: OpaquePointer, type: CGEventType, eventRef: CGEvent,
                   refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    if type == .keyDown {
        let keycode = eventRef.getIntegerValueField(.keyboardEventKeycode)
        if keycode == 53 {
            if let refcon = refcon {
                let audioPlayerPtr = refcon.assumingMemoryBound(to: AVAudioPlayer.self)
                audioPlayerPtr.pointee.play()
            }
        }
    }
    return Unmanaged<CGEvent>.passUnretained(eventRef)
}

