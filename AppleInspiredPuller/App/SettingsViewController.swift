//
//  SettingsViewController.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 09.03.2023.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var pullerAnimatorControl: UISegmentedControl!
    @IBOutlet weak var slowAnimationsSwitch: UISwitch!
    @IBOutlet weak var dragIndicatorControl: UISegmentedControl!
    
    @IBOutlet weak var largestUndimmedDetentControl: UISegmentedControl!
    @IBOutlet weak var scrollingExpandsWhenScrolledToEdgeSwitch: UISwitch!
    @IBOutlet weak var keyboardExpandsSwitch: UISwitch!
    
    @IBOutlet weak var closingLockedBySwipeSwitch: UISwitch!
    @IBOutlet weak var circleCloseButtonSwitch: UISwitch!
    @IBOutlet weak var supportsInteractivePopGestureSwitch: UISwitch!
    
    @IBOutlet weak var whatShouldToDoWhenSelectedARowControl: UISegmentedControl!
    
    private lazy var grapiteColor = UIColor(hex: 0x11100C)
    private lazy var peachColor = UIColor(hex: 0xFED6BC)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        pullerAnimatorControl.setTextColor(grapiteColor)
        dragIndicatorControl.setTextColor(grapiteColor)
        largestUndimmedDetentControl.setTextColor(grapiteColor)
        whatShouldToDoWhenSelectedARowControl.setTextColor(grapiteColor)
        setLabelTextColor(in: view)
        
        view.backgroundColor = peachColor

        let settings = PresentationSettings.sharedInstance

        pullerAnimatorControl.selectedSegmentIndex = settings.animator.damping == 1.0 ? 0 : 1

        slowAnimationsSwitch.isOn = settings.slowAnimations
        
        let selectedDragIndicatorSegmentIndex: Int
        switch settings.dragIndicator {
        case .none:
            selectedDragIndicatorSegmentIndex = 0
        case .inside:
            selectedDragIndicatorSegmentIndex = 1
        case .outside:
            selectedDragIndicatorSegmentIndex = 2
        }
        dragIndicatorControl.selectedSegmentIndex = selectedDragIndicatorSegmentIndex

        let selectedSegmentIndex: Int
        switch settings.largestUndimmedDetent {
        case .custom(let value):
            selectedSegmentIndex = value == 0 ? 0 : 1
        case .medium:
            selectedSegmentIndex = 2
        case .large:
            selectedSegmentIndex = 3
        case .full:
            selectedSegmentIndex = 4
        default:
            selectedSegmentIndex = 0
        }
        largestUndimmedDetentControl.selectedSegmentIndex = selectedSegmentIndex
        
        whatShouldToDoWhenSelectedARowControl.selectedSegmentIndex = settings.dismissWhenSelectedARow ? 0 : 1
        
        scrollingExpandsWhenScrolledToEdgeSwitch.isOn = settings.scrollingExpandsWhenScrolledToEdge
        
        keyboardExpandsSwitch.isOn = settings.keyboardExpands
        
        closingLockedBySwipeSwitch.isOn = settings.isModalInPresentation
        
        circleCloseButtonSwitch.isOn = settings.hasCircleCloseButton
        
        supportsInteractivePopGestureSwitch.isOn = settings.supportsInteractivePopGesture
    }
    
    @IBAction func pullerAnimatorChanged(_ sender: UISegmentedControl) {
        let animator: PullerAnimator = sender.selectedSegmentIndex == 0 ? .default : .spring
        
        PresentationSettings.sharedInstance.animator = animator
        updateSheet()
    }
    
    @IBAction func slowAnimationsChanged(_ sender: UISwitch) {

        PresentationSettings.sharedInstance.slowAnimations = sender.isOn
        updateSheet()
    }
    
    @IBAction func dragIndicatorChanded(_ sender: UISegmentedControl) {
        
        let dragIndicator: PullerModel.DragIndicator
        switch sender.selectedSegmentIndex {
        case 0:
            dragIndicator = .none
        case 1:
            if #available(iOS 13.0, *) {
                dragIndicator = .inside(.label)
            } else {
                dragIndicator = .inside(.black)
            }
        default:
            if #available(iOS 13.0, *) {
                dragIndicator = .outside(.label)
            } else {
                dragIndicator = .outside(.black)
            }
        }
        
        PresentationSettings.sharedInstance.dragIndicator = dragIndicator
        updateSheet()
    }
    
    @IBAction func largestUndimmedDetentChanged(_ sender: UISegmentedControl) {
        let largestUndimmedDetent: PullerModel.Detent
        switch sender.selectedSegmentIndex {
        case 0:
            largestUndimmedDetent = .zero
        case 1:
            largestUndimmedDetent = .custom(0.25)
        case 2:
            largestUndimmedDetent = .medium
        case 3:
            largestUndimmedDetent = .large
        default:
            largestUndimmedDetent = .full
        }
        
        PresentationSettings.sharedInstance.largestUndimmedDetent = largestUndimmedDetent
        updateSheet()
    }
    
    @IBAction func whatShouldToDoWhenSelectedARowSwitchChanged(_ sender: UISegmentedControl) {
        PresentationSettings.sharedInstance.dismissWhenSelectedARow = sender.selectedSegmentIndex == 0
        updateSheet()
    }
    
    @IBAction func scrollingExpandsWhenScrolledToEdgeSwitchChanged(_ sender: UISwitch) {
        PresentationSettings.sharedInstance.scrollingExpandsWhenScrolledToEdge = sender.isOn
        updateSheet()
    }

    @IBAction func keyboardExpandsSwitchChanged(_ sender: UISwitch) {
        PresentationSettings.sharedInstance.keyboardExpands = sender.isOn
        updateSheet()
    }
    
    @IBAction func closingLockedBySwipeSwitchChanged(_ sender: UISwitch) {
        PresentationSettings.sharedInstance.isModalInPresentation = sender.isOn
        updateSheet()
    }

    @IBAction func circleCloseButtonSwitchSwitchChanged(_ sender: UISwitch) {
        PresentationSettings.sharedInstance.hasCircleCloseButton = sender.isOn
        updateSheet()
    }

    @IBAction func supportsInteractivePopGestureSwitchChanged(_ sender: UISwitch) {
        PresentationSettings.sharedInstance.supportsInteractivePopGesture = sender.isOn
        updateSheet()
    }
    
    func updateSheet() {
        let presentationSettings = PresentationSettings.sharedInstance
        let model = presentationSettings.makePullerModel(isSettings: true)
        pullerPresentationController?.apply(model: model)
    }
    
    private func setLabelTextColor(in view: UIView) {
        for index in view.subviews.indices {
            let subView = view.subviews[index]
            (subView as? UILabel)?.textColor = grapiteColor
            setLabelTextColor(in: subView)
        }
    }
}
