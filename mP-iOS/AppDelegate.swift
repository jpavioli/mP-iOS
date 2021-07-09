import UIKit
import mParticle_Apple_SDK
import AppTrackingTransparency
import UserNotifications
import AdSupport

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        //initialize mParticle
        let options = MParticleOptions(key: "MPARTICLE KEY",
            secret: "MPARTICLE SECRET")
        
        //add identities to initalization
        let identityRequest = MPIdentityApiRequest.withEmptyUser()
        // identityRequest.email = "test@example.com"
        options.identifyRequest = identityRequest

        // Verbosity
        options.logLevel = MPILogLevel.verbose

        // Identity Callback
        let identityCallback = {(result: MPIdentityApiResult?, error: Error?) in
            if (result?.user != nil) {
//                // IDSync request succeeded, mutate attributes or query for the MPID as needed
//                // Do Cool Stuf:
//                // Like set User Attributes:
//                result?.user.setUserAttribute("example attribute key", value: "example attribute value")
//                // Alias Users (if Enabled)
//                // Successful login request returns new and previous users
//                let newUser = apiResult.user
//                guard let previousUser = apiResult.previousUser else { return }
//                // Copy anything attributes and products from previous to new user.
//                // This example copies everything
//                newUser.userAttributes = previousUser.userAttributes
//                newUser.cart.addAllProducts(previousUser.cart.products() ?? [], shouldLogEvents:false)
//                // Create and send the alias request
//                let request = MPAliasRequest(sourceUser:previousUser, destinationUser:newUser)
//                MParticle.sharedInstance().identity.aliasUsers(request)
            } else {
                NSLog(error!.localizedDescription)
                let resultCode = MPIdentityErrorResponseCode(rawValue: UInt((error! as NSError).code))
                switch (resultCode!) {
                case .clientNoConnection,
                     .clientSideTimeout:
                    //retry the IDSync request
                    break;
                case .requestInProgress,
                     .retry:
                    //inspect your implementation if this occurs frequency
                    //otherwise retry the IDSync request
                    break;
                default:
                    // inspect error.localizedDescription to determine why the request failed
                    // this typically means an implementation issue
                    break;
                }
            }
        }
        options.onIdentifyComplete = identityCallback

        // iOS 14 ATT status
        if #available(iOS 14, *) {
            options.attStatus = NSNumber.init(value: ATTrackingManager.trackingAuthorizationStatus.rawValue)
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                switch status {
                case .authorized:
                    MParticle.sharedInstance().setATTStatus(MPATTAuthorizationStatus(rawValue:3)!, withATTStatusTimestampMillis: nil)
                    print(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
                    // Now that we are authorized we can get the IDFA, supply to mParticle Identity API as needed
                    identityRequest.setIdentity(ASIdentifierManager.shared().advertisingIdentifier.uuidString, identityType: MPIdentity.iosAdvertiserId)
                    MParticle.sharedInstance().identity.modify(identityRequest, completion: identityCallback)
                case .denied:
                    MParticle.sharedInstance().setATTStatus(MPATTAuthorizationStatus(rawValue:2)!, withATTStatusTimestampMillis: nil)
                case .notDetermined:
                    MParticle.sharedInstance().setATTStatus(MPATTAuthorizationStatus(rawValue:0)!, withATTStatusTimestampMillis: nil)
                case .restricted:
                    MParticle.sharedInstance().setATTStatus(MPATTAuthorizationStatus(rawValue:1)!, withATTStatusTimestampMillis: nil)
                @unknown default:
                    MParticle.sharedInstance().setATTStatus(MPATTAuthorizationStatus(rawValue:0)!, withATTStatusTimestampMillis: nil)
                }
            })
        } else {
            let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject
            let version = nsObject as! String
            print("ATT Tracking not enabled. This Device is currently on v",version)
        }

        MParticle.sharedInstance().start(with: options)

        //Register the App with APN for Push Notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                // Handle the error here.
                print("There was and Error registering Push Authorization \(error)")
                return
            }
            self.getNotificationSettings()
            // Enable or disable features based on the authorization.
        }

        return true
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

    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
        guard settings.authorizationStatus == .authorized else { return }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
      let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
      let pushToken = tokenParts.joined()
      print("Device Token: \(pushToken)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
      print("Failed to register: \(error)")
    }

    func application(
      _ application: UIApplication,
      didReceiveRemoteNotification userInfo: [AnyHashable: Any],
      fetchCompletionHandler completionHandler:
      @escaping (UIBackgroundFetchResult) -> Void
    ) {
      guard let aps = userInfo["aps"] as? [String: AnyObject] else {
        completionHandler(.failed)
        return
      }
      print("Notification Recieved: \(aps)")
    }

}
