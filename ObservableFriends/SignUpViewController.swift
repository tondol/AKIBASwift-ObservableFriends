//
//  ViewController.swift
//  ObservableFriends
//
//  Created by Tomoyuki Hosaka on 2017/04/16.
//  Copyright © 2017年 Tomoyuki Hosaka. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SignUpViewController: UIViewController {
    
    @IBOutlet private weak var mailAddressTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var passwordConfirmTextField: UITextField!
    @IBOutlet private weak var mailAddressErrorLabel: UILabel!
    @IBOutlet private weak var passwordErrorLabel: UILabel!
    @IBOutlet private weak var signUpButton: UIButton!
    
    static private let MAIL_ADDRESS_REGEXP = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    
    private let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    fileprivate func isValidMailAddress(mailAddress: String) -> Bool {
        return NSPredicate(format:"SELF MATCHES %@", SignUpViewController.MAIL_ADDRESS_REGEXP)
            .evaluate(with: mailAddress)
    }

    fileprivate func setupBindings() {
        let inputObservable = Observable.combineLatest(
            mailAddressTextField.rx.text,
            passwordTextField.rx.text,
            passwordConfirmTextField.rx.text) { ($0, $1, $2) }
            .flatMap { t -> Observable<(String, String, String)> in
                guard let mailAddress = t.0,
                    let password = t.1,
                    let passwordConfirm = t.2 else {
                        return Observable.empty()
                }
                
                return Observable.just((mailAddress, password, passwordConfirm))
            }
            .asDriver(onErrorDriveWith: Driver.empty())
        
        inputObservable
            .map { [unowned self] mailAddress, password, passwordConfirm in
                 self.isValidMailAddress(mailAddress: mailAddress) &&
                    password.characters.count >= 8 &&
                    password == passwordConfirm
            }
            .drive(signUpButton.rx.isEnabled)
            .addDisposableTo(bag)
        
        inputObservable
            .map { [unowned self] mailAddress, _, _ in
                if mailAddress.isEmpty ||
                    self.isValidMailAddress(mailAddress: mailAddress) {
                        return ""
                } else {
                    return "メールアドレスを正しく入力してください。"
                }
            }
            .drive(mailAddressErrorLabel.rx.text)
            .addDisposableTo(bag)
        
        inputObservable
            .map { _, password, passwordConfirm in
                var error = ""
                
                if !password.isEmpty &&
                    password.characters.count < 8 {
                        error += "パスワードは8桁以上で入力してください。"
                }
                if !password.isEmpty &&
                    password != passwordConfirm {
                        error += "再入力パスワードが一致しません。"
                }
                return error
            }
            .drive(passwordErrorLabel.rx.text)
            .addDisposableTo(bag)
    }
}

