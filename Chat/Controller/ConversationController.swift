//
//  ConversationController.swift
//  Chat
//
//  Created by Admin on 27.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import Firebase

class ConversationController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout {
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    
    var messages = Array<Message>()
    
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let userMessagesReference = Database.database().reference().child("user-messages").child(uid)
        userMessagesReference.observe(.childAdded, with: {(snapshot) in
            let messageId = snapshot.key
            let messagesReference = Database.database().reference().child(messageId)
            messagesReference.observeSingleEvent(of: .value, with: {(snapshot) in
                guard let dictionary = snapshot.value as? [String : AnyObject] else {
                    return
                }
                let message = Message()
                message.setValuesForKeys(dictionary)
                if message.chatPartnerId() == self.user?.id {
                    self.messages.append(message)
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                    }
                }
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter a message"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = .white
        collectionView?.register(ConversationMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        setupInputs()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ConversationMessageCell
        let message = messages[indexPath.item]
        cell.messageTextView.text = message.text
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 88)
    }
    
    func setupInputs() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(inputTextField)
        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLine)
        separatorLine.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        containerView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: 1).isActive = true
        
    }
    
    @objc func handleSend()  {
        let reference = Database.database().reference().child("messages")
        let childReference = reference.childByAutoId()
        let senderId = Auth.auth().currentUser?.uid
        let receiverId = user?.id!
        let timestamp: Int = Int(NSDate().timeIntervalSince1970)
        let values = ["text" : inputTextField.text!, "senderId" : senderId, "receiverId" : receiverId, "timestamp" : timestamp] as [String : Any]
        //reference.updateChildValues(values)
        childReference.updateChildValues(values, withCompletionBlock: {(error, ref) in
            if error != nil {
                print(error)
                return
            }
            let userMessagesReference = Database.database().reference().child("user-messages").child(senderId!)
            let messageId = childReference.key
            userMessagesReference.updateChildValues([messageId: 1])
            let recipientUserMessagesReference = Database.database().reference().child("user-messages").child(receiverId!)
            recipientUserMessagesReference.updateChildValues([messageId: 1])
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
