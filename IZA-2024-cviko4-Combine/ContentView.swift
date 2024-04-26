//
//  ContentView.swift
//  IZA-2024-cviko4-Combine
//
//  Created by Martin Hruby on 24.04.2024.
//

import SwiftUI
import Combine


// ----------------------------------------------------------------------
//
func pinga() async -> String {
    //
    await URLRequest.FOR(.ping).givemeAsync(errValue: MyBasicURLResponse.errValue).body
}

// ----------------------------------------------------------------------
//
func pingMe3times() async -> String {
    //
    var _out = ""
    
    //
    for _ in 0..<3 {
        //
        _out += await pinga()
    }
    
    //
    return _out
}

// ----------------------------------------------------------------------
//
func pingMe3timesInParal() async -> String {
    //
    //
    async let _a = pinga()
    async let _b = pinga()
    async let _c = pinga()
    
    //
    return await (_a + _b + _c)
}


// ----------------------------------------------------------------------
//
struct Page1: View {
    // ------------------------------------------------------------------
    //
    @State var cosi = ""
    @State var _cancik: AnyCancellable?
    @ObservedObject var appmodel = AppModel.shared
    
    // ------------------------------------------------------------------
    //
    var body: some View {
        //
        NavigationView {
            //
            VStack {
                //
                Text("Odpoved: \(cosi)")
                
                //
                Spacer()
                
                //
                Button("zmackni-async") {
                    //
                    self.cosi = "..."
                    
                    //
                    Task {
                        //
                        let _value = await URLRequest.FOR(.ping).givemeAsync(errValue: MyBasicURLResponse.errValue)
                        
                        // predpokladam GlobalThread
                        DispatchQueue.main.async {
                            //
                            self.cosi = _value.body
                        }
                    }
                }
                
                //
                Button("zmackni-async-3") {
                    //
                    self.cosi = "..."
                    
                    //
                    Task {
                        //
                        let _value = await pingMe3timesInParal()
                        
                        // predpokladam GlobalThread
                        DispatchQueue.main.async {
                            //
                            self.cosi = _value
                        }
                    }
                }
                
                //
                Button("zmackni-sink") {
                    //
                    self.cosi = "..."
                    
                    //
                    _cancik = URLRequest.FOR(.ping)
                        .givemePublisher(errValue: MyBasicURLResponse.errValue)
                        .sink { _value in
                            // ocekavam MainThread
                            self.cosi = _value.body
                        }
                }
            }
            
            .toolbar {
                //
                HStack {
                    //
                    Button(action: appmodel.onLogoutButton) { Text("Logout") }
                }
            }
        }
    }
}


// ----------------------------------------------------------------------
//
struct MyTestDataVMRow: View {
    //
    let item: MyTestDataVM
    
    //
    var body: some View {
        //
        HStack {
            //
            Text(item.header.name)
            Spacer()
            Text("\(item.counter)")
        }
    }
}

// ----------------------------------------------------------------------
//
struct Page2: View {
    // ------------------------------------------------------------------
    //
    @StateObject var req = TestDataModel()
    
    // ------------------------------------------------------------------
    //
    var body: some View {
        //
        NavigationView {
            VStack {
                //
                List(req.tobePresented) { i in
                    //
                    MyTestDataVMRow(item: i)
                }
            }.searchable(text: $req.filter)
        }
    }
}

// ----------------------------------------------------------------------
//
struct Page3: View {
    // ------------------------------------------------------------------
    //
    @StateObject var model = RepeatModel()
    
    // ------------------------------------------------------------------
    //
    var body: some View {
        //
        VStack {
            //
            TextField("dej pocet", value: $model.number, format: .number)
            
            //
            List(model.result, id: \.self) { i in
                //
                Text(i)
            }
        }
    }
}


// ----------------------------------------------------------------------
//
struct ContentView: View {
    // ------------------------------------------------------------------
    //
    @ObservedObject var appmodel = AppModel.shared
    
    // ------------------------------------------------------------------
    //
    var body: some View {
        //
        TabView {
            //
            Page1().tabItem { Text("1-dotaz") }
            Page2().tabItem { Text("Seznam-dotaz") }
            Page3().tabItem { Text("Repeater")}
        }
        
        // logovaci okno, ktereho se uzivatel nezbavi, dokud se neprihlasi
        .fullScreenCover(isPresented: $appmodel.shouldPresentLoginWindow) {
            //
            AppLoginWindow()
        }
    }
}

#Preview {
    ContentView()
}
