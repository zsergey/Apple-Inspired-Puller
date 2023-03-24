//
//  PullerPresentationController.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 08.03.2023.
//

import UIKit

final class PullerPresentationController: UIPresentationController {
    
    // MARK: - Public properties
    
    var selectedDetent: PullerModel.Detent {
        set { setInternalSelectedDetent(newValue) }
        get { internalSelectedDetent }
    }
    
    // MARK: - Private types
    
    private enum PanGestureSource {
        case scrollView
        case view
    }
    
    private enum ScrollDirection {
        case top
        case stop
        case down
    }
    
    // MARK: - Private properties
    
    private var model: PullerModel

    private var dimmingView: PullerDimmingView?
    private lazy var shadowView: PullerShadowView = { PullerShadowView() }()
    private var shadow: Shadow = .default
    private var fromView: UIView { presentingViewController.view }
    private var toView: UIView { presentedViewController.view }
    private var toViewController: UIViewController { presentedViewController }
    private var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    
    private let keyboard = Keyboard()
    private var isKeyboardVisible: Bool = false
    private var previousDetent: PullerModel.Detent = .zero

    private var standardDetents: [PullerModel.Detent] = []
    private var keyboardDetents: [PullerModel.Detent] = []
    private var dimmedDetent: PullerModel.Detent = .zero
    private var internalSelectedDetent: PullerModel.Detent = .zero
    private var detents: [PullerModel.Detent] { isKeyboardVisible ? keyboardDetents : standardDetents }
    
    private var startedTouchPoint: CGPoint = .zero
    private var startedTouchDetent: PullerModel.Detent = .zero
    
    private var transformObservation: NSKeyValueObservation?
    private var toFrameObservation: NSKeyValueObservation?
    private var fromFrameObservation: NSKeyValueObservation?

    private var needsScrollingPuller = false
    private var scrollView: UIScrollView?
    private var scrollViewInsets: UIEdgeInsets = .zero
    private var scrollViewObservation: NSKeyValueObservation?
    private var scrollViewYOffset: CGFloat = 0
    
    private lazy var screenWidth = { UIScreen.main.bounds.width }()
    private lazy var screenHeight = { UIScreen.main.bounds.height }()
    private var minimumPullerHeight: CGFloat = 0
    private var currentPullerHeight: CGFloat = 0
    
    private var hasRefreshControl: Bool = false
    private var isRotatingDevice: Bool = false
    private var panGestureSource: PanGestureSource = .view
    private var scrollDirection: ScrollDirection = .stop
    
    private var dragIndicatorView: PullerDragIndicatorView?
    private let dragIndicatorSize = CGSize(width: 36.0, height: 5.0)
    private let safeAreaTop: CGFloat = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
    private var dragIndicatorInsideTopOffset: CGFloat { dragIndicatorSize.height }
    private var dragIndicatorOutsideTopOffset: CGFloat { -2 * dragIndicatorSize.height }
    
    private var closeButton: UIButton?
    
