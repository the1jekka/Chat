//
//  Message.swift
//  Chat
//
//  Created by Admin on 27.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    var sender: String?
    var receiver: String?
    var text: String?
    var timestamp: Int?
    
    var imageUrl: String?
    var imageWidth: Int?
    var imageHeight: Int?
    
    var videoUrl: String?
    
    init(dictionary: Dictionary<String, Any>) {
        self.sender = dictionary["senderId"] as? String
        self.receiver = dictionary["receiverId"] as? String
        self.text = dictionary["text"] as? String
        self.timestamp = dictionary["timestamp"] as? Int
        self.imageUrl = dictionary["imageUrl"] as? String
        self.imageWidth = dictionary["imageWidth"] as? Int
        self.imageHeight = dictionary["imageHeight"] as? Int
        self.videoUrl = dictionary["videoUrl"] as? String
    }
    
    func chatPartnerId() -> String? {
        return sender == Auth.auth().currentUser?.uid ? receiver : sender
    }
}
