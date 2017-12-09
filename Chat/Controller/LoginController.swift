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

class LoginController: UIViewController, UIViewControllerTransitioningDelegate {
    
    var messagesController: MessagesController?

    lazy var inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    let loginRegisterButton: TransitionSubmitButton = {
        let button = TransitionSubmitButton(type: .system)
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
            guard let strongSelf = self else { return }
            if let err = error {
                print(err)
            }
            
            guard let token = session?.authToken else { return }
            guard let secret = session?.authTokenSecret else { return }
            
            let credentials = TwitterAuthProvider.credential(withToken: token, secret: secret)
            print("credentials: \(credentials)")
            strongSelf.loginWithCredentials(credentials: credentials, type: "Twitter")
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
        
        self.configure()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    var nameTextFieldHeightAnchor: NSLayoutConstraint?
    var emailTextFieldHeightAnchor: NSLayoutConstraint?
    var passwordTextFieldHeightAnchor: NSLayoutConstraint?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeAnimator(transitionDuration: 0.5, startingAlpha: 0.0)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

// MARK: -
// MARK: - Configure

fileprivate extension LoginController {
    func configure() {
        self.view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        
        self.view.addSubview(self.inputsContainerView)
        self.view.addSubview(self.loginRegisterButton)
        self.view.addSubview(self.profileImageView)
        self.view.addSubview(self.loginRegisterSegmentedControl)
        self.view.addSubview(self.facebookLoginButton)
        self.view.addSubview(self.googleLoginButton)
        self.view.addSubview(self.twitterLoginButton)
        
        self.setupInputsContainerView()
        self.setupLoginRegisterButton()
        self.setupProfileImageView()
        self.setupLoginRegisterSegmentedControl()
        self.setupFacebookLoginButton()
        self.setupGoogleLoginButton()
        self.setupTwitterLoginButton()
    }
    
    func setupInputsContainerView() {
        self.inputsContainerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.inputsContainerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.inputsContainerView.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -25).isActive = true
        self.inputsContainerViewHeightAnchor = self.inputsContainerView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 1 / 5)
        self.inputsContainerViewHeightAnchor?.isActive = true
        self.inputsContainerView.addSubview(self.nameTextField)
        self.inputsContainerView.addSubview(self.nameSeparatorView)
        self.inputsContainerView.addSubview(self.emailTextField)
        self.inputsContainerView.addSubview(self.emailSeparatorView)
        self.inputsContainerView.addSubview(self.passwordTextField)
        
        self.setupNameTextField()
        self.setupNameSeparatorView()
        self.setupEmailTextField()
        self.setupEmailSeparatorView()
        self.setupPasswordTextField()
    }
    
    func setupLoginRegisterButton() {
        self.loginRegisterButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.loginRegisterButton.centerYAnchor.constraint(equalTo: self.inputsContainerView.bottomAnchor,
                                                          constant: 30).isActive = true
        self.loginRegisterButton.widthAnchor.constraint(equalTo: self.inputsContainerView.widthAnchor).isActive = true
        self.loginRegisterButton.heightAnchor.constraint(equalTo: self.inputsContainerView.heightAnchor,
                                                         multiplier: 1 / 3).isActive = true
    }
    
    func setupNameTextField() {
        self.nameTextField.leftAnchor.constraint(equalTo: self.inputsContainerView.leftAnchor, constant: 15).isActive = true
        self.nameTextField.topAnchor.constraint(equalTo: self.inputsContainerView.topAnchor).isActive = true
        self.nameTextField.widthAnchor.constraint(equalTo: self.inputsContainerView.widthAnchor, multiplier: 1).isActive = true
        self.nameTextFieldHeightAnchor = self.nameTextField.heightAnchor.constraint(equalTo: self.inputsContainerView.heightAnchor,
                                                                                    multiplier: 1 / 3)
        self.nameTextFieldHeightAnchor?.isActive = true
    }
    
