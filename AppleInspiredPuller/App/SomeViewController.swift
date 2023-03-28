//
//  SomeViewController.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 16.02.2023.
//

import UIKit

class SomeViewController: UIViewController {
    
    lazy var tableView = UITableView()
    lazy var button = Button()
    lazy var appleLabel = UILabel()
    lazy var refreshControl = UIRefreshControl()

    var onSelectItem: ((UIViewController, Item) -> Void)?
    
    private var dataSource: [Item] = []
    
    private lazy var grapiteColor = UIColor(hex: 0x11100C)
    private lazy var skyBlueColor = UIColor(hex: 0xC6D8FF)
    private lazy var lightTurquoiseColor = UIColor(hex: 0xB5F2EA)
    private var topTableViewConstraint: NSLayoutConstraint?
    private var byApple: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupButton()
        setupAppleLabel()
    }
    
    private func setupTableView() {
        let string = "Eat some more of these soft French buns and drink some tea"
        let words = string.components(separatedBy: " ")
        for word in words {
            dataSource.append(Item(text: word, isEditable: true))
        }
        for _ in 0..<10 {
            dataSource.append(Item(text: string, isEditable: false))
        }
        for word in words {
            dataSource.append(Item(text: word, isEditable: true))
        }

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        topTableViewConstraint = tableView.top(to: view)
        tableView.left(to: view)
        tableView.bottom(to: view)
        tableView.right(to: view)
        
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets

        tableView.backgroundColor = .clear

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }
    
    private func setupButton() {
        button.setTitle("Close", for: .normal)
        button.backgroundColor = Button.normalColor
        button.contentEdgeInsets = .init(top: 16, left: 50, bottom: 16, right: 50)
        button.setTitleColor(grapiteColor, for: .normal)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)

        view.addSubview(button)
        button.bottom(to: view, constant: 16)
        button.centerX(in: view)
    }
    
    private func setupAppleLabel() {
        appleLabel.text = ""
        view.addSubview(appleLabel)
        appleLabel.textColor = grapiteColor
        appleLabel.left(to: view, constant: 16)
        appleLabel.top(to: view, constant: 16)
    }

    func setBackgroundColor(_ byApple: Bool) {
        self.byApple = byApple
        view.backgroundColor = byApple ? skyBlueColor : lightTurquoiseColor
        appleLabel.isHidden = !byApple
    }

    func addRefreshControl() {
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    func addAirPodsPro() {
        tableView.alpha = 0
        
        let imageView = UIImageView(image: UIImage(named: "hero-airpods-pro"))
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.pin(to: view, insets: .init(top: 8, left: 80, bottom: 80, right: 80))
    }
    
    func addHeader() {
        CATransaction.disableAnimations {
            self.topTableViewConstraint?.constant = 60
        }
    }
    
    @objc private func didTapButton() {
        dismiss(animated: true)
    }

    @objc private func refresh(_ sender: AnyObject) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.refreshControl.endRefreshing()
        }
    }
}

extension SomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        76
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") {
            configureCell(cell, at: indexPath)
            return cell
        }
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        configureCell(cell, at: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        
        var textField: UITextField? = findTextField(on: cell)
        
        let item = dataSource[indexPath.row]
        if item.isEditable {
            
            cell.textLabel?.text = ""
            if textField == nil {
                textField = makeTextField(on: cell)
            }
            textField?.text = item.text
            textField?.tag = indexPath.row
            
        } else {
            textField?.removeFromSuperview()
            cell.textLabel?.text = item.text
            cell.textLabel?.textColor = UIColor.black
        }
        
        textField?.textColor = grapiteColor
        cell.textLabel?.textColor = grapiteColor
        cell.backgroundColor = .clear
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = byApple ? lightTurquoiseColor : skyBlueColor
        cell.selectedBackgroundView = selectedBackgroundView
    }
    
    private func makeTextField(on cell: UITableViewCell) -> TextField {
        let textField = TextField(frame: .zero)
        textField.backgroundColor = byApple ? lightTurquoiseColor : skyBlueColor
        textField.layer.cornerRadius = 16
        textField.returnKeyType = .done
        textField.delegate = self
        cell.contentView.addSubview(textField)
        textField.left(to: cell.contentView, constant: 16)
        textField.right(to: cell.contentView, constant: 16)
        textField.top(to: cell.contentView, constant: 8)
        textField.bottom(to: cell.contentView, constant: 8)
        return textField
    }
    
    private func findTextField(on cell: UITableViewCell) -> TextField? {
        var textField: TextField?
        cell.contentView.subviews.forEach { view in
            if let view = view as? TextField {
                textField = view
            }
        }
        return textField
    }
}

extension SomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        onSelectItem?(self, dataSource[indexPath.row])
    }
}

extension SomeViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        
        dataSource[textField.tag] = Item(text: textField.text ?? "", isEditable: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
        textField.endEditing(true)
        return true
    }
}

extension SomeViewController {
    
    struct Item {
        let text: String
        let isEditable: Bool
    }
}

class TextField: UITextField {
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        CGRectInset(bounds, 16, 0)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        CGRectInset(bounds, 16, 0)
    }
}

class Button: UIButton {
    
    static let highlightedColor = UIColor(hex: 0xE18AAA)
    static let normalColor = UIColor(hex: 0xE4A0B7)
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? Button.highlightedColor : Button.normalColor
        }
    }
}
