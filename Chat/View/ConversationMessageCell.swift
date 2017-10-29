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
        textView.backgroundColor = .clear
        textView.textColor = .white
        return textView
    }()
    
    let bubbleMessageView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 0, g: 137, b: 249)
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var bubleMessageWidthAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bubbleMessageView)
        setupBubbleMessageView()
        setupMessageTextView()
    }
    
    func setupBubbleMessageView() {
        bubbleMessageView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8).isActive = true
        bubbleMessageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubleMessageWidthAnchor = bubbleMessageView.widthAnchor.constraint(equalToConstant: 200)
        bubleMessageWidthAnchor?.isActive = true
        bubbleMessageView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
    
    func setupMessageTextView() {
        messageTextView.leftAnchor.constraint(equalTo: bubbleMessageView.leftAnchor, constant: 8).isActive = true
        messageTextView.rightAnchor.constraint(equalTo: bubbleMessageView.rightAnchor).isActive = true
        messageTextView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        messageTextView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
