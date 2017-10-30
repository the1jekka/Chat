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
    
    static let blueColor = UIColor(r: 0, g: 137, b: 249)
    static let greyColor = UIColor(r: 240, g: 240, b: 240)
    
    let bubbleMessageView: UIView = {
        let view = UIView()
        view.backgroundColor = blueColor
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    var bubleMessageWidthAnchor: NSLayoutConstraint?
    var bubleMessageRightAnchor: NSLayoutConstraint?
    var bubleMessageLeftAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bubbleMessageView)
        addSubview(messageTextView)
        addSubview(profileImageView)
        
        setupProfileImageView()
        setupBubbleMessageView()
        setupMessageTextView()
    }
    
    func setupProfileImageView() {
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
    }
    
    func setupBubbleMessageView() {
        bubleMessageRightAnchor = bubbleMessageView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubleMessageRightAnchor?.isActive = true
        bubleMessageLeftAnchor = bubbleMessageView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        bubleMessageLeftAnchor?.isActive = false
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
