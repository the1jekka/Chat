//
//  NewMessageController.swift
//  Chat
//
//  Created by Admin on 26.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {

    private let cellId = "cellId"
    private var users = Array<User>()
    var messagesController: MessagesController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        self.configure()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell
        let user = users[indexPath.row]
        cell?.textLabel?.text = user.name!
        cell?.detailTextLabel?.text = user.email!
        if let userProfileImageURL = user.profileImageURL {
            cell?.profileImageView.loadImageUsingCacheWithUrl(urlString: userProfileImageURL)
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.startConversation(indexPath: indexPath)
    }
}

// MARK: -
// MARK: - Configure

fileprivate extension NewMessageController {
    func configure() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        self.fetchUser()
    }
    
    func fetchUser() {
        Database.database().reference().child("users").observe(.childAdded, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            if let dict = snapshot.value as? [String : AnyObject] {
                let user = User(dictionary: dict)
                user.id = snapshot.key
                strongSelf.users.append(user)
                
                DispatchQueue.main.async {
                    strongSelf.tableView.reloadData()
                }
                
            }
            }, withCancel: nil)
    }
}

// MARK: -
// MARK: - Transitions

fileprivate extension NewMessageController {
    @objc func handleCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func startConversation(indexPath: IndexPath) {
        self.dismiss(animated: true) {
            let user = self.users[indexPath.row]
            self.messagesController?.showConversationController(forUser: user)
        }
    }
}
