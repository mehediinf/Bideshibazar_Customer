import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("🚀 App starting...")

    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      print("✅ Firebase configured")
    } else {
      print("✅ Firebase already configured")
    }

    // Set FCM delegate BEFORE requesting permissions
    Messaging.messaging().delegate = self

    // Request notification permissions
    UNUserNotificationCenter.current().delegate = self

    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("✅ Notification permission granted")
            DispatchQueue.main.async {
              UIApplication.shared.registerForRemoteNotifications()
            }
          } else {
            print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown")")
          }
        }
    )

    // Check if already have APNS token
    if let apnsToken = Messaging.messaging().apnsToken {
      print("✅ APNS Token already available")
      let tokenParts = apnsToken.map { data in String(format: "%02.2hhx", data) }
      print("📱 APNS Token: \(tokenParts.joined())")
    } else {
      print("⏳ Waiting for APNS Token...")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  //  APNS Token received callback
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("🎉 ════════════════════════════════════")
    print("📱 APNS Token received successfully!")

    // Convert token to string for debugging
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("📱 APNS Token: \(token)")
    print("🎉 ════════════════════════════════════")

    //  Set APNS token to Firebase
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNS Token set to Firebase Messaging")

    // Trigger FCM token generation
    Messaging.messaging().token { fcmToken, error in
      if let error = error {
        print("❌ Error getting FCM token: \(error.localizedDescription)")
      } else if let fcmToken = fcmToken {
        print("🔥 FCM Token: \(fcmToken)")
      }
    }
  }

  // APNS registration failed callback
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ ════════════════════════════════════")
    print("❌ Failed to register for remote notifications")
    print("❌ Error: \(error.localizedDescription)")
    print("❌ ════════════════════════════════════")

    // Check common issues
    #if targetEnvironment(simulator)
    print("⚠️  You are running on SIMULATOR")
    print("⚠️  Push notifications don't work on simulator!")
    print("⚠️  Please use a REAL DEVICE for testing")
    #endif
  }

  // Handle notification when app is in foreground (iOS 13+ compatible)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("🔔 Notification received in foreground")

    // iOS 14+ uses .banner, iOS 13 uses .alert
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
    print("👆 Notification tapped")
    let userInfo = response.notification.request.content.userInfo
    print("📦 Data: \(userInfo)")
    completionHandler()
  }
}

// FCM Token refresh handler
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔥 ════════════════════════════════════")
    print("🔥 FCM Token received: \(fcmToken ?? "nil")")
    print("🔥 ════════════════════════════════════")

    // Send token to Flutter side
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
    )
  }
}
