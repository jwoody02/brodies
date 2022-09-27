//
//  StoryObjects.swift
//  Egg.
//
//  Created by Jordan Wood on 9/23/22.
//

import Foundation
import UIKit
import SwiftUI
class AppData: ObservableObject {
    @Published var stories: Array<Story> = []
}

struct Story {
    var username: String
    var userImage: String
    var contents: [StoryContent]
    var lastUnseen: Int? {
        contents.firstIndex(where: { !$0.seen })
    }
}

struct StoryContent {
    var mediaURL: String
    var duration: Double = 1.0
    var seen: Bool = false
    var date: Date = Date()
}

