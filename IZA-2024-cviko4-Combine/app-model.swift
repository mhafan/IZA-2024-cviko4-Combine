//
//  app-model.swift
//  IZA-2024-cviko4-Combine
//
//  Created by Martin Hruby on 24.04.2024.
//

import Foundation
import Combine


// ----------------------------------------------------------------------
// Zpracovani vstupu z libovolneho TextField (@Published)
func TextFieldProcessor(input: Published<String>.Publisher) -> AnyPublisher<String, Never>
{
    return input
        // chci samplovat s timto krokem
        .debounce(for: 0.5, scheduler: DispatchSerialQueue.main)
        // a filtrovat vyskyty duplikati
        .removeDuplicates()
        // ...
        .eraseToAnyPublisher()
}

// ----------------------------------------------------------------------
// Combine-style procedura, ktera stanovuje podminky "spravne vypadajiciho login"
// ----------------------------------------------------------------------
func CheckMyLogin(input: AnyPublisher<String, Never>) -> AnyPublisher<Bool, Never> {
    //
    input
        .map { txt in txt.count >= 3 }
        .eraseToAnyPublisher()
}

// ----------------------------------------------------------------------
// Combine-style procedura, ktera stanovuje podminky "spravne vypadajiciho password"
// ----------------------------------------------------------------------
func CheckMyPassword(input: AnyPublisher<String, Never>) -> AnyPublisher<Bool, Never> {
    //
    input
        .map { txt in txt.count >= 3 }
        .eraseToAnyPublisher()
}


// ----------------------------------------------------------------------
// Abstrakce nad user-defaults
extension UserDefaults {
    // ------------------------------------------------------------------
    //
    enum MyKeys: String {
        //
        case login = "myLogin"
        case passwd = "myPasswd"
    }
    
    // ------------------------------------------------------------------
    //
    subscript(key: MyKeys) -> String {
        get { self.string(forKey: key.rawValue) ?? "" }
        set { self.set(newValue, forKey: key.rawValue) }
    }
}


// ----------------------------------------------------------------------
// navratova hodnota z prihlasovani
enum MyLoginResponse {
    // je OK, tady je appkey
    case cool(appkey: String)
    
    //
    case badLoginPassword
}

// ----------------------------------------------------------------------
// Implementace dotazu na server pro prihlaseni uzivatele
func LoginRequest(login: String, Password: String) async -> MyLoginResponse {
    //
    let _workload = UInt64(2 * 1_000_000_000)
    
    // sleep vyhazuje vyjimku...mozne je dnes vsecko....
    try? await Task.sleep(nanoseconds: _workload)
    
    // :D
    // takhle to dnes rano vypadalo pri hlaseni do MS-Teams....ano, ano
    /*
    if Bool.random() {
        //
        return .badLoginPassword
    } */
    
    //
    return .cool(appkey: "cosi-kdesi")
}

// ----------------------------------------------------------------------
// zaobaleni vyse uvedene funkce do Future
func LoginRequestFuture(login: String, password: String) -> Future<MyLoginResponse, Never> {
    //
    return Future<MyLoginResponse, Never> { promise in
        //
        Task {
            //
            let _response = await LoginRequest(login: login, Password: password)
            
            //
            await MainActor.run {
                //
                promise(.success(_response))
            }
        }
    }
}

// ----------------------------------------------------------------------
// Oznacim cely objekt za MainActor - vsechny jeho funkce budou provadeny
// v hlavnim vlakne
@MainActor class AppModel: ObservableObject {
    // ------------------------------------------------------------------
    // Stav prihlasenni
    // - neprihlasen
    // - probiha overovani udaju
    // - je prihlasen
    enum LoginState {
        //
        case notLoggedIn
        case inProgress
        case iamIn
    }
    
    // ------------------------------------------------------------------
    // pro ucely logovaciho okna - lze vyclenit
    @Published var login: String = UserDefaults.standard[.login]
    @Published var password: String = UserDefaults.standard[.passwd]
    @Published var isLoginPasswordOK = false
    @Published var messageFromLogin = ""
    
    // ------------------------------------------------------------------
    // stav aplikace
    // - je/neni uzivatel prihlasen
    @Published var isLoggedIn = LoginState.iamIn
    @Published var shouldPresentLoginWindow = true
    
    // ------------------------------------------------------------------
    //
    static let shared = AppModel()
    
    // ------------------------------------------------------------------
    //
    private var _anies = Set<AnyCancellable>()
    private var _loginFuture: AnyCancellable? = nil
    
    // ------------------------------------------------------------------
    // dostal jsem zpravu o dotazu na log-in
    private func loginProcessGotResponse(response: MyLoginResponse) {
        // ... overuju
        assert(Thread.isMainThread)
        
        //
        switch response {
            //
        case .cool(appkey: let appkeyReceived):
            print(appkeyReceived)
            isLoggedIn = .iamIn
            
            //
        case .badLoginPassword:
            isLoggedIn = .notLoggedIn
            messageFromLogin = "chybne vsecko, naprosto..."
        }
    }
    
    // ------------------------------------------------------------------
    //
    private func loginProcessSwitch(to: LoginState, withMessage: String = "") {
        //
        self.isLoggedIn = to
        
        //
        switch to {
        case .notLoggedIn: ()
        case .inProgress:
            //
            UserDefaults.standard[.login] = login
            UserDefaults.standard[.passwd] = password
            //
            messageFromLogin = withMessage
        case .iamIn: ()
        }
    }
    
    // ------------------------------------------------------------------
    //
    func onLoginButton() {
        //
        loginProcessSwitch(to: .inProgress, withMessage: "")
        
        //
        Task {
            //
            let _response = await LoginRequest(login: login, Password: password)
            
            //
            loginProcessGotResponse(response: _response)
        }
    }
    
    // ------------------------------------------------------------------
    //
    func onLoginButton_futureVersion() {
        //
        loginProcessSwitch(to: .inProgress)
        
        //
        _loginFuture = LoginRequestFuture(login: login, password: password)
            .sink {
                //
                self.loginProcessGotResponse(response: $0)
            }
    }
    
    
    // ------------------------------------------------------------------
    //
    func onLogoutButton() {
        //
        loginProcessSwitch(to: .notLoggedIn, withMessage: "")
    }
    
    // ------------------------------------------------------------------
    // Sestaveni vazeb
    init() {
        // --------------------------------------------------------------
        // Publisher pro dva text-fields
        // - je login name ok
        // - je passwd ...
        let _loginProcessing = CheckMyLogin(input: TextFieldProcessor(input: $login))
        let _passwdProcessing = CheckMyPassword(input: TextFieldProcessor(input: $password))
        
        // --------------------------------------------------------------
        // spojuji tok obou udalosti
        Publishers.CombineLatest(_loginProcessing, _passwdProcessing)
            .map { (lOk, pOK) in lOk && pOK }
            .assign(to: \AppModel.isLoginPasswordOK, on: self)
            .store(in: &_anies)
        
        // --------------------------------------------------------------
        //
        $isLoggedIn
            .map { state in state != LoginState.iamIn }
            .assign(to: \AppModel.shouldPresentLoginWindow, on: self)
            .store(in: &_anies)
    }
}
