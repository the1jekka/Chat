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
    
    init(dictionary: Dictionary<String, Any>) {
        self.sender = dictionary["senderId"] as? String
        self.receiver = dictionary["receiverId"] as? String
        self.text = dictionary["text"] as? String
        self.timestamp = dictionary["timestamp"] as? Int
    }
    
    func chatPartnerId() -> String? {
        return sender == Auth.auth().currentUser?.uid ? sender : receiver
    }
}
