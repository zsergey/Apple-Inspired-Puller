# 🥇 Puller (sheet) like at Apple

> Apple has released a sheet presentation controller in iOS 15, which works great. In iOS 16, developers can customize the detents of the sheet. However, we would like to use these features in iOS 14 as well. That's why I have developed a puller presentation controller with the same API as Apple's. The puller works even in iOS 11. Please feel free to use the puller and give it a star if you find it useful.
>

🛠 How to present a puller?
 --------------------------


`let viewController = UIViewController()`

`let pullerModel = PullerModel(animator: .spring, detents: [.custom(0.25), .medium, .full], dragIndicator: .outside(.black))`

`presentAsPuller(viewController, model: pullerModel)`
