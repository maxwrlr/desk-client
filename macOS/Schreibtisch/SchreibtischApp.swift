//
//  SchreibtischApp.swift
//  Schreibtisch
//

import SwiftUI

@main
struct SchreibtischApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
	
	var body: some Scene {
		MenuBarExtra("Schreibtisch", systemImage: "table.furniture.fill") {
			ContentView()
		}
		.menuBarExtraStyle(.window)
		Settings {
			SettingsView()
		}
	}
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
	func applicationDidFinishLaunching(_ notification: Notification) {
		UserDefaults.standard.set("/dev/cu.usbserial-14410", forKey: "serialPort")
	}
}
