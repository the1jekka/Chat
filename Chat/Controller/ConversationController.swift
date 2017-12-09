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

class ConversationController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate {
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    
    var messages = Array<Message>()
    
    private let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configure()
    }
    
    @objc func handleHideKeyboard() {
        //collectionView?.endEditing(true)
        //inputContainerView.endEditing(true)
        inputContainerView.inputTextField.resignFirstResponder()
    }
    
    lazy var inputContainerView: ConversationInputContainerView = {
        let conversationInputContainerView = ConversationInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        conversationInputContainerView.conversationController = self
        return conversationInputContainerView
    }()
    
    override var inputAccessoryView: UIView? {
        return inputContainerView
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
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
        cell?.message = message
        cell?.messageTextView.text = message.text
        setupCell(cell: cell!, message: message)
        if let text = message.text {
            cell?.bubbleMessageWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
            cell?.messageTextView.isHidden = false
        } else if message.imageUrl != nil {
            cell?.bubbleMessageWidthAnchor?.constant = 200
            cell?.messageTextView.isHidden = true
        }
        
        cell?.playButton.isHidden = message.videoUrl == nil
        
        return cell!
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
    
    @objc func handleSend()  {
        guard let text = inputContainerView.inputTextField.text else { return }
        var textVar = text
        if text.isEmpty {
            return
        }
        
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            return
        } else {
            var spaces: String = ""
            for character in text {
                if character == " " {
                    spaces.append(character)
                } else {
                    break
                }
            }
            let characterSet = CharacterSet.init(charactersIn: spaces)
            textVar = text.trimmingCharacters(in: characterSet)
        }
        
        let options = ["text" : textVar] as [String : Any]
        sendMessageWithOptions(options: options)
    }
    
    var startFrame: CGRect?
    var blackBackgroundView: UIView?
    var startImageView: UIImageView?
    var startXConstraint: NSLayoutConstraint?
    var startYConstraint: NSLayoutConstraint?
    var startWidthConstraint: NSLayoutConstraint?
    var startHeightConstraint: NSLayoutConstraint?
    
    
}

// MARK: -
// MARK: - Configure

fileprivate extension ConversationController {
    func configure() {
        self.collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        // collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        self.collectionView?.alwaysBounceVertical = true
        self.collectionView?.backgroundColor = .white
        self.collectionView?.register(ConversationMessageCell.self, forCellWithReuseIdentifier: cellId)
        self.collectionView?.keyboardDismissMode = .interactive
        self.collectionView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleHideKeyboard)))
        //setupInputs()
        self.setupKeyboard()
    }
    
    func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: Notification.Name.UIKeyboardDidShow, object: nil)
        // NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
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
}

// MARK: -
// MARK: - Messages Actions

fileprivate extension ConversationController {
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        guard let receiver = user?.id else {
            return
        }
        let userMessagesReference = Database.database().reference().child("user-messages").child(uid).child(receiver)
        userMessagesReference.observe(.childAdded, with: { [weak self] (snapshot) in
            let messageId = snapshot.key
            let messagesReference = Database.database().reference().child("messages").child(messageId)
            messagesReference.observeSingleEvent(of: .value, with: {(snapshot) in
                guard let dictionary = snapshot.value as? [String : AnyObject] else {
                    return
                }
                let message = Message(dictionary: dictionary)
                self?.messages.append(message)
                DispatchQueue.main.async {
                    self?.collectionView?.reloadData()
                    let indexPath = IndexPath(item: (self?.messages.count)! - 1, section: 0)
                    self?.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
            }, withCancel: nil)
            }, withCancel: nil)
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
        var values = ["senderId" : senderId ?? "", "receiverId" : receiverId ?? "", "timestamp" : timestamp] as [String : Any]
        options.forEach({values[$0] = $1})
        childReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, ref) in
            guard let strongSelf = self else { return }
            if let changeValueError = error {
                print(changeValueError)
                return
            }
            strongSelf.inputContainerView.inputTextField.text = nil
            let userMessagesReference = Database.database().reference().child("user-messages").child(senderId!).child(receiverId!)
            let messageId = childReference.key
            userMessagesReference.updateChildValues([messageId: 1])
            let recipientUserMessagesReference = Database.database().reference().child("user-messages").child(receiverId!).child(senderId!)
            recipientUserMessagesReference.updateChildValues([messageId: 1])
        })
    }
}

