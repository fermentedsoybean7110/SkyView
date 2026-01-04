//
//  Item.swift
//  SkyView
//
//  Created by 宮坂信城 on 2026/01/04.
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
