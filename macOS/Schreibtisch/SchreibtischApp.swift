//
//  SchreibtischApp.swift
//  Schreibtisch
//

import SwiftUI

@main
struct SchreibtischApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
	
	var body: some Scene {
		Settings {
			SettingsView()
		}
	}
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
	private var statusItem: NSStatusItem!
	private var popover: NSPopover!
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		UserDefaults.standard.set("/dev/cu.usbserial-14410", forKey: "serialPort")
		
		self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		if let statusButton = self.statusItem.button {
			statusButton.image = NSImage(systemSymbolName: "studentdesk", accessibilityDescription: "Schreibtisch")
			statusButton.action = #selector(self.togglePopover)
		}
		
		self.popover = NSPopover()
		self.popover.behavior = .transient
		self.popover.contentViewController = NSHostingController(rootView: ContentView())
	}
	
	@objc func togglePopover() {
		if self.popover.isShown {
			self.popover.performClose(nil)
		} else if let button = self.statusItem.button {
			self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
			self.popover.contentViewController?.view.window?.makeKey()
		}
	}
}
