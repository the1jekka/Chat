//
//  ConversationController.swift
//  Chat
//
//  Created by Admin on 27.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ConversationController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
        guard let receiver = user?.id else {
            return
        }
        let userMessagesReference = Database.database().reference().child("user-messages").child(uid).child(receiver)
        userMessagesReference.observe(.childAdded, with: {(snapshot) in
            let messageId = snapshot.key
            let messagesReference = Database.database().reference().child("messages").child(messageId)
            messagesReference.observeSingleEvent(of: .value, with: {(snapshot) in
                guard let dictionary = snapshot.value as? [String : AnyObject] else {
                    return
                }
                let message = Message(dictionary: dictionary)
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
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
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
       // collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = .white
        collectionView?.register(ConversationMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.keyboardDismissMode = .interactive
        collectionView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleHideKeyboard)))
        //setupInputs()
        setupKeyboard()
    }
    
    @objc func handleHideKeyboard() {
        //collectionView?.endEditing(true)
        //inputContainerView.endEditing(true)
        inputTextField.resignFirstResponder()
    }
    
    lazy var inputContainerView: UIView = {
        
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = .white
        
        let attachImageView = UIImageView()
        attachImageView.image = UIImage(named: "attachIcon")
        attachImageView.translatesAutoresizingMaskIntoConstraints = false
        attachImageView.isUserInteractionEnabled = true
        attachImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAttachImageTap)))
        containerView.addSubview(attachImageView)
        attachImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        attachImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        attachImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        attachImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
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
        inputTextField.leftAnchor.constraint(equalTo: attachImageView.rightAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLine)
        separatorLine.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLine.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        separatorLine.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLine.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: 1).isActive = true
    
        return containerView
    }()
    
    @objc func handleAttachImageTap() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
            handleVideoSelectedForURL(url: videoUrl)
        } else {
            handleImageSelectedForInfo(info: info)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelectedForURL(url: URL) {
        let filename = UUID().uuidString + ".mov"
        let uploadTask = Storage.storage().reference().child("message-movies").child(filename).putFile(from: url, metadata: nil, completion: { (metadata, error) in
            if let nonNilError = error {
                print("Failed upload of video \(nonNilError)")
                return
            }
            
            if let videoURL = metadata?.downloadURL()?.absoluteString {
                if let thumbnailImage = self.thumbnailImageForUrl(url: url) {
                    self.uploadToFirebaseStorage(image: thumbnailImage, completion: { (imageURL) in
                        let options: Dictionary<String, Any> =
                            ["imageUrl" : imageURL, "imageWidth" : thumbnailImage.size.width, "imageHeight" : thumbnailImage.size.height, "videoUrl" : videoURL]
                        self.sendMessageWithOptions(options: options)
                    })
                   
                }
            }
        })
        uploadTask.observe(.progress) { (snapshot) in
            <#code#>
        }
        
        uploadTask.observe(.success) { (<#StorageTaskSnapshot#>) in
            <#code#>
        }
    }
    
    private func thumbnailImageForUrl(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch let error {
            print(error)
        }
        
        return nil
    }
    
    private func handleImageSelectedForInfo(info: Dictionary<String, Any>) {
        var selectedImage: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImage = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImage = originalImage
        }
        if let selected = selectedImage {
            uploadToFirebaseStorage(image: selected, completion: { (imageURL) in
                self.sendMessageWithImageUrl(imageUrl: imageURL, image: selected)
            })
        }
    }
    
    private func uploadToFirebaseStorage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
        let imageName = UUID().uuidString
        let reference = Storage.storage().reference().child("message-images").child(imageName)
        if let uploadedData = UIImageJPEGRepresentation(image, 0.5) {
            reference.putData(uploadedData, metadata: nil, completion: {(metadata, error) in
                if error != nil {
                    print("Failed to upload image \(error)")
                    return
                }
                
                if let imageURL = metadata?.downloadURL()?.absoluteString {
                    completion(imageURL)
                    
                }
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override var inputAccessoryView: UIView? {
        return inputContainerView
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: Notification.Name.UIKeyboardDidShow, object: nil)
       // NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    @objc func handleKeyboardWillShow(notification: Notification) {
        let keyboardFrame = notification.userInfo![UIKeyboardIsLocalUserInfoKey] as? CGRect
        let keyboardDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    @objc func handleKeyboardWillHide(notification: Notification) {
        let keyboardDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ConversationMessageCell
        cell?.conversationController = self
        let message = messages[indexPath.item]
        cell?.messageTextView.text = message.text
        setupCell(cell: cell!, message: message)
        if let text = message.text {
            cell?.bubbleMessageWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
            cell?.messageTextView.isHidden = false
        } else if message.imageUrl != nil {
            cell?.bubbleMessageWidthAnchor?.constant = 200
            cell?.messageTextView.isHidden = true
        }
        return cell!
    }
    
    private func setupCell(cell: ConversationMessageCell, message: Message) {
        if let profileImageURL = self.user?.profileImageURL {
            cell.profileImageView.loadImageUsingCacheWithUrl(urlString: profileImageURL)
        }
        
        if message.sender == Auth.auth().currentUser?.uid {
            cell.bubbleMessageView.backgroundColor = ConversationMessageCell.blueColor
            cell.messageTextView.textColor = .white
            cell.bubbleMessageRightAnchor?.isActive = true
            cell.bubbleMessageLeftAnchor?.isActive = false
            cell.profileImageView.isHidden = true
        } else {
            cell.bubbleMessageView.backgroundColor = ConversationMessageCell.greyColor
            cell.messageTextView.textColor = .black
            cell.bubbleMessageRightAnchor?.isActive = false
            cell.bubbleMessageLeftAnchor?.isActive = true
            cell.profileImageView.isHidden = false
        }

        if let imageMessageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrl(urlString: imageMessageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleMessageView.backgroundColor = .clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 88
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth,
            let imageHeight = message.imageHeight {
            height = CGFloat(Double(imageHeight) / Double(imageWidth) * 200)
            print("height = \(height)")
        }
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func setupInputs() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomAnchor?.isActive = true
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
        separatorLine.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        separatorLine.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLine.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: 1).isActive = true
        
    }
    
    @objc func handleSend()  {
        
        let options = ["text" : inputTextField.text!] as [String : Any]
        sendMessageWithOptions(options: options)
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        let options: [String : Any] =  ["imageUrl" : imageUrl, "imageWidth" : image.size.width, "imageHeight" : image.size.height]
        sendMessageWithOptions(options: options)
    }
    
    private func sendMessageWithOptions(options: [String : Any]) {
        let reference = Database.database().reference().child("messages")
        let childReference = reference.childByAutoId()
        let senderId = Auth.auth().currentUser?.uid
        let receiverId = user?.id!
        let timestamp: Int = Int(NSDate().timeIntervalSince1970)
        var values = ["senderId" : senderId, "receiverId" : receiverId, "timestamp" : timestamp] as [String : Any]
        options.forEach({values[$0] = $1})
        //reference.updateChildValues(values)
        childReference.updateChildValues(values, withCompletionBlock: {(error, ref) in
            if error != nil {
                print(error)
                return
            }
            self.inputTextField.text = nil
            let userMessagesReference = Database.database().reference().child("user-messages").child(senderId!).child(receiverId!)
            let messageId = childReference.key
            userMessagesReference.updateChildValues([messageId: 1])
            let recipientUserMessagesReference = Database.database().reference().child("user-messages").child(receiverId!).child(senderId!)
            recipientUserMessagesReference.updateChildValues([messageId: 1])
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    var startFrame: CGRect?
    var blackBackgroundView: UIView?
    var startImageView: UIImageView?
    
    func performZooming(startImageView: UIImageView) {
        self.startImageView = startImageView
        self.startImageView?.isHidden = true
        startFrame = startImageView.superview?.convert(startImageView.frame, to: nil)
        let zoomingImageView = UIImageView(frame: startFrame!)
        zoomingImageView.backgroundColor = .red
        zoomingImageView.image = startImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        if let keyWindow = UIApplication.shared.keyWindow {
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = .black
            blackBackgroundView?.alpha = 0
            keyWindow.addSubview(blackBackgroundView!)
            keyWindow.addSubview(zoomingImageView)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                let height = self.startFrame!.height / self.startFrame!.width * keyWindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
            }, completion: { (comleted) in
                
            })
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let imageView = tapGesture.view {
            imageView.layer.cornerRadius = 16
            imageView.clipsToBounds = true
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                imageView.frame = self.startFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            }, completion: { (comleted) in
                imageView.removeFromSuperview()
                self.startImageView?.isHidden = false
            })
        }
    }
}
