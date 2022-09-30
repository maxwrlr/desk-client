//
//  SettingsView.swift
//  Schreibtisch
//

import SwiftUI

struct SettingsView: View {
	@AppStorage("serialPort") private var serialPort = ""

	@FocusState private var isFocused: Bool
	
    var body: some View {
		Form {
			TextField("Port", text: $serialPort)
		}
		.padding()
		.frame(width: 300, height: 75)
		.focused($isFocused)
		.onAppear {
			isFocused = true
		}
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
