//
//  ContentView.swift
//  Schreibtisch
//

import SwiftUI

struct ContentView: View {
	@StateObject var desk = Desk(path: UserDefaults.standard.string(forKey: "serialPort")!)
	@State var isOn = true
	
	let formatter = NumberFormatter()

	init() {
		formatter.minimumFractionDigits = 1
		formatter.maximumFractionDigits = 1
	}
	
	var body: some View {
		VStack(spacing: 8) {
			HStack {
				Text("Schreibtisch")
					.bold()
				Spacer()
				Toggle("", isOn: $isOn)
					.labelsHidden()
					.toggleStyle(SwitchToggleStyle(tint: .accentColor))
					.onChange(of: isOn) { value in
						if(value) {
							desk.connect()
						} else {
							desk.disconnect()
						}
					}
			}
			.padding(.bottom, 2)
			
			Divider()
			
			VStack {
				HStack(alignment: .center) {
					VStack(alignment: .leading) {
						Text("Aktuelle Höhe")
							.bold()
							.foregroundColor(.secondary)
						Text(desk.height > 0 ? "\(Float(desk.height) / 10 as NSNumber, formatter: formatter)cm" : "---")
					}
					
					Spacer()
					
					if desk.state == .busy {
						ProgressView()
							.scaleEffect(0.5)
					} else if desk.state == .sleep {
						Image(systemName: "powersleep")
					} else if desk.state == .error {
						Text(String(desk.errorCode))
							.foregroundColor(.red)
					}
				}
				
				if let error = desk.errorMessage {
					Text(error)
						.foregroundColor(.red)
				}
			}
			
			Divider()
			
			HStack {
				VStack(spacing: 0) {
					ArrowButton(button: .up)
					ArrowButton(button: .down)
				}
				.cornerRadius(5)
				
				Spacer()
				
				HStack {
					PresetButton(button: .p1)
					PresetButton(button: .p2)
					PresetButton(button: .p3)
				}
				
			}
			.environmentObject(desk)
		}
		.padding(.vertical, 10)
		.padding(.horizontal, 14)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
