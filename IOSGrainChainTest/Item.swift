//
//  Item.swift
//  IOSGrainChainTest
//
//  Created by Ricardo Developer on 23/04/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
