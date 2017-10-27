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

    let cellId = "cellId"
    var users = Array<User>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUser()
    }
    
    func fetchUser() {
        Database.database().reference().child("users").observeSingleEvent(of: .childAdded, with: {(snapshot) in
            if let dict = snapshot.value as? [String : AnyObject] {
                let user = User()
                user.setValuesForKeys(dict)
                self.users.append(user)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell
        let user = users[indexPath.row]
        cell?.textLabel?.text = user.name
        cell?.detailTextLabel?.text = user.email
        if let userProfileImageURL = user.profileImageURL {
            cell?.profileImageView.loadImageUsingCacheWithUrl(urlString: userProfileImageURL)
        }
        
        return cell!
    }
}

class UserCell: UITableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.translatesAutoresizingMaskIntoConstraints = false
        setupTextLabel()
        setupDetailTextLabel()
        
    }
    
    func setupTextLabel() {
        textLabel?.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        textLabel?.widthAnchor.constraint(equalTo: (textLabel?.widthAnchor)!, multiplier: 1)
        textLabel?.heightAnchor.constraint(equalTo: (textLabel?.heightAnchor)!, multiplier: 1)
    }
    
    func setupDetailTextLabel() {
        detailTextLabel?.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        detailTextLabel?.widthAnchor.constraint(equalTo: (detailTextLabel?.widthAnchor)!, multiplier: 1)
        detailTextLabel?.heightAnchor.constraint(equalTo: (detailTextLabel?.heightAnchor)!, multiplier: 1)
    }
    
    var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "google_firebase-512")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        addSubview(profileImageView)
        setupProfileImage()
    }
    
    func setupProfileImage() {
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
