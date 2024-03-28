//
//  PullerPresentationController.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 08.03.2023.
//

import UIKit

final public class PullerPresentationController: UIPresentationController {
    
    // MARK: - Public properties
    
    public var lastDetent: PullerModel.Detent? {
        model.detents.last
    }
    
    public var selectedDetent: PullerModel.Detent {
        set { setInternalSelectedDetent(newValue) }
        get { internalSelectedDetent }
    }
    
    public lazy var toView: UIView = { presentedViewController.view }()

    // MARK: - Private set properties

    var isFitContent: Bool = false
    var defaultViewHeight: CGFloat = 0
    var originalViewHeight: CGFloat = 0

    /// `PullerPresentationController` can modify the dismissal direction for `PullerAnimationController`.
    weak var animationController: PullerAnimationController?
    
    // MARK: - Private types
    
    private enum PanGestureSource {
        case scrollView
        case view
    }
    
    private enum MovingDirection {
        case up
        case down
    }
    
    // MARK: - Private properties
    
    private var model: PullerModel
    
    private var dimmingView: PullerDimmingView?
    private lazy var shadowView = PullerShadowView()
    private var shadow: Shadow = .default
    private var fromView: UIView { presentingViewController.view }
    private var fromViewController: UIViewController { presentingViewController }
    private var toViewController: UIViewController { presentedViewController }
    private var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    private var isDialog: Bool { !model.hasDynamicHeight }
    private var canBeDismissedHorizontally: Bool { model.hasDynamicHeight && model.supportsInteractivePopGesture }
    
    private let keyboard = Keyboard()
    private var isKeyboardVisible: Bool = false
    private var previousDetent: PullerModel.Detent = .zero

    private var standardDetents: [PullerModel.Detent] = []
    private var keyboardDetents: [PullerModel.Detent] = []
    private var dimmedDetent: PullerModel.Detent = .zero
    private var internalSelectedDetent: PullerModel.Detent = .zero
    private var detents: [PullerModel.Detent] { isKeyboardVisible ? keyboardDetents : standardDetents }
    
    private var pointOfMoving: CGPoint = .zero
    private var detentAtBeginningOfTouch: PullerModel.Detent = .zero
    private var lastTransformOfToView: CGAffineTransform = .identity

    private var transformObservation: NSKeyValueObservation?
    private var toFrameObservation: NSKeyValueObservation?
    private var fromFrameObservation: NSKeyValueObservation?

    private var needsMovingPuller = false
    private var scrollView: UIScrollView?
    private var scrollViewContentInsetBottom: CGFloat = .zero
    private var currentContentInsetTop: CGFloat = 0
    private var isScrollViewAtTopAtBeginningOfTouch: Bool = true
    private var isScrollViewAtTop: Bool {
        (scrollView?.contentInset.top ?? 0) + (scrollView?.contentOffset.y ?? 0) <= 0
    }
    private var isMovingDownByScrollView: Bool {
        panGestureSource == .scrollView && movingDirection == .down
    }
    private var isMovingUpByScrollView: Bool {
        panGestureSource == .scrollView && movingDirection == .up
    }
    private lazy var screenWidth = { UIScreen.main.bounds.width }()
    private lazy var screenHeight = { UIScreen.main.bounds.height }()
    private var minimumPullerHeight: CGFloat = 0
    private var currentPullerHeight: CGFloat = 0
    
    private var hasRefreshControl: Bool = false
    private var isRotatingDevice: Bool = false
    private var isRunningHorizontalAnimation: Bool = false
    private var isRunningVerticalAnimation: Bool = false
    private var isValidGesture: Bool = true
    private var pullerMovement: PullerModel.Movement = .vertical
    private var isHorizontal: Bool { pullerMovement == .horizontal }
    private var isInternalDismissing: Bool = false
    private var panGestureSource: PanGestureSource = .view
    private var movingDirection: MovingDirection = .up
    private var scrollViewHorizontalContentOffset: CGPoint = .zero
    
    private var dragIndicatorView: PullerDragIndicatorView?
    private let dragIndicatorSize = CGSize(width: 36.0, height: 5.0)
    private lazy var window = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
    private lazy var safeAreaTopInset: CGFloat = window?.safeAreaInsets.top ?? 0
    private lazy var safeAreaBottomInset: CGFloat = window?.safeAreaInsets.bottom ?? 0
    private var dragIndicatorInsideTopOffset: CGFloat { dragIndicatorSize.height }
    private var dragIndicatorOutsideTopOffset: CGFloat { -2 * dragIndicatorSize.height }
    
    private var closeButton: UIButton?
    
    private var pullerWidth: CGFloat {
        
        UIDevice.current.userInterfaceIdiom == .pad && model.isCompactPadSize ? 468 : min(screenWidth, screenHeight)
    }
    
