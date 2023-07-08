//
//  ContentView.swift
//  LifespanTester
//
//  Created by Dan Crosby on 11/30/22.
//

import SwiftUI

struct ContentView: View {
    let btc = BluetoothController()
    @State var listenForBluetooth: Bool
    
    var body: some View {
        VStack {
            Toggle("Listen for Treadmill",
                   isOn: $listenForBluetooth)
            .onChange(of: listenForBluetooth) { newValue in
                btc.listening = newValue
            }
        }
        .padding().onAppear {
            btc.setUp()
            btc.listening = listenForBluetooth
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(listenForBluetooth: true)
    }
}
