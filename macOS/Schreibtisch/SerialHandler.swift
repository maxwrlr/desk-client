//
//  SerialHandler.swift
//  Schreibtisch
//

import Foundation
import ORSSerial

protocol SerialDelegate {
	func serialDidChangeOpenState(_ isOpen: Bool, _ error: Error?) -> Void
	func serialDidReceiveData(_ data: UInt16) -> Void
}

class SerialHandler: NSObject, ORSSerialPortDelegate {
	let path: String 
	
	private var port: ORSSerialPort?
	private var delegate: SerialDelegate
	
	private var buffer = Data(count: 3)
	private var bufferIndex = 0
	
	init(path: String, delegate: SerialDelegate) {
		self.path = path
		self.delegate = delegate
		super.init()
	}
	
	func isConnected() -> Bool {
		return self.port?.isOpen ?? false
	}
	
	func open() {
		if let port = self.port {
			port.open()
			return
		}
		
		if let port = ORSSerialPort(path: self.path) {
			self.port = port
			port.baudRate = 9600
			port.parity = .none
			port.numberOfStopBits = 1
			port.delegate = self
			port.open()
		}
	}
	
	func send(_ data: Data) {
		if let port = self.port {
			if port.isOpen {
				port.send(data)
			}
		}
	}
	
	func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
		self.delegate.serialDidChangeOpenState(false, error)
	}
	
	func serialPortWasOpened(_ serialPort: ORSSerialPort) {
		let descriptor = ORSSerialPacketDescriptor(prefixString: "", suffixString: "", maximumPacketLength: 1, userInfo: nil)
		serialPort.startListeningForPackets(matching: descriptor)
		self.delegate.serialDidChangeOpenState(true, nil)
	}
	
	func serialPort(_ serialPort: ORSSerialPort, didReceivePacket packetData: Data, matching descriptor: ORSSerialPacketDescriptor) {
		// push a data byte into the buffer
		if bufferIndex == 3 {
			buffer[0] = buffer[1]
			buffer[1] = buffer[2]
			buffer[2] = packetData[0]
		} else {
			buffer[bufferIndex] = packetData[0]
			bufferIndex += 1
		}
		
		// if the buffer is full, check if we have a valid message to emit
		if bufferIndex == 3 {
			let (checksum,_) = buffer[0].addingReportingOverflow(buffer[1])
			if checksum == buffer[2] {
				bufferIndex = 0
				let value = (UInt16(buffer[0]) << 8) | UInt16(buffer[1])
				self.delegate.serialDidReceiveData(value)
			}
		}
	}
	
	func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
		serialPort.close()
		serialPort.delegate = nil
		port = nil
		self.delegate.serialDidChangeOpenState(false, nil)
	}
	
	func close() {
		self.port?.close()
		self.delegate.serialDidChangeOpenState(false, nil)
	}
}
