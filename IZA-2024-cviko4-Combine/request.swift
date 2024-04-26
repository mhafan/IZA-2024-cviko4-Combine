//
//  request.swift
//  IZA-2024-cviko4-Combine
//
//  Created by Martin Hruby on 24.04.2024.
//

import Foundation
import Combine

// ----------------------------------------------------------------------
// Seznam vsech znamych dotazu na AWS/GateAPI
enum GateWayRequest {
    //
    case ping
    case testdata
}

// ----------------------------------------------------------------------
//
enum GateWayErrors: Error {
    //
    case unspecified
}


// ----------------------------------------------------------------------
// JSON vstup pro #2 demo
struct MyTestData: Codable {
    //
    let name: String
    let language: String
    let id: String
    let bio: String
    let version: Double
}

// ----------------------------------------------------------------------
//
extension URLRequest {
    // ------------------------------------------------------------------
    // x-api-key do GateWayAPI
    // ----------------------------------------------------------------------
    // TODO: promyslet nejakou lepsi metodu evidence klice
    static let _InternalAPIKey = "oYtqq1dke19CpnFxYGEae8oYrjtttjWH2Wj4XAaT"

    // ------------------------------------------------------------------
    // Konstrukce URLRequest pro moje dotazy do AWS/GateAPI
    static func FOR(_ forR: GateWayRequest) -> URLRequest {
        // cilovy end-point
        var _url: URL?
        
        //
        switch forR {
        case .ping:
            _url = URL(string: "https://api.mhafan.link/pok1/ping")
        case .testdata:
            _url = URL(string: "https://api.mhafan.link/pok1/testdata")
        }
        
        //
        guard let __url = _url else { fatalError("Nezname cosi... \(forR)") }
        
        //
        return URLRequest(url: __url).apiKeyed
    }
    
    // ------------------------------------------------------------------
    //
    var apiKeyed: URLRequest {
        //
        var _copy = self
        
        //
        _copy.addValue(URLRequest._InternalAPIKey, forHTTPHeaderField: "x-api-key"); return _copy
    }
}

// ----------------------------------------------------------------------
//
struct MyBasicURLResponse: Codable {
    //
    let statusCode: Int
    let body: String
    
    //
    static let errValue: MyBasicURLResponse = {
        //
        MyBasicURLResponse(statusCode: 404, body: "proste ne, ne, ne")
    }()
}

// ----------------------------------------------------------------------
// Spousteni URL dotazu: konvencni
// ----------------------------------------------------------------------
// "action" je volano v rezimu MainThread
extension URLRequest {
    // ------------------------------------------------------------------
    // Inicializuje URL dotaz a vysledek preda pres MainThread
    func processAsData(action: @escaping (Data) -> ()) {
        // sestaveni dotazu
        let task = URLSession.shared.dataTask(with: self) { (data, response, error) in
            //
            guard
                error == nil,
                let _data = data
            else {
                //
                return
            }
            
            // ted jsem typicky v GlobalThread -> jdu do MainThread
            DispatchQueue.main.async {
                //
                action(_data)
            }
        }
        
        // aktivace dotazu
        task.resume()
    }
    
    // ------------------------------------------------------------------
    //
    func processAsString(action: @escaping (String) -> ()) {
        //
        processAsData { dataFrom in
            //
            let dataString = String(decoding: dataFrom, as: UTF8.self)
            
            //
            action(dataString)
        }
    }
    
    // ------------------------------------------------------------------
    //
    func processAsMyResponse(action: @escaping (MyBasicURLResponse) -> ()) {
        //
        processAsData { dataFrom in
            //
            if let _decoded = try? JSONDecoder().decode(MyBasicURLResponse.self, from: dataFrom) {
                //
                action(_decoded)
            }
        }
    }
}


// ----------------------------------------------------------------------
//
extension URLRequest {
    // ------------------------------------------------------------------
    // vytvori URL dotaz jako Future -> Data
    func givemeFuture() -> Future<Data, GateWayErrors> {
        //
        Future<Data, GateWayErrors> { promise in
            // sestaveni dotazu
            let task = URLSession.shared.dataTask(with: self) { (data, response, error) in
                //
                guard
                    error == nil,
                    let _data = data
                else {
                    //
                    promise(.failure(.unspecified)); return
                }
                
                //
                promise(.success(_data))
            }
            
            // aktivace dotazu
            task.resume()
        }
    }
    
    // ------------------------------------------------------------------
    //
    func givemePublisher<Value:Codable>(errValue: Value) -> AnyPublisher<Value, Never> {
        //
        URLSession.shared.dataTaskPublisher(for: self)
            .print()
            .receive(on: RunLoop.main)
            .map(\.data)
            .decode(type: Value.self, decoder: JSONDecoder())
            .print()
            .replaceError(with: errValue)
            .eraseToAnyPublisher()
    }
    
    // ------------------------------------------------------------------
    //
    func givemePublisherFromFuture<Value:Codable>(errValue: Value) -> AnyPublisher<Value, Never> {
        //
        givemeFuture()
            .receive(on: RunLoop.main)
            .decode(type: Value.self, decoder: JSONDecoder())
            .replaceError(with: errValue)
            .eraseToAnyPublisher()
    }
    
    // ------------------------------------------------------------------
    //
    func givemePublisherFromFutureE() -> AnyPublisher<MyBasicURLResponse, Error> {
        //
        givemeFuture()
            .receive(on: RunLoop.main)
            .decode(type: MyBasicURLResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // ------------------------------------------------------------------
    //
    func givemeAsync<Value>(errValue: Value) async -> Value where Value: Codable {
        //
        if let (_data, _response) = try? await URLSession.shared.data(for: self) {
            //
            print(_response)
            
            //
            if let _decos = try? JSONDecoder().decode(Value.self, from: _data) {
                //
                return _decos
            }
        }
        
        //
        return errValue
    }
}

