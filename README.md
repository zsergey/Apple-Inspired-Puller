# 🥇 Apple-Inspired Puller

> Apple has released a sheet presentation controller in iOS 15, which works great. In iOS 16, developers can customize the detents of the sheet. However, we would like to use these features in iOS 14 as well. That's why I have developed a puller presentation controller with the same API as Apple's. The puller works even in iOS 11. Please feel free to use the puller and give it a star if you find it useful.
>

### 🌈 Features
* Extremely easy to use with a native API-like interface
* Customizable puller presentation animation with two presets: default and spring
* Compatible with iOS 11+ and offers three preset detents: medium, large, and full. In the full state, Puller supports device corners, similar to the Apple Music app
* Supports inside and outside drag indicators
* Works seamlessly with ScrollView
* Compatible with keyboard and device rotation
* Can be opened in a similar style to the AirPods Pro sheet as shown by Apple
* Includes various settings for customization and control

### 🛠 Usage

```swift
let viewController = UIViewController()

let pullerModel = PullerModel(animator: .spring, 
                              detents: [.custom(0.25), .medium, .full], 
                              dragIndicator: .outside(.black))

presentAsPuller(viewController, model: pullerModel)
```
### 🏝️ Example

<img src="https://github.com/zsergey/apple-inspired-puller/blob/develop/example.gif" height="600" width="278">

