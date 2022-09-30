//
//  PresetButton.swift
//  Schreibtisch
//

import SwiftUI
import CoreGraphics

struct RoundedButtonStyle: ButtonStyle {
	var isOn: Bool
	
	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.buttonStyle(.plain)
			.frame(width: 36, height: 36, alignment: .center)
			.background(isOn ? Color.accentColor : configuration.isPressed
						? Color(NSColor(named: "popupButtonPressColor")!)
						: Color(NSColor(named: "popupButtonColor")!))
			.foregroundColor(isOn ? Color.white : Color.primary)
			.buttonStyle(.borderless)
			.clipShape(Circle())
	}
}

struct PresetButton: View {
	@EnvironmentObject var desk: Desk
	
	let button: DeskButton
	
	var body: some View {
		Button(action: {
			// if option key is pressed: set current height to preset
			if CGEventSource.keyState(.combinedSessionState, key: 0x3A) {
				desk.saveHeight(asPreset: button)
			} else {
				desk.toggleButton(button)
			}
		}) {
			if desk.desiredPreset == button {
				ProgressView()
					.scaleEffect(0.5)
			} else {
				Text(String(button.rawValue))
			}
		}
		.buttonStyle(RoundedButtonStyle(isOn: desk.activePreset == button))
	}
}

struct PresetButton_Previews: PreviewProvider {
	static var previews: some View {
		PresetButton(button: .p1)
			.environmentObject(Desk())
	}
}
