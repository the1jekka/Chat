//
//  UserCell.swift
//  Chat
//
//  Created by Admin on 29.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell {
    
    var message: Message? {
        didSet {
            setupNameAndAvatar()
            detailTextLabel?.text = message?.text
            if let seconds =  message?.timestamp {
                let timeDate = Date(timeIntervalSince1970: Double(seconds))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                self.timeLabel.text = dateFormatter.string(from: timeDate)
            }
        }
    }
    
    private func setupNameAndAvatar() {
        if let id = message?.chatPartnerId() {
            let reference = Database.database().reference().child("users").child(id)
            reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                if let dictionary = snapshot.value as? [String : AnyObject] {
                    self?.textLabel?.text = dictionary["name"] as? String
                    if let profileImageUrl = dictionary["profileImageURL"] as? String {
                        self?.profileImageView.loadImageUsingCacheWithUrl(urlString: profileImageUrl)
                        
                    }
                }
            }, withCancel: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: 64, y: textLabel!.frame.origin.y - 2, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 64, y: detailTextLabel!.frame.origin.y + 2, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
        
        
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
    
    var timeLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        addSubview(profileImageView)
        addSubview(timeLabel)
        setupProfileImage()
        setupTimeLabel()
    }
    
    func setupTimeLabel() {
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: textLabel!.heightAnchor).isActive = true
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
