//
//  ViewController.swift
//  Chat
//
//  Created by Admin on 24.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn
import TwitterKit

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

    private let cellId = "cellId"
    private var timer: Timer?
    private var messages = Array<Message>()
    private var messagesDictionary = Dictionary<String, Message>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configure()
        self.checkUserLogIn()
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        self.deleteConversation(indexPath: indexPath)
    }
    
    private func attemptReloadTable() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
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
        self.showConversationControllerForUser(indexPath: indexPath)
    }
    
    
    
    func setupNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            if let dict = snapshot.value as? [String : AnyObject] {
                let user = User(dictionary: dict)
                strongSelf.setupNavBarWithUser(user: user)
            }
        }, withCancel: nil)
    }
}

// MARK: -
// MARK: - Configure

extension MessagesController {
    private func configure() {
        self.setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "newMessageIcon"), style: .plain, target: self, action: #selector(handleNewMessage))
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
}

// MARK: -
// MARK: - Functions For Tableview

fileprivate extension MessagesController {
    func deleteConversation(indexPath: IndexPath) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let message = messages[indexPath.row]
        
        if let chatPartnerId = message.chatPartnerId() {
            Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, reference) in
                if let removeError = error {
                    print("Failed to delete: \(removeError)")
                    return
                }
                
                self.messagesDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadTable()
                //self.messages.remove(at: indexPath.row)
                //self.tableView.deleteRows(at: [indexPath], with: .automatic)
            })
        }
    }
    
    @objc func handleReloadTable() {
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort{(message1, message2) -> Bool in
            return message1.timestamp > message2.timestamp
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

// MARK: -
// MARK: - Messages Action

fileprivate extension MessagesController {
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let reference = Database.database().reference().child("user-messages").child(uid)
        reference.observe(.childAdded, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            let userId = snapshot.key
            let conversationReference = Database.database().reference().child("user-messages").child(uid).child(userId)
            conversationReference.observe(.childAdded, with: {(snapshot) in
                let messageId = snapshot.key
                strongSelf.fetchMessageAndAttemptReaload(messageId: messageId)
            }, withCancel: nil)
            }, withCancel: nil)
        reference.observe(.childRemoved, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            strongSelf.messagesDictionary.removeValue(forKey: snapshot.key)
        }, withCancel: nil)
    }
    
    private func fetchMessageAndAttemptReaload(messageId: String) {
        let messageReference = Database.database().reference().child("messages").child(messageId)
        messageReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            if let dictionary = snapshot.value as? [String : AnyObject] {
                let message = Message(dictionary: dictionary)
                if let chatPartner = message.chatPartnerId() {
                    strongSelf.messagesDictionary[chatPartner] = message
                }
                strongSelf.attemptReloadTable()
            }
            }, withCancel: nil)
    }
    
    func observeMessages() {
        let reference = Database.database().reference().child("messages")
        reference.observe(.childAdded, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            if let dictionary = snapshot.value as? [String : AnyObject] {
                let message = Message(dictionary: dictionary)
                if let receiver = message.receiver {
                    strongSelf.messagesDictionary[receiver] = message
                    strongSelf.messages = Array((self?.messagesDictionary.values)!)
                    strongSelf.messages.sort{(message1, message2) -> Bool in
                        return message1.timestamp > message2.timestamp
                    }
                }
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
            }, withCancel: nil)
    }
}

// MARK: -
// MARK: - Transitions

extension MessagesController {
    @objc private func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    private func showConversationControllerForUser(indexPath: IndexPath) {
        let message = messages[indexPath.row]
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        let reference = Database.database().reference().child("users").child(chatPartnerId)
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            guard let dictionary = snapshot.value as? [String : AnyObject] else {
                return
            }
            let user = User(dictionary: dictionary)
            user.id = chatPartnerId
            strongSelf.showConversationController(forUser: user)
            }, withCancel: nil)
    }
    
    @objc func showConversationController(forUser user: User) {
        let conversationController = ConversationController(collectionViewLayout: UICollectionViewFlowLayout())
        conversationController.user = user
        navigationController?.pushViewController(conversationController, animated: true)
    }
    
    @objc private func handleLogout() {
        checkSocialLogin()
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }
}

// MARK: -
// MARK: - User Auth State

fileprivate extension MessagesController {
    func checkUserLogIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            setupNavBarTitle()
        }
    }
    
    func checkFacebookLogin() {
        if FBSDKAccessToken.current() != nil {
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        }
    }
    
    func checkGoogleLogin() {
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            GIDSignIn.sharedInstance().signOut()
        }
    }
    
    func checkTwitterLogin() {
        let sessionStore = Twitter.sharedInstance().sessionStore
        
        if let userID = sessionStore.session()?.userID {
            sessionStore.logOutUserID(userID)
        }
    }
    
    func checkSocialLogin() {
        checkFacebookLogin()
        checkGoogleLogin()
        checkTwitterLogin()
    }
}
