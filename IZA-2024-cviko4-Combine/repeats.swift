//
//  repeats.swift
//  IZA-2024-cviko4-Combine
//
//  Created by Martin Hruby on 25.04.2024.
//

import Foundation
import Combine


// ----------------------------------------------------------------------
// ukazka zpracovani sekvence pozadavku
func procArray(of: [Int]) -> AnyPublisher<[String], Never> {
    // publisher nad polem - publikuje posloupnost iterovanim
    // a na zaver EOF
    of.publisher
        // kazdy prvek se zpracuje
        .map { String(repeating: "a", count: $0) }
        // a udela souhrn
        .collect()
        .eraseToAnyPublisher()
}

// ----------------------------------------------------------------------
//
class RepeatModel: ObservableObject {
    // ------------------------------------------------------------------
    //
    @Published var result: [String] = []
    @Published var number: Int = 10
    
    // ------------------------------------------------------------------
    //
    private var _subs: AnyCancellable?
    
    // ------------------------------------------------------------------
    //
    func gen(_ v: Int) -> [Int] {
        //
        var _out = [Int]()
        
        //
        for i in 0..<v { _out.append(i) }
        
        //
        return _out
    }
    
    // ------------------------------------------------------------------
    //
    init() {
        //
        _subs = $number
                    .flatMap { procArray(of: self.gen($0)) }
                    .assign(to: \RepeatModel.result, on: self)
    }
}
