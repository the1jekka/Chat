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
    
    func chatPartnerId() -> String? {
        if sender == Auth.auth().currentUser?.uid {
            return receiver
        } else {
            return sender
        }
    }
}
