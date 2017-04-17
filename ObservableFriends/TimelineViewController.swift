//
//  TimelineViewController.swift
//  ObservableFriends
//
//  Created by Tomoyuki Hosaka on 2017/04/16.
//  Copyright © 2017年 Tomoyuki Hosaka. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TimelineViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var reloadButton: UIButton!
    
    private var count = 0
    
    private let toots = PublishSubject<[String]>()
    private let bag = DisposeBag()
    
    class MyError: Error {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    // API コールを Observable による I/F で実装したと思ってください。
    fileprivate func fetchWithObservable() -> Observable<[String]> {
        // 自分で Observable を作るときは Observable#create を使います。
        return Observable.create { [unowned self] observer in
            self.count += 1
            observer.onNext(["わーい！", "すごーい！", "\(self.count)回目"])
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    // こちらは Single で実装したバージョン。
    fileprivate func fetchWithSingle() -> Single<[String]> {
        // Single も Single#create で作ることができます。
        return Single.create { event in
            self.count += 1
//            event(.error(MyError())) // エラーを先に流したら??
            event(.success(["わーい！", "すごーい！", "\(self.count)回目"]))
//            event(.success(["もっと値を流したらどうなるの??"]))
            return Disposables.create()
        }
    }
    
    fileprivate func didTapReloadButton() {
//        // タップする度に新しいトゥートが表示されることを期待しているが・・・
//        fetchWithObservable()
//            .bind(to: toots)
//            .addDisposableTo(bag)
        
        // Single の場合は、そもそも bind ができない!!
        // 型で値がひとつしか来ないことが分かるし、事故が起こりづらい。
        fetchWithSingle()
            .subscribe(onSuccess: { [unowned self] newToots in
                self.toots.onNext(newToots)
            })
            .addDisposableTo(bag)
    }
    
    fileprivate func setupBindings() {
        // タップしたら API をコールして、取得したトゥートを TableView で表示する!
        reloadButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                self.didTapReloadButton()
            })
            .addDisposableTo(bag)
        
        // RxSwift で Observable を TableView に bind するときのパターン。
        toots
            .bind(to: tableView.rx.items) { tv, i, vm in
                guard let cell = tv.dequeueReusableCell(withIdentifier: "toot") as? TootCell else {
                    return UITableViewCell()
                }
                cell.tootLabel.text = vm
                return cell
            }
            .addDisposableTo(bag)
    }
    
    // Completable
    fileprivate func exampleCompletable() -> Completable {
        return Completable.create { event in
            event(.completed)
            event(.error(MyError()))
            return Disposables.create()
        }
    }
    // Completable 、ほぼ Single<Void> じゃない??
    fileprivate func exampleSingleVoid() -> Single<Void> {
        return Single.create { event in
            event(.success())
            event(.error(MyError()))
            return Disposables.create()
        }
    }
    
    // Maybe
    // 要素が 0 個でも completed になりうる。
    fileprivate func exampleMaybe() -> Maybe<[String]> {
        return Maybe.create { event in
            event(.success(["わーい！", "すごーい！"]))
            event(.completed)
            event(.error(MyError()))
            return Disposables.create()
        }
    }
}
