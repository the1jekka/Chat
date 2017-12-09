//
//  ConversationMessageCell.swift
//  Chat
//
//  Created by Admin on 29.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import AVFoundation

class ConversationMessageCell: UICollectionViewCell {
    
    var conversationController: ConversationController?
    var message: Message?
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .red
        button.setImage(UIImage(named: "play"), for: .normal)
        button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        return button
    }()
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    @objc func handlePlay() {
        if let videoUrlString = message?.videoUrl,
            let videoUrl = URL(string: videoUrlString) {
            self.player = AVPlayer(url: videoUrl)
            self.playerLayer = AVPlayerLayer(player: player)
            self.playerLayer?.frame = bubbleMessageView.bounds
            self.bubbleMessageView.layer.addSublayer(playerLayer!)
            self.player?.play()
            self.activityIndicatorView.startAnimating()
            self.playButton.isHidden = true
            
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        activityIndicatorView.stopAnimating()
    }

    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.isEditable = false
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
    
    lazy var messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))
        return imageView
    }()
    
    var bubbleMessageWidthAnchor: NSLayoutConstraint?
    var bubbleMessageRightAnchor: NSLayoutConstraint?
    var bubbleMessageLeftAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bubbleMessageView)
        addSubview(messageTextView)
        addSubview(profileImageView)
        bubbleMessageView.addSubview(messageImageView)
        bubbleMessageView.addSubview(playButton)
        bubbleMessageView.addSubview(activityIndicatorView)
        
        setupBubbleMessageView()
        setupPlayButton()
        setupActivityIndicatorView()
        setupMessageTextView()
        setupMessageImageView()
        setupProfileImageView()
    }
    
    @objc func handleZoomTap(tapGesture: UITapGestureRecognizer) {
        if message?.videoUrl != nil {
            return
        }
        
        if let imageView = tapGesture.view as? UIImageView {
            print(imageView.constraints)
            self.conversationController?.performZooming(startsImageView: imageView)
        }
    }
    
    func setupActivityIndicatorView() {
        activityIndicatorView.centerXAnchor.constraint(equalTo: bubbleMessageView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: bubbleMessageView.centerYAnchor).isActive = true
        activityIndicatorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicatorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setupPlayButton() {
        playButton.centerXAnchor.constraint(equalTo: bubbleMessageView.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: bubbleMessageView.centerYAnchor).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setupMessageImageView() {
        messageImageView.leftAnchor.constraint(equalTo: bubbleMessageView.leftAnchor).isActive = true
        messageImageView.rightAnchor.constraint(equalTo: bubbleMessageView.rightAnchor).isActive = true
        messageImageView.topAnchor.constraint(equalTo: bubbleMessageView.topAnchor).isActive = true
        messageImageView.bottomAnchor.constraint(equalTo: bubbleMessageView.bottomAnchor).isActive = true
    }
    
    func setupProfileImageView() {
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
    }
    
    func setupBubbleMessageView() {
        bubbleMessageRightAnchor = bubbleMessageView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubbleMessageRightAnchor?.isActive = true
        bubbleMessageLeftAnchor = bubbleMessageView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        bubbleMessageLeftAnchor?.isActive = false
        bubbleMessageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleMessageWidthAnchor = bubbleMessageView.widthAnchor.constraint(equalToConstant: 200)
        bubbleMessageWidthAnchor?.isActive = true
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
