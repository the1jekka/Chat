//
//  LoginControllerHandle.swift
//  Chat
//
//  Created by Admin on 26.10.2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit

// MARK: -
// MARK: - Login/RegisterButton actions implementation

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleSelectProfileImage() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = true
            strongSelf.present(picker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImage: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImage = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImage = originalImage
        }
        if let selected = selectedImage {
            profileImageView.image = selected
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func handleRegister() {
        
        guard let email = self.emailTextField.text else {
            print("Form is not valid")
            return
        }
        
        guard let password = self.passwordTextField.text else {
            print("Form is not valid")
            return
        }
        
        guard let name = self.nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        if email.isEmpty || password.isEmpty || name.isEmpty {
            self.configureAlertController(title: "Name/password/email unfilled")
        } else {
            Auth.auth().createUser(withEmail: email, password: password, completion: { [weak self] (user, error) in
                if error != nil {
                    print(error!)
                    return
                }
                
                guard let uid = user?.uid else {
                    return
                }
                
                let imageName = UUID().uuidString
                let storageReference = Storage.storage().reference().child("profile_images").child("\(imageName).png")
                
                //if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!)
                
                if let profileImage = self?.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
                    storageReference.putData(uploadData, metadata: nil, completion: {(metadata, error) in
                        if let putDataError = error {
                            print(putDataError)
                            return
                        }
                        if let profileImageURL = metadata?.downloadURL()?.absoluteString {
                            let values = ["name" : name, "email" : email, "profileImageURL" : profileImageURL]
                            self?.registerUserIntoDatabase(uid: uid, values: values as [String : AnyObject])
                        }
                    })
                }
            })
        }
    }
    
    func configureAlertController(title: String) {
        let alert = UIAlertController(title: title, message: "Please try again", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: handleAlertAction)
        alert.addAction(alertAction)
        self.present(alert, animated: true, completion: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loginRegisterButton.returnToOriginalState()
        })
    }
    
    func registerUserIntoDatabase(uid: String, values: [String : AnyObject]) {
        let reference = Database.database().reference()
        let usersReference = reference.child("users").child(uid)
        usersReference.updateChildValues(values, withCompletionBlock: {[weak self] (err, ref) in
            
            if err != nil {
                print(err!)
                return
            }
            
            guard let strongSelf = self else { return }
            let user = User(dictionary: values)
            
            strongSelf.loginRegisterButton.animate(1, completion: {
                strongSelf.messagesController?.setupNavBarWithUser(user: user)
                self?.dismiss(animated: false, completion: nil)
            })
        })
    }
    
    func handleLogin() {
        guard let email = self.emailTextField.text else {
            print("Form is not valid")
            return
        }
        
        guard let password = self.passwordTextField.text else {
            print("Form is not valid")
            return
        }
        
        if email.isEmpty || password.isEmpty {
            configureAlertController(title: "Invalid login/password")
        } else {
            Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] (user, error) in
                if error != nil {
                    print(error!)
                    return
                }
                guard let strongSelf = self else { return }
            
                strongSelf.loginRegisterButton.animate(1, completion: {
                    strongSelf.messagesController?.setupNavBarTitle()
                    strongSelf.dismiss(animated: false, completion: nil)
                })
            })
        }
    }
    
    func handleAlertAction(action: UIAlertAction) {
        return
    }
    
    @objc func handleLoginRegister() {
        self.loginRegisterButton.startLoadingAnimation()
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            self.handleLogin()
        } else {
            self.handleRegister()
        }
    }
    
    @objc func handleLoginRegisterChange() {
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1 / 3)
        nameTextFieldHeightAnchor?.isActive = true
        
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1 / 2 : 1 / 3)
        emailTextFieldHeightAnchor?.isActive = true
        
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1 / 2 : 1 / 3)
        passwordTextFieldHeightAnchor?.isActive = true
        
    }
}
