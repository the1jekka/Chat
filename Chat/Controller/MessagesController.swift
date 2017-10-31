//
//  ViewController.swift
//  Chat
//
//  Created by Admin on 24.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import Firebase

fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

class MessagesController: UITableViewController {

    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "newMessageIcon"), style: .plain, target: self, action: #selector(handleNewMessage))
        checkUserLogIn()
        //navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New ", style: .plain, target: self, action: #selector(handleNewMessage))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
    }
    
    var messages = Array<Message>()
    var messagesDictionary = Dictionary<String, Message>()
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let reference = Database.database().reference().child("user-messages").child(uid)
        reference.observe(.childAdded, with: {(snapshot) in
            let userId = snapshot.key
            let conversationReference = Database.database().reference().child("user-messages").child(uid).child(userId)
            conversationReference.observe(.childAdded, with: {(snapshot) in
                let messageId = snapshot.key
                self.fetchMessageAndAttemptReaload(messageId: messageId)
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    private func fetchMessageAndAttemptReaload(messageId: String) {
        let messageReference = Database.database().reference().child("messages").child(messageId)
        messageReference.observeSingleEvent(of: .value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String : AnyObject] {
                let message = Message(dictionary: dictionary)
                if let chatPartner = message.chatPartnerId() {
                    self.messagesDictionary[chatPartner] = message
                }
                self.attemptReloadTable()
            }
        }, withCancel: nil)
    }
    
    private func attemptReloadTable() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    var timer: Timer?
    
    @objc func handleReloadTable() {
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort{(message1, message2) -> Bool in
            return message1.timestamp > message2.timestamp
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func observeMessages() {
        let reference = Database.database().reference().child("messages")
        reference.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String : AnyObject] {
                let message = Message(dictionary: dictionary)
                if let receiver = message.receiver {
                    self.messagesDictionary[receiver] = message
                    self.messages = Array(self.messagesDictionary.values)
                    self.messages.sort{(message1, message2) -> Bool in
                        return message1.timestamp > message2.timestamp
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.row]
        cell.message = message
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        let reference = Database.database().reference().child("users").child(chatPartnerId)
        reference.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let dictionary = snapshot.value as? [String : AnyObject] else {
                return
            }
            let user = User(dictionary: dictionary)
            user.id = chatPartnerId
            self.showConversationController(forUser: user)
        }, withCancel: nil)
        
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    func checkUserLogIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            setupNavBarTitle()
        }
    }
    
    func setupNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: {(snapshot) in
            if let dict = snapshot.value as? [String : AnyObject] {
                let user = User(dictionary: dict)
                self.setupNavBarWithUser(user: user)
            }
        }, withCancel: nil)
    }
    
    func setupNavBarWithUser(user: User){
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        if let profileImageUrl = user.profileImageURL {
            profileImageView.loadImageUsingCacheWithUrl(urlString: profileImageUrl)
        }
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        containerView.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        containerView.addSubview(nameLabel)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        
        navigationItem.titleView = titleView
        
        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showConversationController)))
        
    }
    
    @objc func showConversationController(forUser user: User) {
        let conversationController = ConversationController(collectionViewLayout: UICollectionViewFlowLayout())
        conversationController.user = user
        navigationController?.pushViewController(conversationController, animated: true)
    }

    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

