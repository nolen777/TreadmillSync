//
//  ContentView.swift
//  LifespanTester
//
//  Created by Dan Crosby on 11/30/22.
//

import SwiftUI

struct ContentView: View {
    let btc = BluetoothController()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding().onAppear {
            btc.setUp()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
