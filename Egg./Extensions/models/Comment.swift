//
//  Comment.swift
//  Egg.
//
//  Created by Jordan Wood on 5/18/22.
//

import Foundation

struct Comment {
    
    let user: User
    let text: String
    let uid: String
//    let creationDate: Date
    
    init(user: User, dictionary: [String: Any]) {
        self.user = user
        self.text = dictionary["text"] as? String ?? ""
        self.uid = dictionary["uid"] as? String ?? ""
//        self.creationDate = dictionary["creationDate"] as? Date
    }
    
}