    // MARK: - Public methods
    
    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         model: PullerModel) {
        
        self.model = model
        
        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)
        
        setupController()
        setupKeyboard()
    }
    
    func apply(model: PullerModel) {
        self.model = model
        
        setupController()
        
        update3DScale()
        updateCornerRadius()
        updateAlpha()
        
        setupDragIndicatorView()
        
        setupCloseButton()
        updateCloseButton()
    }
    
    deinit {
        
        keyboard.unsubscribeFromNotifications()
        
        invalidateObservers()
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        setupDimmingView()
        setupScrollView()
        setupViews()
        setupCloseButton()
        
        setupDragIndicatorView()
        setFirstDetentAsSelected()
        setStartPositionDragIndicatorView()
        
        updateDragIndicatorView()
        updateCloseButton()
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {

        super.viewWillTransition(to: size, with: coordinator)
        
        isRotatingDevice = true
        guard let containerView = containerView,
              let firstDetent = detents.first else {
            isRotatingDevice = false
            return
        }

        screenWidth = containerView.frame.size.height
        screenHeight = containerView.frame.size.width
        minimumPullerHeight = calcHeight(detent: firstDetent)
        
        DispatchQueue.main.async {
            self.adjustHeightByTransition()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        shadowView.layer.applyShadow(shadow)
    }
    
    func animateChanges(_ changes: @escaping () -> Void) {
        
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
    
    private func setFirstDetentAsSelected() {
        guard let firstDetent = detents.first else {
            return
        }
        
        CATransaction.disableAnimations {
            selectedDetent = .zero
            currentPullerHeight = calcHeight(detent: firstDetent)
            minimumPullerHeight = currentPullerHeight
            selectedDetent = firstDetent
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
    
    private func setupDimmingView() {
        guard let containerView = containerView else {
            return
        }
        let dimmingView = makeDimmingView()
        containerView.addSubview(dimmingView)
        dimmingView.pin(to: containerView)
        self.dimmingView = dimmingView
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
            offset = safeAreaTop
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
    
    private func setupScrollView() {
        scrollView = findScrollView(in: toView)
        scrollViewInsets = scrollView?.contentInset ?? .zero

        if let tableView = scrollView as? UITableView,
           tableView.refreshControl != nil {
            hasRefreshControl = true
        }
    }
    
    private func setupViews() {
        containerView?.addSubview(shadowView)
        shadowView.backgroundColor = toView.backgroundColor
        containerView?.addSubview(toView)

        toView.addGestureRecognizer(makePanGestureRecognizer())
        toViewController.pullerPresentationController = self
        
        if model.hasDynamicHeight {
            toView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            toView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                          .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        fromView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        toView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        toFrameObservation?.invalidate()
        toFrameObservation = toView.observe(\.frame) { [weak self] _, _ in
            guard let self = self else {
                return
            }
            self.syncShadowView()
            self.update3DScale()
            self.updateCornerRadius()
            self.updateAlpha()
            self.updateDragIndicatorView()
            self.updateCloseButton()
        }
        
        fromFrameObservation?.invalidate()
        fromFrameObservation = fromView.observe(\.frame) { [weak self] _, _ in
            self?.update3DScale()
        }
            
        transformObservation?.invalidate()
        transformObservation = toView.observe(\.transform) { [weak self] _, _ in
            guard let self = self else {
                return
            }
            self.syncShadowView()
            self.update3DScale()
            self.updateCornerRadius()
            self.updateAlpha()
            self.updateDragIndicatorView()
            self.updateCloseButton()
        }
        
        scrollViewObservation?.invalidate()
        scrollViewObservation = scrollView?.observe(\.contentOffset, options: .new) { [weak self] scrollView, change in
            self?.updateScrollView(scrollView, change: change)
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
        toViewController.dismiss(animated: true)
    }
    
    private func setupController() {
        standardDetents = model.detents
        
        dimmedDetent = model.detents.first { detent in
            detent.value > model.largestUndimmedDetent.value
        } ?? .full
    }
    
    private func makePanGestureRecognizer() -> UIPanGestureRecognizer {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(panGestureRecognizer:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.delegate = self
        return panGestureRecognizer
    }
    
    private func makeDimmingView() -> PullerDimmingView {
        let view = PullerDimmingView()
        view.viewToTranslateGesture = fromView
        view.onDidTap = { [weak self] in
            self?.dismissPresentedViewController()
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
        var insets = scrollViewInsets
        insets.bottom = parameters.frameTo.height
        scrollView?.contentInset = insets
        scrollView?.scrollIndicatorInsets = insets
    }
    
    private func handleHidingKeyboard(parameters: Keyboard.Parameters) {
        scrollView?.contentInset = scrollViewInsets
        scrollView?.scrollIndicatorInsets = scrollViewInsets
        
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
    
    private func isReachedLastDetent() -> Bool {
        guard let lastDetent = detents.last else {
            return false
        }
        return Int(toView.frame.minY) <= Int(calcPosition(detent: lastDetent))
    }
    
    @objc private func handlePanGestureRecognizer(panGestureRecognizer: UIPanGestureRecognizer) {
        
        let touchPoint = panGestureRecognizer.location(in: toView)
        
        switch panGestureRecognizer.state {
        case .began:
             
            handleBeginStateOfPanGestureRecognizer(at: touchPoint)
            
        case .changed:
            
            handleChangedStateOfPanGestureRecognizer(panGestureRecognizer, at: touchPoint)
            
        case .ended, .cancelled:
            
            handleEndedStateOfPanGestureRecognizer(panGestureRecognizer)
            
        default: break
        }
    }

    private func handleBeginStateOfPanGestureRecognizer(at touchPoint: CGPoint) {
        if panGestureSource == .view {
            needsScrollingPuller = true
        }
        
        startedTouchPoint = touchPoint
        startedTouchDetent = nearestDetent(to: toView.frame.origin.y)
    }
    
    private func handleChangedStateOfPanGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer,
                                                          at touchPoint: CGPoint) {
        
        guard let firstDetent = detents.first,
              let lastDetent = detents.last else {
            return
        }
        
        guard needsScrollingPuller else {
            startedTouchPoint = touchPoint
            startedTouchDetent = nearestDetent(to: toView.frame.origin.y)
            panGestureRecognizer.setTranslation(.zero, in: toView)
            return
        }
        
        let translation = panGestureRecognizer.translation(in: toView)
        let changedY = calcPosition(detent: startedTouchDetent) + translation.y
        
        let isCrossingFirstDetent = changedY > calcPosition(detent: firstDetent)
        let isCrossingLastDetent = changedY < calcPosition(detent: lastDetent)
        
        let isBouncing = (model.isClosingLockedBySwipe && isCrossingFirstDetent) || isCrossingLastDetent
        
        if !isBouncing {
            CATransaction.disableAnimations {
                toView.transform = CGAffineTransform(translationX: 0, y: translation.y)
                toView.frame = adjustHeight(y: toView.frame.origin.y)
            }
            return
        }
        
        let closestDetent = nearestDetent(to: changedY)
        if calcPosition(detent: startedTouchDetent) != calcPosition(detent: closestDetent) {
            startedTouchPoint = touchPoint
            startedTouchDetent = closestDetent
            CATransaction.disableAnimations {
                toView.transform = .identity
                toView.frame.origin.y = calcPosition(detent: closestDetent)
            }
            panGestureRecognizer.setTranslation(.zero, in: toView)
            return
        }
        
        var offset = touchPoint.y - startedTouchPoint.y
        let exponent: CGFloat = model.hasDynamicHeight ? 0.7 : 0.8
        offset = offset > 0 ? pow(offset, exponent) : -pow(-offset, exponent)
        
        let isMovingByView = panGestureSource == .view
        let isMovingDownByScrollView = panGestureSource == .scrollView && scrollDirection == .down && scrollViewYOffset == 0 && offset > 0
        let needsBouncingPuller = isMovingByView || isMovingDownByScrollView
        
        CATransaction.disableAnimations {
            if needsBouncingPuller {
                toView.transform = CGAffineTransform(translationX: 0, y: offset)
            } else {
                toView.transform = .identity
                toView.frame.origin.y = calcPosition(detent: startedTouchDetent)
            }
            self.toView.frame = adjustHeight(y: toView.frame.origin.y)
        }
    }
    
    private func handleEndedStateOfPanGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) {
        guard needsScrollingPuller else {
            return
        }
        
        let velocity = panGestureRecognizer.velocity(in: toView)
        let distance = distanceRest(initialVelocity: velocity.y,
                                    decelerationRate: model.decelerationRate)
        let yRest = toView.frame.origin.y + distance
        
        let closestDetent = nearestDetent(to: yRest)
        
        if startedTouchDetent > closestDetent {
            toView.endEditing(true)
        }
        
        let isGoingToDismiss = closestDetent == .zero
        if !model.isClosingLockedBySwipe && isGoingToDismiss {
            toViewController.dismiss(animated: true)
            return
        }
        
        let isChangedDetent = selectedDetent != closestDetent
        
        self.model.animator.animate { [weak self] in
            guard let self = self else {
                return
            }
            self.selectedDetent = closestDetent
            if self.standardDetents.contains(closestDetent) {
                self.previousDetent = closestDetent
            }
            self.layoutPullerIfNeeded()
        } completion: { _ in
            if isChangedDetent {
                self.model.onChangeDetent?(closestDetent)
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
        let detents = model.isClosingLockedBySwipe ? detents : [.zero] + detents
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
        let inset: CGFloat = model.hasDynamicHeight ? 0 : 6
        let width: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? max(screenWidth, screenHeight) * 0.4 : min(screenWidth, screenHeight)
        let x: CGFloat = (screenWidth - width) / 2
        return (x + inset, width - inset * 2, inset)
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

    @objc private func dismissPresentedViewController() {
        if model.isClosingLockedBySwipe {
            return
        }
        toViewController.dismiss(animated: true)
    }
    
    private func calcHeight(detent: PullerModel.Detent) -> CGFloat {
        screenHeight * detent.value
    }
    
    private func calcPosition(detent: PullerModel.Detent) -> CGFloat {
        screenHeight * (1.0 - detent.value)
    }

    private func updateAlpha() {
        let currentY = max(toView.frame.origin.y, calcPosition(detent: dimmedDetent))
        
        let maxHeight = max(calcPosition(detent: model.largestUndimmedDetent) - calcPosition(detent: dimmedDetent), 0)
        let currentHeight = max(calcPosition(detent: model.largestUndimmedDetent) - currentY, 0)
        var alpha: CGFloat = 0.0
        if maxHeight != 0 {
            alpha = model.dimmedAlpha * currentHeight / maxHeight
        }
        dimmingView?.alpha = alpha
    }
    
    private func calcValue(lastDetent: PullerModel.Detent, maxValue: CGFloat, minValue: CGFloat) -> CGFloat {
        let maxY = calcPosition(detent: lastDetent)
        let minY = detents.count > 1 ? calcPosition(detent: detents[detents.count - 2]) : screenHeight
        let currentY = max(min(toView.frame.origin.y, minY), maxY)
        
        let step = (maxValue - minValue) / (minY - maxY)
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
        let scale = calcValue(lastDetent: lastDetent, maxValue: maxScale, minValue: minScale)
        
        fromView.layer.transform = CATransform3DMakeScale(scale, scale, maxScale)
    }
        
    private func updateCornerRadius() {
        if !model.hasDynamicHeight {
            var radius = UIScreen.main.displayCornerRadius
            radius = radius > 0 ? radius: model.cornerRadius
            toView.layer.setCornerRadius(radius).adjustMasksToBounds()
            shadowView.layer.setCornerRadius(radius)
            return
        }
        
        guard let lastDetent = detents.last,
              lastDetent.isExpanded else {
            
            toView.layer.setCornerRadius(model.cornerRadius).adjustMasksToBounds()
            shadowView.layer.setCornerRadius(model.cornerRadius)
            return
        }
        
        let maxRadius: CGFloat = model.cornerRadius
        let minRadius: CGFloat = UIScreen.main.displayCornerRadius
        let toRadius = calcValue(lastDetent: lastDetent, maxValue: maxRadius, minValue: minRadius)
        
        let fromRadius = maxRadius + minRadius - toRadius
        
        fromView.layer.setCornerRadius(fromRadius)
        if lastDetent.isFull && isPhone && screenWidth < screenHeight {
            toView.layer.setCornerRadius(toRadius).adjustMasksToBounds()
            shadowView.layer.setCornerRadius(toRadius)
        } else {
            toView.layer.setCornerRadius(model.cornerRadius).adjustMasksToBounds()
            shadowView.layer.setCornerRadius(model.cornerRadius)
        }
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
        let minOffset = safeAreaTop
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
        let minInset = safeAreaTop
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
            self.dragIndicatorView?.frame = CGRect(origin: CGPoint(x: self.dragIndicatorView?.frame.origin.x ?? 0,
                                                                   y: self.toView.frame.origin.y + offset),
                                                   size: self.dragIndicatorSize)
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

// MARK: - UIGestureRecognizerDelegate

extension PullerPresentationController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        panGestureSource = .view
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let shouldRecognizeSimultaneously = gestureRecognizer.state != .changed && otherGestureRecognizer.view == scrollView
        
        if shouldRecognizeSimultaneously {
            panGestureSource = .scrollView
            scrollDirection = .stop
            needsScrollingPuller = false
        }
        return shouldRecognizeSimultaneously
    }
}

// MARK: - UIScrollView support

extension PullerPresentationController {
    
    func findScrollView(in view: UIView?) -> UIScrollView? {
        guard let view = view else {
            return nil
        }
        for index in view.subviews.indices {
            let subView = view.subviews[index]
            if let scrollView = subView as? UIScrollView {
                return scrollView
            }
            let scrollView = findScrollView(in: subView)
            if scrollView != nil {
                return scrollView
            }
        }
        return nil
    }
    
    func updateScrollView(_ scrollView: UIScrollView,
                          change: NSKeyValueObservedChange<CGPoint>) {
        
        guard scrollView.contentOffset.y != scrollViewYOffset else {
            return
        }
        
        if hasRefreshControl {
            trackScrolling(scrollView)
            setNeedsScrollingPuller(false)
            return
        }
        
        scrollDirection = scrollView.contentOffset.y > scrollViewYOffset ? .top : .down
        switch scrollDirection {
        case .top:
            handleScrollingToTop(scrollView)
        case .down:
            handleScrollingToBottom(scrollView)
        case .stop:
            break
        }
    }
    
    private func handleScrollingToTop(_ scrollView: UIScrollView) {
        
        if model.scrollingExpandsWhenScrolledToEdge {
            expandPullerToLastDetent(scrollView)
        } else {
            expandPullerToNearestDetent(scrollView)
        }
    }
    
    private func expandPullerToNearestDetent(_ scrollView: UIScrollView) {
        
        if Int(toView.frame.origin.y) > Int(calcPosition(detent: startedTouchDetent)) {
            stopScrolling(scrollView)
            setNeedsScrollingPuller(true)
        } else {
            trackScrolling(scrollView)
            setNeedsScrollingPuller(false)
        }
    }
    
    private func expandPullerToLastDetent(_ scrollView: UIScrollView) {
        if isReachedLastDetent() {
            trackScrolling(scrollView)
            setNeedsScrollingPuller(false)
        } else {
            stopScrolling(scrollView)
            setNeedsScrollingPuller(true)
        }
    }
    
    private func handleScrollingToBottom(_ scrollView: UIScrollView) {

        let isZeroYOffset = scrollViewYOffset == 0
        if scrollView.isScrolling && isZeroYOffset {
            stopScrolling(scrollView)
            setNeedsScrollingPuller(true)
        } else {
            trackScrolling(scrollView)
            setNeedsScrollingPuller(isZeroYOffset)
        }
    }
    
    private func setNeedsScrollingPuller(_ value: Bool) {
        guard panGestureSource == .scrollView else {
            return
        }
        needsScrollingPuller = value
    }
    
    private func stopScrolling(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollViewYOffset), animated: false)
    }
    
    private func trackScrolling(_ scrollView: UIScrollView) {
        scrollViewYOffset = max(scrollView.contentOffset.y, 0)
    }
}
