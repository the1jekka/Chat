//
//  ConversationMessageCell.swift
//  Chat
//
//  Created by Admin on 29.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class ConversationMessageCell: UICollectionViewCell {

    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(messageTextView)
        setupMessageTextView()
    }
    
    func setupMessageTextView() {
        messageTextView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        messageTextView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        messageTextView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        messageTextView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
