//
//  LoginController.swift
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

class LoginController: UIViewController, FBSDKLoginButtonDelegate, GIDSignInUIDelegate, GIDSignInDelegate {
    
    var messagesController: MessagesController?

    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    let loginRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(r: 80, g: 101, b: 161)
        button.setTitle("Register", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        button.addTarget(self, action: #selector(handleLoginRegister), for: .touchUpInside)
        
        return button
    }()
    
    lazy var facebookLoginButton: FBSDKLoginButton = {
        let button = FBSDKLoginButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        button.readPermissions = ["email", "public_profile"]
        return button
    }()
    
    lazy var googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        return button
    }()
    
    lazy var twitterLoginButton: TWTRLogInButton = {
        let button = TWTRLogInButton(logInCompletion: { [weak self] (session, error) in
            if let err = error {
                print(err)
            }
            
            guard let token = session?.authToken else { return }
            guard let secret = session?.authTokenSecret else { return }
            print("token: \(token), secret: \(secret)")
            
            let credentials = TwitterAuthProvider.credential(withToken: token, secret: secret)
            print("credentials: \(credentials)")
            self?.loginWithCredentials(credentials: credentials, type: "Twitter")
        })
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Name"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let nameSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let emailSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isSecureTextEntry = true
        return textField
    }()
    
    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "google_firebase-512")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImage)))
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    
    lazy var loginRegisterSegmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["Login", "Register"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.tintColor = .white
        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.addTarget(self, action: #selector(handleLoginRegisterChange), for: .valueChanged)
        return segmentedControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        
        view.addSubview(inputsContainerView)
        view.addSubview(loginRegisterButton)
        view.addSubview(profileImageView)
        view.addSubview(loginRegisterSegmentedControl)
        view.addSubview(facebookLoginButton)
        view.addSubview(googleLoginButton)
        view.addSubview(twitterLoginButton)
        
        setupInputsContainerView()
        setupLoginRegisterButton()
        setupProfileImageView()
        setupLoginRegisterSegmentedControl()
        setupFacebookLoginButton()
        setupGoogleLoginButton()
        setupTwitterLoginButton()
    }
    
    func loginWithCredentials(credentials: AuthCredential, type: String) {
        Auth.auth().signIn(with: credentials) { [weak self] (user, error) in
            if let loginError = error {
                print("Failed to login to Firebase via \(type): \(loginError)")
                return
            }
            let reference = Database.database().reference().child("users")
            reference.observe(.value, with: { (snapshot) in
                let dict = snapshot.value as! NSDictionary
                let keys = dict.allKeys as! [String]
                let userKey = user?.uid
                var isRegisteredInDBBefore = false
                for key in keys {
                    if userKey == key {
                        isRegisteredInDBBefore = true
                        break
                    }
                }
                
                if isRegisteredInDBBefore {
                    self?.messagesController?.setupNavBarTitle()
                    self?.dismiss(animated: true, completion: nil)
                } else {
                    var values = [String: AnyObject]()
                    switch type {
                    case "Facebook":
                        let imageURL = FBSDKProfile.current().imageURL(for: .square,
                                                                       size: CGSize(width: 100, height: 100))
                        let userName = FBSDKProfile.current().name
                        let userLink = FBSDKProfile.current().linkURL
                        let image = String(describing: imageURL!)
                        let name = userName!
                        let link = String(describing: userLink!)
                        values = [
                            "name" : name as AnyObject,
                            "email" : link as AnyObject,
                            "profileImageURL" : image as AnyObject
                        ]
                        
                        self?.registerUserIntoDatabase(uid: userKey!, values: values)
                        
                    case "Google":
                        let imageURL = GIDSignIn.sharedInstance().currentUser.profile.imageURL(withDimension: 100)
                        let userLink = GIDSignIn.sharedInstance().currentUser.profile.email
                        let name = GIDSignIn.sharedInstance().currentUser.profile.name
                        let image = String(describing: imageURL!)
                        values = [
                            "name": name! as AnyObject,
                            "email": userLink! as AnyObject,
                            "profileImageURL": image as AnyObject
                        ]
                        
                        self?.registerUserIntoDatabase(uid: userKey!, values: values)
                        
                    case "Twitter":
                        let client = TWTRAPIClient.withCurrentUser()
                        guard let userID = client.userID else { return }
                      
                        client.loadUser(withID: userID, completion: { (user, error) in
                            if let err = error {
                                print(err)
                            }
                            
                            let name = user?.name
                            let imageURL = user?.profileImageURL
                            let userLink = user?.profileURL
                            let stringLink = String(describing: userLink!)
                            print("name: \(name), imageURL: \(imageURL), userLink: \(stringLink)")
                            values = [
                                "name": name! as AnyObject,
                                "email": stringLink as AnyObject,
                                "profileImageURL": imageURL! as AnyObject
                            ]
                            
                            self?.registerUserIntoDatabase(uid: userKey!, values: values)
                        })
                    default:
                        break
                    }
                   
                    
                    
                }
                
            }, withCancel: nil)
        }
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let errorMessage = error {
            print(errorMessage)
            return
        }
        
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields" : "id, name, picture.type(large), link, email"]).start { [weak self] (connection, result, err) in
            if let error = err {
                print("Failed to start graph request: \(error)")
                return
            }
        }
        
        let accessToken = FBSDKAccessToken.current()
        
        guard let accessTokenString = accessToken?.tokenString else {
            print("Can't get access token")
            return
        }
        
        FBSDKProfile.loadCurrentProfile { (profile, error) in
            if let loadingError = error {
                print(loadingError)
                return
            }
        }
        
        let credentials = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
        
        loginWithCredentials(credentials: credentials, type: "Facebook")
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("logout")
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let err = error {
            print(err.localizedDescription)
            return
        }
        
        guard let idToken = user.authentication.idToken else { return }
        guard let accessToken = user.authentication.accessToken else { return }
        
        let credentials = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        loginWithCredentials(credentials: credentials, type: "Google")
    }
    
    func setupLoginRegisterSegmentedControl() {
        loginRegisterSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterSegmentedControl.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -15).isActive = true
        loginRegisterSegmentedControl.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterSegmentedControl.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setupProfileImageView() {
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: loginRegisterSegmentedControl.topAnchor, constant: -15).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }
    
    var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    var nameTextFieldHeightAnchor: NSLayoutConstraint?
    var emailTextFieldHeightAnchor: NSLayoutConstraint?
    var passwordTextFieldHeightAnchor: NSLayoutConstraint?
    
    func setupInputsContainerView() {
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -25).isActive = true
        inputsContainerViewHeightAnchor = inputsContainerView.heightAnchor.constraint(equalToConstant: 150)
        inputsContainerViewHeightAnchor?.isActive = true
        
        inputsContainerView.addSubview(nameTextField)
        inputsContainerView.addSubview(nameSeparatorView)
        inputsContainerView.addSubview(emailTextField)
        inputsContainerView.addSubview(emailSeparatorView)
        inputsContainerView.addSubview(passwordTextField)
        
        setupNameTextField()
        setupNameSeparatorView()
        setupEmailTextField()
        setupEmailSeparatorView()
        setupPasswordTextField()
    }
    
    func setupLoginRegisterButton() {
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.centerYAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 30).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1 / 3).isActive = true
    }
    
    func setupNameTextField() {
        nameTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 15).isActive = true
        nameTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        nameTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, multiplier: 1).isActive = true
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1 / 3)
            nameTextFieldHeightAnchor?.isActive = true
    }
    
    func setupNameSeparatorView() {
        nameSeparatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        nameSeparatorView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        nameSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, multiplier: 1).isActive = true
        nameSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    func setupEmailTextField() {
        emailTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 15).isActive = true
        emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, multiplier: 1).isActive = true
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1 / 3)
            emailTextFieldHeightAnchor?.isActive = true
    }
    
    func setupEmailSeparatorView() {
        emailSeparatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        emailSeparatorView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        emailSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, multiplier: 1).isActive = true
        emailSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    func setupPasswordTextField() {
        passwordTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 15).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, multiplier: 1).isActive = true
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1 / 3)
            passwordTextFieldHeightAnchor?.isActive = true
    }
    
    func setupFacebookLoginButton() {
        facebookLoginButton.centerXAnchor.constraint(equalTo: loginRegisterButton.centerXAnchor).isActive = true
        facebookLoginButton.topAnchor.constraint(equalTo: loginRegisterButton.bottomAnchor, constant: 8).isActive = true
        facebookLoginButton.widthAnchor.constraint(equalTo: loginRegisterButton.widthAnchor).isActive = true
        facebookLoginButton.heightAnchor.constraint(equalTo: loginRegisterButton.heightAnchor).isActive = true
    }
    
    func setupGoogleLoginButton() {
        googleLoginButton.centerXAnchor.constraint(equalTo: loginRegisterButton.centerXAnchor).isActive = true
        googleLoginButton.topAnchor.constraint(equalTo: facebookLoginButton.bottomAnchor, constant: 8).isActive = true
        googleLoginButton.widthAnchor.constraint(equalTo: loginRegisterButton.widthAnchor).isActive = true
        googleLoginButton.heightAnchor.constraint(equalTo: loginRegisterButton.heightAnchor).isActive = true
    }
    
    func setupTwitterLoginButton() {
        twitterLoginButton.centerXAnchor.constraint(equalTo: loginRegisterButton.centerXAnchor).isActive = true
        twitterLoginButton.topAnchor.constraint(equalTo: googleLoginButton.bottomAnchor, constant: 8).isActive = true
        twitterLoginButton.widthAnchor.constraint(equalTo: loginRegisterButton.widthAnchor).isActive = true
        twitterLoginButton.heightAnchor.constraint(equalTo: loginRegisterButton.heightAnchor).isActive = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }
}
