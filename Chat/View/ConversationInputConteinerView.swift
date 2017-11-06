//
//  ConversationInputConteinerView.swift
//  Chat
//
//  Created by Admin on 06.11.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class ConversationInputContainerView: UIView, UITextFieldDelegate {
    
    var conversationController: ConversationController? {
        didSet {
            sendButton.addTarget(conversationController, action: #selector(ConversationController.handleSend), for: .touchUpInside)
            attachImageView.addGestureRecognizer(UITapGestureRecognizer(target: conversationController, action: #selector(ConversationController.handleAttachImageTap)))
        }
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter a message"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    let sendButton: UIButton = {
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        return sendButton
    }()
    
    let attachImageView: UIImageView = {
        let attachImageView = UIImageView()
        attachImageView.image = UIImage(named: "attachIcon")
        attachImageView.translatesAutoresizingMaskIntoConstraints = false
        attachImageView.isUserInteractionEnabled = true
        return attachImageView
    }()
    
    let separatorLine: UIView = {
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        return separatorLine
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(attachImageView)
        addSubview(sendButton)
        addSubview(inputTextField)
        addSubview(separatorLine)
        
        setupAttachImageView()
        setupSendButton()
        setupInputTextField()
        setupSeparatorLine()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        conversationController?.handleSend()
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupAttachImageView() {
        attachImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        attachImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        attachImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        attachImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    func setupSendButton() {
        sendButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
    
    func setupInputTextField() {
        inputTextField.leftAnchor.constraint(equalTo: attachImageView.rightAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
    
    func setupSeparatorLine() {
        separatorLine.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorLine.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        separatorLine.topAnchor.constraint(equalTo: topAnchor).isActive = true
        separatorLine.bottomAnchor.constraint(equalTo: topAnchor, constant: 1).isActive = true
    }
}