// MARK: -
// MARK: - ImagePickerControllerDelegate

extension ConversationController: UIImagePickerControllerDelegate {
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
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: -
// MARK: - Zooming
extension ConversationController {
    func performZooming(startsImageView: UIImageView) {
        self.startImageView = startsImageView
        self.startImageView?.isHidden = true
        startFrame = startsImageView.superview?.convert(startsImageView.frame, to: nil)
        let zoomingImageView = UIImageView()
        zoomingImageView.translatesAutoresizingMaskIntoConstraints = false
        //startXConstraint = zoomingImageView.centerXAnchor.constraint(equalTo: startImageView.centerXAnchor)
        //startYConstraint = zoomingImageView.centerYAnchor.constraint(equalTo: startImageView.centerYAnchor)
        zoomingImageView.image = startsImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        //zoomingImageView.centerXAnchor.constraint(equalTo: startsImageView.centerXAnchor).isActive = true
        //zoomingImageView.centerYAnchor.constraint(equalTo: startsImageView.centerYAnchor).isActive = true
        //zoomingImageView.widthAnchor.constraint(equalTo: startsImageView.widthAnchor).isActive = true
        //zoomingImageView.heightAnchor.constraint(equalTo: startsImageView.heightAnchor).isActive = true
        if let keyWindow = UIApplication.shared.keyWindow {
            //blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView = UIView()
            blackBackgroundView?.translatesAutoresizingMaskIntoConstraints = false
            blackBackgroundView?.backgroundColor = .black
            blackBackgroundView?.alpha = 0
            keyWindow.addSubview(blackBackgroundView!)
            keyWindow.addSubview(zoomingImageView)
            
            blackBackgroundView?.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            blackBackgroundView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            blackBackgroundView?.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            blackBackgroundView?.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                let height = self.startFrame!.height / self.startFrame!.width * keyWindow.frame.width
                zoomingImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                zoomingImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
                zoomingImageView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
                zoomingImageView.heightAnchor.constraint(equalToConstant: height).isActive = true
                self.view.layoutIfNeeded()
                //keyWindow.layoutIfNeeded()
                //zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                //zoomingImageView.center = keyWindow.center
            }, completion: { (comleted) in
                
            })
        }
    }
    
    @objc private func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let imageView = tapGesture.view {
            imageView.layer.cornerRadius = 16
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                //imageView.frame = self.startFrame!
                imageView.centerXAnchor.constraint(equalTo: (self.startImageView?.centerXAnchor)!).isActive = true
                imageView.centerYAnchor.constraint(equalTo: (self.startImageView?.centerYAnchor)!).isActive = true
                imageView.widthAnchor.constraint(equalTo: (self.startImageView?.widthAnchor)!).isActive = true
                imageView.heightAnchor.constraint(equalTo: (self.startImageView?.heightAnchor)!).isActive = true
                self.view.layoutIfNeeded()
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            }, completion: { (comleted) in
                imageView.removeFromSuperview()
                self.startImageView?.isHidden = false
            })
        }
    }
}

// MARK: -
// MARK: - Image/Video actions

fileprivate extension ConversationController {
    private func handleVideoSelectedForURL(url: URL) {
        let filename = UUID().uuidString + ".mov"
        Storage.storage().reference().child("message-movies").child(filename).putFile(from: url, metadata: nil, completion: { [weak self] (metadata, error) in
            if let nonNilError = error {
                print("Failed upload of video \(nonNilError)")
                return
            }
            
            if let videoURL = metadata?.downloadURL()?.absoluteString {
                if let thumbnailImage = self?.thumbnailImageForUrl(url: url) {
                    self?.uploadToFirebaseStorage(image: thumbnailImage, completion: { (imageURL) in
                        let options: Dictionary<String, Any> =
                            ["imageUrl" : imageURL, "imageWidth" : thumbnailImage.size.width, "imageHeight" : thumbnailImage.size.height, "videoUrl" : videoURL]
                        self?.sendMessageWithOptions(options: options)
                    })
                }
            }
        })
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
                if let putDataError = error {
                    print("Failed to upload image \(putDataError)")
                    return
                }
                
                if let imageURL = metadata?.downloadURL()?.absoluteString {
                    completion(imageURL)
                }
            })
        }
    }
}
