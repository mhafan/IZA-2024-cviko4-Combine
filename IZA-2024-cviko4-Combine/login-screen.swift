//
//  login-screen.swift
//  IZA-2024-cviko4-Combine
//
//  Created by Martin Hruby on 24.04.2024.
//

import Foundation
import SwiftUI
import Combine


// ----------------------------------------------------------------------
//
struct AppLoginWindow: View {
    // ------------------------------------------------------------------
    //
    @ObservedObject var vm = AppModel.shared
    
    // ------------------------------------------------------------------
    // Podoba logovaciho okna
    var body: some View {
        // cekam na spojeni se serverem (tocici se kolecko....)
        if vm.isLoggedIn == .inProgress {
            //
            Text("Trying to log in ....")
        } else {
            //
            Form {
                //
                if vm.messageFromLogin.isEmpty == false {
                    //
                    Text(vm.messageFromLogin)
                        .foregroundStyle(.red)
                }
                
                //
                Section("Login") {
                    //
                    TextField("login", text: $vm.login)
                        .autocorrectionDisabled()
                }
                
                Section("Password") {
                    //
                    TextField("password", text: $vm.password)
                        .autocorrectionDisabled()
                }
                
                //
                Button(action: vm.onLoginButton_futureVersion ) {
                    //
                    Text("Login")
                    //
                }.disabled(vm.isLoginPasswordOK == false)
            }
        }
    }
}
