//
//  AppDelegate.swift
//  TWP4BG
//
//  Created by daelee on 2023/08/09.
//

import UIKit
import RealmSwift
import FirebaseCore
import FirebaseFirestore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var shouldSupportAllOrientation = true
    // 화면회전을 잠그고 고정할 목적의 플래그 변수를 추가한다.
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        lazy var realm: Realm? = {
            do {
                return try Realm()
            } catch {
                print("Could not access Realm, \(error)")
                return nil
            }
        }()
        FirebaseApp.configure()
        sleep(1)
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {

            if (shouldSupportAllOrientation == true){
                return UIInterfaceOrientationMask.all //  모든방향 회전 가능
            }
            return UIInterfaceOrientationMask.portrait //  세로방향으로 고정
        }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

