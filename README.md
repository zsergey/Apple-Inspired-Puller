# 🥇 Apple-Inspired Puller

> Apple has released a sheet presentation controller in iOS 15, which works great. In iOS 16, developers can customize the detents of the sheet. However, we would like to use these features in iOS 14 as well. That's why I have developed a puller presentation controller with the same API as Apple's. The puller works even in iOS 11. Please feel free to use the puller and give it a star if you find it useful.
>

## 🌈 Features
* Extremely easy to use with a native API-like interface.
* Customizable puller presentation animation with two presets: default and spring.
* Compatible with iOS 11+, the puller offers four preset detents: `medium`, `large`, `full` and `fitsContent`. In the `full` state, the puller supports device corners, like the Apple Music app. When using the `fitsContent` state, the puller adapts its height to the default height of the presenting view controller's view. Additionally, you can set as many `custom` detents you want.
* Supports inside and outside drag indicators.
* Supports interactive pop gesture.
* Supports SwiftUI.
* Works seamlessly with ScrollView.
* Compatible with keyboard and device rotation.
* Can be opened in a similar style to the AirPods Pro sheet as shown by Apple.
* Includes various settings for customization and control.
* Unfortunately, the puller doesn’t support view controllers like `UIColorPickerViewController` cause they are running in another process and using `UIRemoteView` under the hood.

## 💡 Attention
The puller uses <a href="https://github.com/kylebshr/ScreenCorners">a specific approach to obtain the screen corner radius</a> by adding a `displayCornerRadius` property to `UIScreen`, which reads the private `_displayCornerRadius`. The selector somewhat obscured, which usually means it will get past app review. However, use at your own risk!

## 🏗️ Installation

Apple-Inspired Puller is available through SPM. Just add this repository as a dependency to your package or project.

```swift
dependencies: [
    .package(url: "https://github.com/zsergey/Apple-Inspired-Puller.git", branch: "develop")
]
```

## 🛠 Examples

### Default puller

Default puller with three detents: custom, medium and large. Drag indicator is inside.

<img src="https://github.com/zsergey/apple-inspired-puller/blob/develop/default.gif" height="600" width="278">

<details>
<summary>Source Code</summary>

```swift
let viewController = UIViewController()

let pullerModel = PullerModel(detents: [.custom(0.25), .medium, .full], 
                              dragIndicator: .inside(.black))

presentAsPuller(viewController, model: pullerModel)
```
</details>

### Spring puller

Spring puller in full state. Drag indicator is outside.

<img src="https://github.com/zsergey/apple-inspired-puller/blob/develop/spring.gif" height="600" width="278">

<details>
<summary>Source Code</summary>

```swift
let viewController = UIViewController()

let pullerModel = PullerModel(animator: .spring, 
                              detents: [.full], 
                              dragIndicator: .outside(.black))

presentAsPuller(viewController, model: pullerModel)
```
</details>

### Supporting interactive pop gesture

Spring puller in full state that supports interactive pop gesture.

<img src="https://github.com/zsergey/apple-inspired-puller/blob/develop/popgesture.gif" height="600" width="278">

<details>
<summary>Source Code</summary>

```swift
let viewController = UIViewController()

let pullerModel = PullerModel(animator: .spring, 
                              detents: [.full], 
                              supportsInteractivePopGesture: true) // it's true by default

presentAsPuller(viewController, model: pullerModel)
```
</details>

### Dialog style

Dialog style puller resembles Apple's AirPods Pro sheet.

<img src="https://github.com/zsergey/apple-inspired-puller/blob/develop/dialog.gif" height="600" width="278">

<details>
<summary>Source Code</summary>

```swift
let viewController = UIViewController()

let pullerModel = PullerModel(animator: .spring, 
                              detents: [.medium], 
                              hasDynamicHeight: false)

presentAsPuller(viewController, model: pullerModel)
```
</details>

### How to use `fitsContent` detent

The `intrinsicContentSize` property of the view controller being presented must be set for the `fitsContent` detent to work properly in the puller. If the `intrinsicContentSize` property is not set, the puller will default to the `large` detent.

<img src="https://github.com/zsergey/apple-inspired-puller/blob/develop/fitscontent.gif" height="600" width="278">

<details>
<summary>Source Code</summary>

```swift
class YourViewController: UIViewController {

    override func loadView() {
        view = ResizableView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        (view as? ResizableView)?.defaultHeight = 300
    }
}

class ResizableView: UIView {
    
    var defaultHeight: CGFloat? 
    
    override var intrinsicContentSize: CGSize {
        if let defaultHeight = defaultHeight {
            return CGSize(width: UIView.noIntrinsicMetric, height: defaultHeight)
        }
        return super.intrinsicContentSize
    }
}

let viewController = YourViewController()

let pullerModel = PullerModel(animator: .spring, 
                              detents: [.fitsContent])

presentAsPuller(viewController, model: pullerModel)
```
</details>

### Supports SwiftUI

You can present `PullerHostingController` with any SwiftUI view.

<img src="https://github.com/zsergey/apple-inspired-puller/blob/develop/supports-swiftui.gif" height="600" width="278">

<details>
<summary>Source Code</summary>

```swift
let viewController = PullerHostingController(rootView: DemoScrollView())

let pullerModel = PullerModel(animator: .spring, 
                              detents: [.custom(0.25), .medium, .full], 
                              dragIndicator: .outside(.black))

presentAsPuller(viewController, model: pullerModel)
```
</details>

Also you can apply the `.puller` modifier to any SwiftUI view, ensuring you attach a binding to the `isPresented` property — just like the standard `.sheet` modifier.

<img src="https://github.com/zsergey/apple-inspired-puller/blob/develop/swiftui-modifier.gif" height="600" width="278">

<details>
<summary>Source Code</summary>

```swift
struct DemoPullerContent: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Spacer()
            Text("Eat some more of these soft French buns and drink some tea.")
            Spacer()
            Button("Close") {
                dismiss()
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView: View {
    @State private var isPresented = false

    var body: some View {
        Button("Present") {
            isPresented.toggle()
        }
        .puller(isPresented: $isPresented, model: PullerModel(detents: [.medium]), content: DemoPullerContent.init)
    }
}
```
</details>

### An image in the puller

You can show the puller with an image.

<img src="https://github.com/zsergey/apple-inspired-puller/blob/develop/image-in-puller.gif" height="600" width="278">

<details>
<summary>Source Code</summary>

```swift
let viewController = ImageViewController()

let pullerModel = PullerModel(animator: .spring, 
                              detents: [.fitsContent], 
                              dragIndicator: .outside(.black))

presentAsPuller(viewController, model: pullerModel)
```
</details>

### Settings in Demo

Demo app includes settings for adjusting animation speed and customizing puller behavior.

<img src="https://github.com/zsergey/apple-inspired-puller/blob/develop/settings.gif" height="600" width="278">

## 🐥 Author
You can find me on Twitter [@zsergey](https://twitter.com/zsergey)

## 🎉 Contributing
Feel free to add issues or pull requests here on GitHub. I cannot guarantee that I will accept your changes, but feel free to fork the repo and make changes as you see fit. Thanks!

## 🎓 License
Apple-Inspired Puller is released under the MIT license. See LICENSE for more information.