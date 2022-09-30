//
//  ArrowButton.swift
//  Schreibtisch
//

import SwiftUI

struct ToggleButtonStyle: ButtonStyle {
	var isOn: Bool
	
	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.padding(.vertical, 4)
			.padding(.horizontal, 10)
			.background(isOn ? Color.accentColor : configuration.isPressed
						? Color(NSColor(named: "popupButtonPressColor")!)
						: Color(NSColor(named: "popupButtonColor")!))
			.foregroundColor(isOn ? Color.white : Color.primary)
			.font(.system(size: 12))
	}
}

struct ArrowButton: View {
	@EnvironmentObject var desk: Desk
	
	let button: DeskButton
	
	var isPressed: Bool {
		desk.activeButton == button
	}
	
    var body: some View {
		Button(action: {
			desk.toggleButton(button)
		}) {
			Image(systemName:  "arrowtriangle.\(button == .up ? "up" : "down")\(isPressed ? ".fill" : "")")
		}
		.buttonStyle(ToggleButtonStyle(isOn: isPressed))
    }
}

struct ArrowButton_Previews: PreviewProvider {
    static var previews: some View {
		ArrowButton(button: .up)
			.environmentObject(Desk())
    }
}