    // MARK: - Public methods
    
    public init(presentedViewController: UIViewController,
                presenting presentingViewController: UIViewController?,
                model: PullerModel) {
        
        self.model = model
        
        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)
        
        setupController()
        setupKeyboard()
    }
    
    public func makeFitsContentDetent(height: CGFloat) -> PullerModel.Detent {
        originalViewHeight = height
        
        let height = height + safeAreaBottomInset
        return makeFitsContentDetentLimitedToLarge(height: height)
    }
    
    private func makeFitsContentDetentLimitedToLarge(height: CGFloat) -> PullerModel.Detent {
        
        let largeHeight = screenHeight * PullerModel.Detent.large.value
        let viewHeight = min(height, largeHeight)
        let detentValue = round(100 * viewHeight / screenHeight) / 100
        return PullerModel.Detent(rawValue: detentValue)
    }
    
    public func setHeightThatMatches(detent: PullerModel.Detent) {
        let height = calcHeight(detent: detent)
        currentPullerHeight = height
        minimumPullerHeight = height
        defaultViewHeight = height
        selectedDetent = detent
        
        (toView as? PullerContentView)?.scrollView.contentSize.height = originalViewHeight
    }
    
    public func apply(detents: [PullerModel.Detent]) {
        self.model.detents = detents
        apply(model: model)
    }

    public func apply(model: PullerModel) {
        self.model = model
        
        setupController()
        
        update3DScale()
        updateCornerRadius()
        updateDimmingView()
        
        setupDragIndicatorView()
        
        setupCloseButton()
        updateCloseButton()
    }
    
    public func embedViewToScrollView() {
        
        guard isFitContent, model.embeddingViewToScrollView,
              originalViewHeight > defaultViewHeight,
              let containerView else {
            return
        }
        
        CATransaction.disableAnimations {
            toView.removeFromSuperview()
            toFrameObservation?.invalidate()
            toFrameObservation = nil
            transformObservation?.invalidate()
            transformObservation = nil
            toView.gestureRecognizers?.removeAll()
            closeButton?.removeFromSuperview()
            closeButton = nil
            dragIndicatorView?.removeFromSuperview()
            dragIndicatorView = nil
            
            let pullerContentView = PullerContentView()
            pullerContentView.backgroundColor = toView.backgroundColor
            pullerContentView.contentView = toView
            pullerContentView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: model.cornerRadius * 2, left: 0, bottom: 0, right: 0)
            let contentSize = CGSize(width: toView.frame.size.width,
                                     height: originalViewHeight)
            pullerContentView.scrollView.contentSize = contentSize
            pullerContentView.scrollView.addSubview(toView)
            pullerContentView.scrollView.flashScrollIndicators()
            setupScrollView(pullerContentView.scrollView)
            
            containerView.addSubview(pullerContentView)
            toView = pullerContentView
            setupToView(toView)
            setupCloseButton()
            setupDragIndicatorView()
        }
    }
    
    deinit {
        
        keyboard.unsubscribeFromNotifications()
        
        invalidateObservers()
    }
    
    public override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        if !isInternalDismissing {
            pullerMovement = .vertical
        }
    }
    
    public override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        addViews()
        setupToView(toView)
        setupFromView()
        setupCloseButton()
        
        setupDragIndicatorView()
        setFirstDetentAsSelected()
        setStartPositionDragIndicatorView()
        
        updateDragIndicatorView()
        updateCloseButton()
    }
    
    public override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        
        if scrollView == nil {
            setupScrollView(toViewController.findScrollView())
        }
    }
    
    public override func viewWillTransition(to size: CGSize,
                                            with coordinator: UIViewControllerTransitionCoordinator) {

        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { [weak self] _ in
            self?.runTransition(size: size)
        }
    }
    
    private func runTransition(size: CGSize) {
        isRotatingDevice = true
        guard let firstDetent = detents.first else {
            isRotatingDevice = false
            return
        }
        
        screenWidth = size.width
        screenHeight = size.height

        if isFitContent {
            
            let detent = makeFitsContentDetentLimitedToLarge(height: defaultViewHeight)
            apply(detents: [detent])
            minimumPullerHeight = calcHeight(detent: detent)
            
            if selectedDetent != .zero {
                selectedDetent = detent
            }
        } else {
            minimumPullerHeight = calcHeight(detent: firstDetent)
        }
        
        adjustHeightByTransition()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        shadowView.layer.applyShadow(shadow)
    }
    
    public func animateChanges(_ changes: @escaping () -> Void) {
        
        model.animator.animate { [weak self] in
            changes()
            self?.layoutPullerIfNeeded()
        }
    }
    
    // MARK: - Private methods
    
    private func layoutPullerIfNeeded() {
        toView.layoutIfNeeded()
        containerView?.layoutIfNeeded()
    }
    
    func updateFirstDetentAsSelected() {
        if selectedDetent == .fitsContent {
            setFirstDetentAsSelected()
        }
    }

    private func setFirstDetentAsSelected() {
        guard let firstDetent = detents.first else {
            return
        }
        
        CATransaction.disableAnimations {
            selectedDetent = .zero
            currentPullerHeight = calcHeight(detent: firstDetent)
            minimumPullerHeight = currentPullerHeight
            selectedDetent = firstDetent
            previousDetent = firstDetent
        }
    }
    
    private func setStartPositionDragIndicatorView() {
        guard let dragIndicatorView = dragIndicatorView else {
            return
        }
        
        CATransaction.disableAnimations {
            let offset = dragIndicatorTopOffset()
            dragIndicatorView.frame = CGRect(origin: CGPoint(x: dragIndicatorView.frame.origin.x,
                                                             y: screenHeight + offset),
                                             size: dragIndicatorView.frame.size)
            layoutPullerIfNeeded()
        }
    }
    
    private func addViews() {
        
        guard let containerView = containerView else {
            return
        }
        
        let dimmingView = makeDimmingView()
        containerView.addSubview(dimmingView)
        dimmingView.pin(to: containerView)
        self.dimmingView = dimmingView
        
        containerView.addSubview(shadowView)
        if #available(iOS 13.0, *) {
            shadowView.overrideUserInterfaceStyle = toView.traitCollection.userInterfaceStyle
        }
        
        containerView.addSubview(toView)
    }
    
    private func hideDragIndicatorView() {
        model.animator.animate { [weak self] in
            self?.dragIndicatorView?.alpha = 0
        } completion: { [weak self] _ in
            self?.dragIndicatorView?.removeFromSuperview()
            self?.dragIndicatorView = nil
        }
    }
    
    private func dragIndicatorTopOffset() -> CGFloat {
        guard let isInside = model.dragIndicator.isInside else {
            return 0
        }
        
        let isFullLastDetent = detents.last?.isFull == true
        let offset: CGFloat
        if isFullLastDetent {
            offset = safeAreaTopInset
        } else if isInside {
            offset = dragIndicatorInsideTopOffset
        } else {
            offset = dragIndicatorOutsideTopOffset
        }
        return offset
    }
    
    private func setupDragIndicatorView() {
        
        guard let containerView = containerView,
              let color = model.dragIndicator.color else {
            hideDragIndicatorView()
            return
        }
        
        let offset = dragIndicatorTopOffset()
        
        if dragIndicatorView == nil {
            let dragIndicatorView = makeDragIndicatorView()
            dragIndicatorView.frame = CGRect(origin: CGPoint(x: (screenWidth - dragIndicatorSize.width) / 2,
                                                             y: toView.frame.origin.y + offset),
                                             size: self.dragIndicatorSize)
            containerView.addSubview(dragIndicatorView)
            dragIndicatorView.backgroundColor = color
            self.dragIndicatorView = dragIndicatorView
        } else {
            animateDragIndicator(offset: offset)
        }
    }
    
    private func setupScrollView(_ scrollView: UIScrollView?) {
        
        self.scrollView = scrollView
        scrollViewContentInsetBottom = scrollView?.contentInset.bottom ?? .zero
        
        scrollView?.panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
        scrollView?.panGestureRecognizer.delaysTouchesBegan = false
        scrollView?.delaysContentTouches = false
        
        if let tableView = scrollView as? UITableView,
           tableView.refreshControl != nil {
            hasRefreshControl = true
        }
    }
    
    private func setupToView(_ toView: UIView) {

        shadowView.backgroundColor = toView.backgroundColor

        let panGestureRecognizer = makePanGestureRecognizer()
        toView.addGestureRecognizer(panGestureRecognizer)
        
        if model.hasDynamicHeight {
            toView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            toView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                          .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        toView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        toFrameObservation?.invalidate()
        toFrameObservation = toView.observe(\.frame) { [weak self] _, _ in
            guard let self = self else {
                return
            }
            self.syncShadowView()
            self.update3DScale()
            self.updateCornerRadius()
            self.updateDimmingView()
            self.updateDragIndicatorView()
            self.updateCloseButton()
        }
        
        transformObservation?.invalidate()
        transformObservation = toView.observe(\.transform) { [weak self] _, _ in
            guard let self = self else {
                return
            }
            self.syncShadowView()
            self.update3DScale()
            self.updateCornerRadius()
            self.updateDimmingView()
            self.updateDragIndicatorView()
            self.updateCloseButton()
        }
    }
    
    private func setupFromView() {
        
        fromView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                        .layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        fromFrameObservation?.invalidate()
        fromFrameObservation = fromView.observe(\.frame) { [weak self] _, _ in
            self?.update3DScale()
        }
    }
    
    private func setupCloseButton() {
        guard model.hasCircleCloseButton else {
            closeButton?.removeFromSuperview()
            closeButton = nil
            return
        }
        
        if closeButton != nil {
            return
        }
        
        let button = UIButton(type: .custom)
        let image = UIImage(named: "ic_nav_closedialogs_m")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        toView.addSubview(button)
        closeButton = button
    }
    
    @objc private func closeButtonTapped() {
        dismissToViewControllerVertically()
    }
    
    private func setupController() {
        toViewController.pullerPresentationController = self

        standardDetents = model.detents
        
        dimmedDetent = model.detents.first { detent in
            detent.value > model.largestUndimmedDetent.value
        } ?? .full
    }
    
    private func makePanGestureRecognizer() -> UIPanGestureRecognizer {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delaysTouchesBegan = true
        return panGesture
    }
    
    private func makeDimmingView() -> PullerDimmingView {
        let view = PullerDimmingView()
        view.viewToTranslateGesture = fromView
        view.onDidTap = { [weak self] in
            self?.dimmingViewTapped()
        }
        return view
    }
    
    private func makeDragIndicatorView() -> PullerDragIndicatorView {
        let view = PullerDragIndicatorView()
        view.layer.cornerRadius = dragIndicatorSize.height / 2.0
        view.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        let value: CGFloat = 30
        view.contentEdgeInsets = UIEdgeInsets(top: value, left: value, bottom: value, right: value)
        view.viewToTranslateGesture = toView
        return view
    }
    
    private func setInternalSelectedDetent(_ newValue: PullerModel.Detent) {
        if newValue == .zero || detents.contains(newValue) {
            toView.transform = .identity
            toView.frame = adjustHeight(y: calcPosition(detent: newValue))
            internalSelectedDetent = newValue
        }
    }
    
    private func setupKeyboard() {
        keyboard.subscribeToNotifications()

        keyboard.onWillShow = { [weak self] parameters in
            guard let self = self, !self.isRotatingDevice else {
                return
            }
            self.handleShowingKeyboard(parameters: parameters)
        }
        
        keyboard.onDidShow = { [weak self] parameters in
            self?.adjustScrollViewInsets(parameters: parameters)
        }
        
        keyboard.onWillHide = { [weak self] parameters in
            guard let self = self, !self.isRotatingDevice else {
                return
            }
            self.handleHidingKeyboard(parameters: parameters)
        }
    }
    
    private func adjustScrollViewInsets(parameters: Keyboard.Parameters) {
        let value = parameters.frameTo.height
        scrollView?.contentInset.bottom = value
        scrollView?.scrollIndicatorInsets.bottom = value
    }
    
    private func handleHidingKeyboard(parameters: Keyboard.Parameters) {
        scrollView?.contentInset.bottom = scrollViewContentInsetBottom
        scrollView?.scrollIndicatorInsets.bottom = scrollViewContentInsetBottom
        
        selectedDetent = previousDetent
        isKeyboardVisible = false
    }

    private func handleShowingKeyboard(parameters: Keyboard.Parameters) {
        guard let lastDetent = self.detents.last else {
            return
        }
        
        keyboardDetents = standardDetents
        previousDetent = selectedDetent

        let keyboardHeight = parameters.frameTo.height
        let rawY = calcPosition(detent: selectedDetent) - keyboardHeight
        let minY = lastDetent.isFull ? 0 : calcPosition(detent: .large)
        let detentY: CGFloat
        
        if model.keyboardExpands {
            if detents.last?.isExpanded == false {
                keyboardDetents.append(.large)
                keyboardDetents = keyboardDetents.sorted(by: <)
            }
            detentY = minY
        } else {
            detentY = max(calcPosition(detent: selectedDetent) - keyboardHeight, minY)
            
            let detentValue = (screenHeight - detentY) / screenHeight
            keyboardDetents.append(.custom(detentValue))
            keyboardDetents = keyboardDetents.sorted(by: <)
        }
        
        let height = keyboardHeight - (detentY - rawY)
        currentPullerHeight += height
        
        isKeyboardVisible = true

        animateChanges { [weak self] in
            guard let self = self else {
                return
            }
            self.toView.frame = self.adjustHeight(y: detentY)
        }
    }
        
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
                    
        if gesture.state == .began {
            handleBeginGesture(gesture)
            return
        }
            
        guard isValidGesture else {
            setTranslationToZero(gesture)
            needsMovingPuller = false
            gesture.state = .cancelled
            return
        }
        
        switch gesture.state {
        case .changed:
            isHorizontal ? handleHorizontalGesture(gesture) :
                           handleVerticalGesture(gesture)
        case .ended, .cancelled:
            isHorizontal ? handleEndHorizontalGesture(gesture) :
                           handleEndVerticalGesture(gesture)
        default: break
        }
        
        setTranslationToZeroIfNeeded(gesture)
    }
    
    private func setTranslationToZero(_ gesture: UIPanGestureRecognizer) {
        
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    private func setTranslationToZeroIfNeeded(_ gesture: UIPanGestureRecognizer) {

        switch pullerMovement {
        case .vertical:

            if panGestureSource == .view ||
                (panGestureSource == .scrollView && needsMovingPuller) {
                
                setTranslationToZero(gesture)
            }

        case .horizontal:
            
            setTranslationToZero(gesture)
        }
    }
    
    private func handleBeginGesture(_ gesture: UIPanGestureRecognizer) {
        
        setupMovingDirection(gesture)
        setupPanGestureSource(gesture)
        setupBeginGestureValues()
        
        guard isPhone && canBeDismissedHorizontally else {
            return
        }
        
        let velocity = gesture.velocity(in: gesture.view)
        let isHorizontal = abs(velocity.x) > abs(velocity.y)
        
        if (isRunningHorizontalAnimation && !isHorizontal) ||
            (isRunningVerticalAnimation && isHorizontal) {
            isValidGesture = false
        } else {
            isValidGesture = true
            pullerMovement = isHorizontal ? .horizontal : .vertical
            scrollViewHorizontalContentOffset = scrollView?.contentOffset ?? .zero
        }
    }
    
    private func setupMovingDirection(_ gesture: UIPanGestureRecognizer) {
        
        movingDirection = gesture.velocity(in: gesture.view).y < 0 ? .up : .down
    }
    
    private func setupBeginGestureValues() {
        
        detentAtBeginningOfTouch = nearestDetent(to: toView.frame.origin.y)
        pointOfMoving = CGPoint(x: 0, y: calcPosition(detent: detentAtBeginningOfTouch))
        lastTransformOfToView = toView.transform
    }

    private func setupPanGestureSource(_ gesture: UIPanGestureRecognizer) {
        
        panGestureSource = .view
        let point = gesture.location(in: toView)
        var targetView = toView.hitTest(point, with: nil)
        while targetView?.superview != nil {
            
            if targetView == scrollView {
                panGestureSource = .scrollView
                break
            }
            targetView = targetView?.superview
        }
        
        guard panGestureSource == .scrollView else {
            
            needsMovingPuller = true
            return
        }
        
        isScrollViewAtTopAtBeginningOfTouch = isScrollViewAtTop
        setTranslationToZero(gesture)

        if movingDirection == .up {
            needsMovingPuller = model.scrollingExpandsWhenScrolledToEdge && isScrollViewAtTop
        } else {
            needsMovingPuller = isScrollViewAtTop && !hasRefreshControl
        }
    }
    
    private func handleHorizontalGesture(_ gesture: UIPanGestureRecognizer) {

        let translation = gesture.translation(in: gesture.view)
        pointOfMoving.x += translation.x

        let isBouncing = pointOfMoving.x < 0
        
        CATransaction.disableAnimations {
            if isBouncing {
                let exponent: CGFloat = 0.7
                let offset = -pow(abs(pointOfMoving.x), exponent)
                toView.transform = lastTransformOfToView.concatenating(CGAffineTransform(translationX: offset, y: 0))
            } else {
                toView.transform = toView.transform.concatenating(CGAffineTransform(translationX: translation.x, y: 0))
                lastTransformOfToView = toView.transform
            }
        }
    }

    private func handleEndHorizontalGesture(_ gesture: UIPanGestureRecognizer) {

        let velocity = gesture.velocity(in: gesture.view)
        let distance = distanceRest(initialVelocity: velocity.x,
                                    decelerationRate: model.decelerationRate)
        let xRest = toView.frame.origin.x + distance
        
        let x: CGFloat
        if xRest > screenWidth / 2 {
            x = screenWidth
        } else {
            x = (screenWidth - pullerWidth) / 2 + model.inset
        }
        
        scrollView?.contentOffset = scrollViewHorizontalContentOffset
        
        let isGoingToDismiss = x == screenWidth
        
        if isGoingToDismiss {
            dismissToViewControllerHorizontally()
            return
        }
        
        isRunningHorizontalAnimation = true
        model.animator.animate { [weak self] in
            guard let self = self else {
                return
            }
            self.toView.transform = .identity
            self.toView.frame.origin.x = x
            self.layoutPullerIfNeeded()
        } completion: { [weak self] _ in
            self?.isRunningHorizontalAnimation = false
        }
    }
    
    private func handleVerticalGesture(_ gesture: UIPanGestureRecognizer) {
        
        setupMovingDirection(gesture)
        
        guard let firstDetent = detents.first,
              let lastDetent = detents.last else {
            return
        }
        
        if isMovingDownByScrollView,
            isScrollViewAtTopAtBeginningOfTouch,
            isScrollViewAtTop,
            !needsMovingPuller,
            !hasRefreshControl {
            
            setupBeginGestureValues()
            needsMovingPuller = true
            setTranslationToZero(gesture)
            return
        }
        
        var translation = gesture.translation(in: gesture.view)
        pointOfMoving.y += translation.y
        
        guard needsMovingPuller else {
            return
        }
        
        if panGestureSource == .scrollView {
            scrollView?.contentOffset.y = -(scrollView?.contentInset.top ?? 0)
        }
        
        let firstDetentY = calcPosition(detent: firstDetent)
        let lastDetentY = calcPosition(detent: lastDetent)
        let isCrossingFirstDetent = pointOfMoving.y > firstDetentY
        let isCrossingLastDetent = pointOfMoving.y < lastDetentY
        
        let isCrossingEdgeDetents = (model.isModalInPresentation && isCrossingFirstDetent) || isCrossingLastDetent
        
        var offset = isCrossingLastDetent ? (pointOfMoving.y - lastDetentY) : (pointOfMoving.y - firstDetentY)
        let exponent: CGFloat = model.hasDynamicHeight ? 0.7 : 0.8
        offset = offset > 0 ? pow(offset, exponent) : -pow(-offset, exponent)
        
        let isMovingByView = panGestureSource == .view
        let doesMovementAffectBounce = isMovingByView || (isMovingDownByScrollView && isScrollViewAtTop && offset > 0)
        let isBouncing = isCrossingEdgeDetents && doesMovementAffectBounce
        
        if isMovingUpByScrollView, isCrossingLastDetent {
            let delta = lastDetentY - pointOfMoving.y
            translation.y += delta
            pointOfMoving.y += delta
            setTranslationToZero(gesture)
            needsMovingPuller = false
        }
        
        CATransaction.disableAnimations {
            if isBouncing {
                toView.transform = lastTransformOfToView.concatenating(CGAffineTransform(translationX: 0, y: offset))
            } else {
                toView.transform = toView.transform.concatenating(CGAffineTransform(translationX: 0, y: translation.y))
                lastTransformOfToView = toView.transform
            }
            self.toView.frame = adjustHeight(y: toView.frame.origin.y)
        }
    }
    
    private func handleEndVerticalGesture(_ gesture: UIPanGestureRecognizer) {
        
        guard needsMovingPuller else {
            return
        }

        let velocity = gesture.velocity(in: gesture.view)
        let distance = distanceRest(initialVelocity: velocity.y,
                                    decelerationRate: model.decelerationRate)
        let yRest = toView.frame.origin.y + distance
        
        let closestDetent = nearestDetent(to: yRest)
        
        if detentAtBeginningOfTouch > closestDetent {
            toView.endEditing(true)
        }
        
        let isGoingToDismiss = closestDetent == .zero
        if !model.isModalInPresentation && isGoingToDismiss {
            dismissToViewControllerVertically()
            return
        }
        
        let isChangedDetent = selectedDetent != closestDetent
        isRunningVerticalAnimation = true
        model.animator.animate { [weak self] in
            guard let self = self else {
                return
            }
            self.selectedDetent = closestDetent
            if self.standardDetents.contains(closestDetent) {
                self.previousDetent = closestDetent
            }
            self.layoutPullerIfNeeded()
        } completion: { [weak self] _ in
            self?.isRunningVerticalAnimation = false
            if isChangedDetent {
                self?.model.onChangeDetent?(closestDetent)
            }
        }
    }

    private func distanceRest(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
        (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate)
    }
    
    private func nearestDetent(to y: CGFloat) -> PullerModel.Detent {
        let point = CGPoint(x: 0, y: y)
        var minimumDistance = CGFloat.greatestFiniteMagnitude
        var closestDetent: PullerModel.Detent = .full
        let detents = model.isModalInPresentation ? detents : [.zero] + detents
        for detent in detents {
            let distance = point.distance(to: CGPoint(x: 0, y: calcPosition(detent: detent)))
            if distance < minimumDistance {
                closestDetent = detent
                minimumDistance = distance
            }
        }
        return closestDetent
    }
    
    private func calcBody() -> (x: CGFloat, width: CGFloat, inset: CGFloat) {
        let x = (screenWidth - pullerWidth) / 2
        return (x + model.inset, pullerWidth - model.inset * 2, model.inset)
    }
    
    private func adjustHeight(y: CGFloat) -> CGRect {
        let body = calcBody()
        
        currentPullerHeight = model.hasDynamicHeight ? max(screenHeight - y, minimumPullerHeight) : currentPullerHeight
        
        let height = model.hasDynamicHeight ? currentPullerHeight : currentPullerHeight - body.inset
        
        return CGRect(origin: CGPoint(x: body.x, y: y),
                      size: CGSize(width: body.width, height: height))
    }
    
    private func setHeight(_ height: CGFloat) {
        let body = calcBody()
        currentPullerHeight = height
        toView.frame = CGRect(origin: CGPoint(x: body.x,
                                              y: screenHeight - height),
                              size: CGSize(width: body.width, height: height - body.inset))
    }
    
    @objc private func dimmingViewTapped() {
        if model.isModalInPresentation {
            return
        }
        dismissToViewControllerVertically()
    }
    
    private func dismissToViewControllerVertically() {
        if isRunningHorizontalAnimation {
            return
        }
        isInternalDismissing = true
        pullerMovement = .vertical
        animationController?.pullerMovement = .vertical
        keyboard.unsubscribeFromNotifications()
        toViewController.dismiss(animated: true)
    }

    private func dismissToViewControllerHorizontally() {
        isInternalDismissing = true
        animationController?.pullerMovement = .horizontal
        keyboard.unsubscribeFromNotifications()
        toViewController.dismiss(animated: true)
    }

    private func calcHeight(detent: PullerModel.Detent) -> CGFloat {
        screenHeight * detent.value
    }
    
    private func calcPosition(detent: PullerModel.Detent) -> CGFloat {
        screenHeight * (1.0 - detent.value)
    }

    private func updateDimmingView() {

        if isHorizontal {

            let currentX = toView.frame.origin.x
            var alpha = model.dimmedAlpha * (screenWidth - currentX) / screenWidth
            let largestUndimmedDetentY = calcPosition(detent: model.largestUndimmedDetent)
            alpha = toView.frame.origin.y < largestUndimmedDetentY ? alpha : 0.0
            dimmingView?.alpha = alpha
            
        } else {
            
            let currentY = max(toView.frame.origin.y, calcPosition(detent: dimmedDetent))
            
            let maxHeight = max(calcPosition(detent: model.largestUndimmedDetent) - calcPosition(detent: dimmedDetent), 0)
            let currentHeight = max(calcPosition(detent: model.largestUndimmedDetent) - currentY, 0)
            var alpha: CGFloat = 0.0
            if maxHeight != 0 {
                alpha = model.dimmedAlpha * currentHeight / maxHeight
            }
            dimmingView?.alpha = alpha
        }
    }
    
    private func calcValue(lastDetent: PullerModel.Detent, maxValue: CGFloat, minValue: CGFloat) -> CGFloat {
        let maxY = calcPosition(detent: lastDetent)
        let minY = detents.count > 1 ? calcPosition(detent: detents[detents.count - 2]) : screenHeight
        let currentY = max(min(toView.frame.origin.y, minY), maxY)
        let deltaY = minY - maxY
        if deltaY == 0 {
            return minValue
        }
        
        let step = (maxValue - minValue) / deltaY
        return maxValue - (minY - currentY) * step
    }

    private func syncShadowView() {
        shadowView.frame = toView.frame
    }

    private func update3DScale() {
        
        guard let lastDetent = detents.last,
              lastDetent.isExpanded,
              isPhone,
              screenHeight > screenWidth,
              fromView.frame.size.height > fromView.frame.size.width else {
            
            fromView.layer.transform = CATransform3DIdentity
            return
        }
        
        let maxScale: CGFloat = 1.0
        let minScale: CGFloat = 0.88
        let scale: CGFloat

        if isHorizontal {
            scale = selectedDetent.isExpanded ? toView.frame.origin.x * (maxScale - minScale) / screenWidth + minScale : maxScale
        } else {
            scale = calcValue(lastDetent: lastDetent, maxValue: maxScale, minValue: minScale)
        }

        let transform = CATransform3DMakeScale(scale, scale, maxScale)
        if let superview = fromView.superview,
           type(of: superview) == NSClassFromString("UITransitionView") {
            superview.layer.transform = transform
        } else {
            fromView.layer.transform = transform
        }
    }
        
    private func updateCornerRadius() {
        
        if isDialog {
            setDisplayCornerRadius()
            return
        }
        
        guard let lastDetent = detents.last,
              lastDetent.isExpanded else {
            setDefaultCornerRadius()
            return
        }
        
        setFlexibleCornerRadiuses(lastDetent: lastDetent)
    }
    
    private func setFlexibleCornerRadiuses(lastDetent: PullerModel.Detent) {
        let maxRadius: CGFloat = model.cornerRadius
        let minRadius: CGFloat = UIScreen.main.displayCornerRadius
        var toRadius: CGFloat
        
        if isHorizontal {
            toRadius = toView.frame.origin.x * (maxRadius - minRadius) / screenWidth + minRadius
        } else {
            toRadius = calcValue(lastDetent: lastDetent, maxValue: maxRadius, minValue: minRadius)
        }
        
        var fromRadius = maxRadius + minRadius - toRadius
        if !(fromViewController is UINavigationController) {
            fromRadius = fromViewController.presentingViewController == nil ? fromRadius : model.cornerRadius
        }
        if isHorizontal {
            fromRadius = selectedDetent.isExpanded ? fromRadius : minRadius
        }
        fromView.layer.setCornerRadius(fromRadius).adjustMasksToBounds()
        
        if isHorizontal {
            toRadius = selectedDetent.isFull ? minRadius : maxRadius
        }
        
        if lastDetent.isFull && isPhone && screenWidth < screenHeight {
            toView.layer.setCornerRadius(toRadius).adjustMasksToBounds()
            shadowView.layer.setCornerRadius(toRadius)
        } else {
            setDefaultCornerRadius()
        }
    }
    
    private func setDisplayCornerRadius() {
        var radius = UIScreen.main.displayCornerRadius
        radius = radius > 0 ? radius: model.cornerRadius
        toView.layer.setCornerRadius(radius).adjustMasksToBounds()
        shadowView.layer.setCornerRadius(radius)
    }

    private func setDefaultCornerRadius() {
        toView.layer.setCornerRadius(model.cornerRadius).adjustMasksToBounds()
        shadowView.layer.setCornerRadius(model.cornerRadius)
    }

    private func updateDragIndicatorView() {
        guard let lastDetent = detents.last,
              lastDetent.isFull,
              let isInside = model.dragIndicator.isInside else {

            let offset = dragIndicatorTopOffset()
            animateDragIndicator(offset: offset)
            
            return
        }
        
        let maxOffset = isInside ? dragIndicatorInsideTopOffset : dragIndicatorOutsideTopOffset
        let minOffset = safeAreaTopInset
        let offset = calcValue(lastDetent: lastDetent, maxValue: maxOffset, minValue: minOffset)
        animateDragIndicator(offset: offset)
    }
    
    private func updateCloseButton() {
        
        var topInset: CGFloat = model.hasDynamicHeight ? 12 : 20
        let rightInset: CGFloat = topInset + 3
        
        guard let lastDetent = detents.last,
              lastDetent.isFull else {
            setCloseButtonInsets(topInset: topInset, rightInset: rightInset)
            return
        }

        let maxInset = topInset
        let minInset = safeAreaTopInset
        topInset = calcValue(lastDetent: lastDetent, maxValue: maxInset, minValue: minInset)

        setCloseButtonInsets(topInset: topInset, rightInset: rightInset)
    }
    
    private func setCloseButtonInsets(topInset: CGFloat, rightInset: CGFloat) {
        let size = CGSize(width: 32, height: 32)
        let point = CGPoint(x: toView.frame.size.width - size.width - rightInset,
                            y: topInset)
        closeButton?.frame = CGRect(origin: point, size: size)
    }

    private func animateDragIndicator(offset: CGFloat) {
        
        animateChanges { [weak self] in
            guard let self = self else {
                return
            }
            let x = self.toView.frame.origin.x + (self.screenWidth - self.dragIndicatorSize.width) / 2
            let frame = CGRect(origin: CGPoint(x: x,
                                               y: self.toView.frame.origin.y + offset),
                               size: self.dragIndicatorSize)
            self.dragIndicatorView?.frame = frame
        }
    }

    private func adjustHeightByTransition() {
        let animations: () -> Void = isKeyboardVisible ? { } : { [weak self] in
            guard let self = self else {
                return
            }
            let height = self.calcHeight(detent: self.selectedDetent)
            if self.toView.frame.size.height > height {
                self.setHeight(height)
            } else if self.currentPullerHeight < height {
                self.setHeight(height)
            }
            self.layoutPullerIfNeeded()
        }
        
        model.animator.animate(animations) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            self.isRotatingDevice = false
            if self.isKeyboardVisible,
               let parameters = self.keyboard.keyboardParameters {
                self.handleShowingKeyboard(parameters: parameters)
            }
        }
    }
    
    private func invalidateObservers() {
        
        transformObservation?.invalidate()
        transformObservation = nil
        
        toFrameObservation?.invalidate()
        toFrameObservation = nil

        fromFrameObservation?.invalidate()
        fromFrameObservation = nil
    }
}
