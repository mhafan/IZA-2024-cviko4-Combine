//
//  TestDataModel.swift
//  IZA-2024-cviko4-Combine
//
//  Created by Martin Hruby on 25.04.2024.
//

import Foundation
import Combine


// ----------------------------------------------------------------------
// @Observable (obdoba ObservableObject)
@Observable class MyTestDataVM: Identifiable {
    // ------------------------------------------------------------------
    //
    let header: MyTestData
    
    // ------------------------------------------------------------------
    // property je sledovana ze strany View automaticky
    var counter = 0
    
    // ------------------------------------------------------------------
    //
    private var _selectionSubs: AnyCancellable?
    
    // ------------------------------------------------------------------
    // je objekt vybran
    func selection(on: Bool) {
        //
        if on {
            // ale jeste v nem nenastartoval proces
            if _selectionSubs == nil {
                //
                _selectionSubs = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink {_ in 
                    //
                    self.counter += 1
                }
            }
        } else {
            //
            _selectionSubs = nil
        }
    }
    
    // ------------------------------------------------------------------
    //
    init(header: MyTestData) {
        //
        self.header = header
    }
}


// ----------------------------------------------------------------------
// Zpusob probedeni REST API dotazu
// - jednorazovy
class TestDataModel: ObservableObject {
    // ------------------------------------------------------------------
    // vysledek dotazu, original
    @Published var originalInput: [MyTestDataVM] = []
    @Published var tobePresented: [MyTestDataVM] = []
    @Published var filter: String = ""
    @Published var inSelectionProcess = false
    
    // ------------------------------------------------------------------
    //
    @Published var selected: MyTestData? = nil
    
    // ------------------------------------------------------------------
    //
    private var _subs: AnyCancellable?
    private var _anies = Set<AnyCancellable>()
    
    // ------------------------------------------------------------------
    //
    private func process(_ inp: [MyTestDataVM], filt: String) -> [MyTestDataVM] {
        //
        guard filt.isEmpty == false else { return inp; }
        
        //
        let _filt = filt.lowercased()
        
        //
        return inp.filter { $0.header.name.lowercased().range(of: _filt) != nil }
    }
    
    // ------------------------------------------------------------------
    //
    private func setupProcess(selected: [MyTestDataVM], running: Bool) {
        //
        originalInput.forEach { $0.selection(on: false) }
        
        //
        if running {
            //
            selected.forEach { $0.selection(on: true) }
        }
    }
    
    // ------------------------------------------------------------------
    //
    init() {
        // --------------------------------------------------------------
        // Proved dotaz a de-alokuj retezec Publisher->Subsriber
        _subs = URLRequest.FOR(.testdata)
            .givemePublisher(errValue: [MyTestData]())
            .sink { inValue in
                // prevezmu data
                self.originalInput = inValue.map { MyTestDataVM(header: $0) }
                // provadim Cancel() na AnyCancellable
                self._subs = nil
            }
        
        // --------------------------------------------------------------
        // Kombinace dvou toku
        Publishers.CombineLatest($originalInput, TextFieldProcessor(input: $filter))
            .map { (dt:[MyTestDataVM], flt: String) in self.process(dt, filt: flt) }
            .assign(to: \TestDataModel.tobePresented, on: self)
            .store(in: &_anies)
        
        // --------------------------------------------------------------
        // pokud je filter != "", pak
        $filter
            .map { $0.isEmpty == false }
            // nepropusti dve stejne hodnoty, tj propusti jenom zmenu
            // false -> true, true -> false
            .removeDuplicates()
            .print()
            .assign(to: \TestDataModel.inSelectionProcess, on: self)
            .store(in: &_anies)
        
        // --------------------------------------------------------------
        //
        Publishers.CombineLatest($tobePresented, $inSelectionProcess)
            .sink { inSelection, selRunning in
                //
                self.setupProcess(selected: inSelection, running: selRunning)
            }
            .store(in: &_anies)
    }
}
