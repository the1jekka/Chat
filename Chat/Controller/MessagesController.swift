//
//  ViewController.swift
//  Chat
//
//  Created by Admin on 24.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "newMessageicon"), style: .plain, target: self, action: #selector(handleNewMessage))
    
        checkUserLogIn()
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        present(newMessageController, animated: true, completion: nil)
    }
    
    func checkUserLogIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            let uid = Auth.auth().currentUser?.uid
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: {(snapshot) in
                if let dict = snapshot.value as? [String : AnyObject] {
                    self.navigationItem.title = dict["name"] as? String
                }
            }, withCancel: nil)
        }
    }

    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

