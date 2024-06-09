//
//  DataStore.swift
//  TWP4BG
//
//  Created by Sangmok Choi on 2023/08/11.
//

import Foundation

class DataStore {
    static let shared = DataStore()
    
    var userInputplaceList : [Place] = []
    
    var userInputEntry : [[String]] = []
    
    var userInputEntryTitle : String = ""
    var userInputEntrySubTitle : String = ""
    var userInputEntryTagColor : String = ""
    
    private init() {}
}
