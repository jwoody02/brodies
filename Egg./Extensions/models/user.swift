//
//  user.swift
//  Egg.
//
//  Created by Jordan Wood on 5/18/22.
//


import Foundation

struct User : Codable, Equatable {
    var uid: String
    var username: String
    var profileImageUrl: String
    var bio: String
    var followingCount: Int
    var followersCount: Int
    var postsCount: Int
    var fullname: String
    var hasValidStory: Bool
    var isFollowing: Bool
    var location: String?
    var isPrivate: Bool?
    var hasRequestedFollow: Bool? // have we requested to follow if private?
    var requestApproved: Bool? // have we been approved
    var isRecentSearch: Bool?
}

