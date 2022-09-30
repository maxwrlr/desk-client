//
//  ModelData.swift
//  Schreibtisch
//

import Foundation
import Combine
import SwiftUI

enum DeskState {
	// reset required
	case invalid
	// any action can be performed
	case ready
	// motors are running
	case busy
	// ready to receive press of preset button
	case config
	// motors were not used for some time, wakeup required
	// no idea why this was implemented in the motor controller
	case sleep
	// should never happen, no action can be performed, reconnect required
	case error
}

enum DeskButton: UInt8 {
	case none = 0
	
	case p1 = 1
	case p2 = 2
	case p3 = 3
	case up = 4
	case down = 5
	case m = 6
	
	var bit: UInt8 {
		return 1 << (6 - self.rawValue)
	}
	
	var isPreset: Bool {
		return 1 <= self.rawValue && self.rawValue <= 3
	}
}

final class Desk: ObservableObject, SerialDelegate {
	private var serial: SerialHandler!
	private var timer: Timer? = nil
	
	@Published var state: DeskState = .invalid
	@Published var height = 0
	@Published var activeButton: DeskButton = .none
	@Published var activePreset: DeskButton = .none
	@Published var desiredPreset: DeskButton = .none
	@Published var errorCode = 0
	@Published var errorMessage: String? = nil
	
	// The following variable has 2 use cases:
	// - if headed for preset: remain in busy state while desk is accelarating (little hacky technique).
	// - if using up or down button: release button if desk doesn't move for some time.
	private var idleTime = 0
	
	init(path: String = "/dev/cu.usbserial-14410") {
		self.serial = SerialHandler(path: path, delegate: self)
		self.connect()
	}
	
	func connect() {
		self.serial.open()
	}
	
	func disconnect() {
		self.state = .invalid
		self.serial.close()
		self.stopTimer()
	}
	
	internal func serialDidChangeOpenState(_ isOpen: Bool, _ error: Error?) {
		self.state = .invalid
		self.idleTime = 0
		self.errorCode = 0
		self.errorMessage = error?.localizedDescription
		
		if(isOpen) {
			self.tick()
			self.startTimer()
		}
	}
	
	/**
	 * The Transition Function.
	 * Receive input and determine next state.
	 */
	internal func serialDidReceiveData(_ data: UInt16) {
		let oldState = self.state
		
		switch data {
		case 1...5:
			// 1 = Überlastung
			// 2 = HOT: Überdurchschnittliche Temperatur erreicht
			// 3-5 = Ungewöhnliche eleketrische Probleme
			self.state = .error
			self.errorCode = Int(data)
			
		case 10:
			self.state = .config
			
		case 11:
			self.state = .ready
			self.activeButton = .none
			
		case 12...14:
			self.state = .config
			self.activePreset = data == 12 ? .p1 : data == 13 ? .p2 : .p3
			self.desiredPreset = .none
			self.activeButton = .none
			
		case 400...2000:
			// release preset target, because controller knows where to go now
			if self.state == .ready && self.activeButton.isPreset {
				self.activeButton = .none
			}
			
			self.state = self.state == .invalid ? .ready : .busy
			self.height = Int(data)
			self.idleTime = 0
			
		case 0x5555:
			// if activeButton is a preset button, the run operation was interrupted
			if self.state != .busy || self.activeButton.isPreset {
				self.state = .ready
			} else {
				// remain in busy state, mainly for UI representation purposes
				let idleThreshold = self.activeButton == .none && self.activePreset == .none ? 2 : 10
				if self.idleTime >= idleThreshold {
					self.state = .ready
					self.activeButton = .none
				} else {
					self.idleTime += 1
				}
			}
			
		case 0x1111:
			self.state = .sleep
			
		default:
			print(data)
		}
		
		if oldState != self.state {
			self.tick()
			// restart the timer because its interval depends on the current state
			self.startTimer()
		} 
	}
	
	/**
	 * The Output Function.
	 * Use the current state and the state variables to determine the buttons which shall be pressed.
	 */
	@objc func tick() {
		if !self.serial.isConnected() {
			self.state = .invalid
			return
		}
		
		switch self.state {
		case .error:
			return
			
		case .invalid:
			self.sendReset()
			
		case .config:
			if self.desiredPreset != .none {
				self.sendButtonPress(self.desiredPreset)
			} else {
				// leave config state
				self.sendButtonPress(.m)
			}
			
		case .ready:
			if self.desiredPreset != .none {
				// enter config state
				self.sendButtonPress(.m)
			} else {
				self.sendButtonPress(self.activeButton)
			}
			
		case .busy:
			// interrupt current action to switch to another preset 
			if self.activeButton.isPreset {
				// send anything but the future button 
				self.sendButtonPress(self.activeButton == .p1 ? .p2 : .p1)
			} else {
				self.sendButtonPress(self.activeButton)
			}
			
		case .sleep:
			if self.activeButton != .none {
				// wake up
				self.sendButtonPress(.m)
			} else {
				self.sendKeepAlive()
			}
		}
	}
	
	func toggleButton(_ button: DeskButton) {
		self.activeButton = self.activeButton == button ? .none : button
		
		switch self.activeButton {
		case .p1, .p2, .p3:
			self.activePreset = self.activeButton
		default:
			self.activePreset = .none
		}
		
		self.tick()
	}
	
	func saveHeight(asPreset button: DeskButton) {
		self.desiredPreset = button
		self.tick()
	}
	
	private func startTimer() {
		let timeout = self.state == .sleep || self.state == .invalid ? 2 : self.state == .ready ? 0.5 : 0.15
		self.stopTimer()
		self.timer = Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
	}
	
	private func stopTimer() {
		self.timer?.invalidate()
		self.timer = nil
	}
	
	private func sendReset() {
		var data = Data(count: 1)
		data[0] = 0x77
		self.serial.send(data)
	}
	
	private func sendKeepAlive() {
		var data = Data(count: 1)
		data[0] = 0x11
		self.serial.send(data)
	}
	
	private func sendButtonPress(_ button: DeskButton) {
		var data = Data(count: 3)
		data[0] = 0xff
		data[1] = button.bit
		data[2] = data[1] // check byte to detect 1-bit errors
		self.serial.send(data)
	}
}
