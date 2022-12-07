//
//  ContentView.swift
//  LifeSpan Sync
//
//  Created by Dan Crosby on 12/7/22.
//

import SwiftUI

struct ContentView: View {
    let receiver = BluetoothWorkoutReceiver()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding().onAppear {
            receiver.setUp()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
