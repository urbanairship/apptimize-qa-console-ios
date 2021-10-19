# Apptimize QA Console for iOS

For more information see the [QA Console FAQ page](https://faq.apptimize.com/hc/en-us/articles/360021675293-How-do-I-use-the-Apptimize-QA-Console-).

## Introduction

The Apptimize QA console is a framework that can be integrated into your mobile app. It enables you to preview variants in different combinations from all of your active feature flags and experiments on a simulator or device. This approach of QA works well for customers with large teams that would like to test hands-on while using the app. Integrating the QA console is a simple one-time process. Once the console is in place, it works by overriding your allocations and forcing your selected variants internally.

> #### Note
>
> The QA console is only intended to be integrated into debug/developer-build versions of your app and should not be included in releases to your end-users.

## Adding the Framework to your Application

### Swift Package
Refer to the official documenation at [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app) for detailed instructions.

1. Create or open an iOS Application project.
2. Click **File —> Add Packages** and search for the package URL `https://github.com/urbanairship/apptimize-qa-console-ios`. 
3. Specify the version (or use the `main` branch) and click `Add Package`.

### CocoaPods

Refer to CocoaPod’s [Getting Started Guide](https://guides.cocoapods.org/using/getting-started.html) for detailed instructions.

1. Add the following to your `Podfile` to import ApptimizeQAConsole as a dependency.

   ```
   pod 'ApptimizeQAConsole'
   ```

2. Save your `Podfile`.
3. And then run the following from the command line in your application's directory.

   ```bash
   pod install
   ```

## Integrating in your Application

1.  Add the package (see [Adding the Framework to your Application](#adding-the-framework-to-your-application)).

2. Open the source for the `UIApplicationDelegate`.

3. Add the following import.

   ```swift
   import ApptimizeQAConsole
   ```

4. Add the following to your `didFinishLaunchingWithOptions` method.

   ```swift
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    	// ...other application setup code ...
   
      // Use the shake gesture.
      ApptimizeQAConsole.isShakeGestureEnabled = true
   
      // ...or disable the shake gesture and use manual presentation only.
      ApptimizeQAConsole.isShakeGestureEnabled = false
      return true
   }
   ```

5.   Open the Apptimize dashboard, create and then launch your experiment(s).

6. Run your app on a device/emulator.

7. If you are running on device, shake the device to launch the Apptimize QA Console.

8. Alternatively, you can launch the Apptimize QA Console programmatically

   ```swift
   ApptimizeQAConsole.display()
   ```