    func setupNameSeparatorView() {
        self.nameSeparatorView.leftAnchor.constraint(equalTo: self.inputsContainerView.leftAnchor).isActive = true
        self.nameSeparatorView.topAnchor.constraint(equalTo: self.nameTextField.bottomAnchor).isActive = true
        self.nameSeparatorView.widthAnchor.constraint(equalTo: self.inputsContainerView.widthAnchor, multiplier: 1).isActive = true
        self.nameSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    func setupEmailTextField() {
        self.emailTextField.leftAnchor.constraint(equalTo: self.inputsContainerView.leftAnchor, constant: 15).isActive = true
        self.emailTextField.topAnchor.constraint(equalTo: self.nameTextField.bottomAnchor).isActive = true
        self.emailTextField.widthAnchor.constraint(equalTo: self.inputsContainerView.widthAnchor,
                                                   multiplier: 1).isActive = true
        self.emailTextFieldHeightAnchor = self.emailTextField.heightAnchor.constraint(equalTo: self.inputsContainerView.heightAnchor, multiplier: 1 / 3)
        self.emailTextFieldHeightAnchor?.isActive = true
    }
    
    func setupEmailSeparatorView() {
        self.emailSeparatorView.leftAnchor.constraint(equalTo: self.inputsContainerView.leftAnchor).isActive = true
        self.emailSeparatorView.topAnchor.constraint(equalTo: self.emailTextField.bottomAnchor).isActive = true
        self.emailSeparatorView.widthAnchor.constraint(equalTo: self.inputsContainerView.widthAnchor,
                                                       multiplier: 1).isActive = true
        self.emailSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    func setupPasswordTextField() {
        self.passwordTextField.leftAnchor.constraint(equalTo: self.inputsContainerView.leftAnchor,
                                                     constant: 15).isActive = true
        self.passwordTextField.topAnchor.constraint(equalTo: self.emailTextField.bottomAnchor).isActive = true
        self.passwordTextField.widthAnchor.constraint(equalTo: self.inputsContainerView.widthAnchor,
                                                 multiplier: 1).isActive = true
        self.passwordTextFieldHeightAnchor = self.passwordTextField.heightAnchor.constraint(equalTo: self.inputsContainerView.heightAnchor, multiplier: 1 / 3)
        self.passwordTextFieldHeightAnchor?.isActive = true
    }
    
    func setupFacebookLoginButton() {
        self.facebookLoginButton.centerXAnchor.constraint(equalTo: self.loginRegisterButton.centerXAnchor).isActive = true
        self.facebookLoginButton.topAnchor.constraint(equalTo: self.loginRegisterButton.bottomAnchor,
                                                      constant: 8).isActive = true
        self.facebookLoginButton.widthAnchor.constraint(equalTo: self.loginRegisterButton.widthAnchor).isActive = true
        self.facebookLoginButton.heightAnchor.constraint(equalTo: self.loginRegisterButton.heightAnchor).isActive = true
    }
    
    func setupGoogleLoginButton() {
        self.googleLoginButton.centerXAnchor.constraint(equalTo: self.loginRegisterButton.centerXAnchor).isActive = true
        self.googleLoginButton.topAnchor.constraint(equalTo: self.facebookLoginButton.bottomAnchor,
                                                    constant: 8).isActive = true
        self.googleLoginButton.widthAnchor.constraint(equalTo: self.loginRegisterButton.widthAnchor).isActive = true
        self.googleLoginButton.heightAnchor.constraint(equalTo: self.loginRegisterButton.heightAnchor).isActive = true
    }
    
    func setupTwitterLoginButton() {
        self.twitterLoginButton.centerXAnchor.constraint(equalTo: self.loginRegisterButton.centerXAnchor).isActive = true
        self.twitterLoginButton.topAnchor.constraint(equalTo: self.googleLoginButton.bottomAnchor,
                                                     constant: 8).isActive = true
        self.twitterLoginButton.widthAnchor.constraint(equalTo: self.loginRegisterButton.widthAnchor).isActive = true
        self.twitterLoginButton.heightAnchor.constraint(equalTo: self.loginRegisterButton.heightAnchor).isActive = true
    }
    
    func setupLoginRegisterSegmentedControl() {
        self.loginRegisterSegmentedControl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.loginRegisterSegmentedControl.bottomAnchor.constraint(equalTo: self.inputsContainerView.topAnchor,
                                                                   constant: -15).isActive = true
        self.loginRegisterSegmentedControl.widthAnchor.constraint(equalTo: self.inputsContainerView.widthAnchor).isActive = true
        self.loginRegisterSegmentedControl.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setupProfileImageView() {
        self.profileImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.profileImageView.bottomAnchor.constraint(equalTo: self.loginRegisterSegmentedControl.topAnchor,
                                                      constant: -15).isActive = true
        self.profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        self.profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }
}

// MARK: -
// MARK: - Login

fileprivate extension LoginController {
    func loginWithCredentials(credentials: AuthCredential, type: String) {
        Auth.auth().signIn(with: credentials) { [weak self] (user, error) in
            guard let strongSelf = self else { return }
            if let loginError = error {
                print("Failed to login to Firebase via \(type): \(loginError)")
                return
            }
            let reference = Database.database().reference().child("users")
            reference.observe(.value, with: { (snapshot) in
                let dict = snapshot.value as! NSDictionary
                let keys = dict.allKeys as! [String]
                guard let userKey = user?.uid else { return }
                var isRegisteredInDBBefore = false
                for key in keys {
                    if userKey == key {
                        isRegisteredInDBBefore = true
                        break
                    }
                }
                
                if isRegisteredInDBBefore {
                    strongSelf.messagesController?.setupNavBarTitle()
                    strongSelf.dismiss(animated: true, completion: nil)
                } else {
                    switch type {
                    case "Facebook":
                        strongSelf.facebookLogin(userKey: userKey)
                    case "Google":
                        strongSelf.googleLogin(userKey: userKey)
                    case "Twitter":
                        strongSelf.twitterLogin(userKey: userKey)
                    default:
                        break
                    }
                }
                
            }, withCancel: nil)
        }
    }
    
    func facebookLogin(userKey: String) {
        var values = [String: AnyObject]()
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
        
        self.registerUserIntoDatabase(uid: userKey, values: values)
    }
    
    func googleLogin(userKey: String) {
        var values = [String: AnyObject]()
        let imageURL = GIDSignIn.sharedInstance().currentUser.profile.imageURL(withDimension: 100)
        let userLink = GIDSignIn.sharedInstance().currentUser.profile.email
        let name = GIDSignIn.sharedInstance().currentUser.profile.name
        let image = String(describing: imageURL!)
        values = [
            "name": name! as AnyObject,
            "email": userLink! as AnyObject,
            "profileImageURL": image as AnyObject
        ]
        
        self.registerUserIntoDatabase(uid: userKey, values: values)
    }
    
    func twitterLogin(userKey: String) {
        var values = [String: AnyObject]()
        let client = TWTRAPIClient.withCurrentUser()
        guard let userID = client.userID else { return }
        
        client.loadUser(withID: userID, completion: { [weak self] (user, error) in
            guard let strongSelf = self else { return }
            if let err = error {
                print(err)
            }
            
            let name = user?.name
            let imageURL = user?.profileImageURL
            let userLink = user?.profileURL
            let stringLink = String(describing: userLink!)
            
            values = [
                "name": name! as AnyObject,
                "email": stringLink as AnyObject,
                "profileImageURL": imageURL! as AnyObject
            ]
            
            strongSelf.registerUserIntoDatabase(uid: userKey, values: values)
        })
    }
}

// MARK: -
// MARK: - FBSDKDelegate

extension LoginController: FBSDKLoginButtonDelegate {
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let errorMessage = error {
            print(errorMessage)
            return
        }
        
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields" : "id, name, picture.type(large), link, email"]).start { (connection, result, err) in
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
}

// MARK: -
// MARK: - GoogleAuthDelegate

extension LoginController: GIDSignInDelegate, GIDSignInUIDelegate {
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
}
