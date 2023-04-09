//
//  SwiftUIViewController.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 09.04.2023.
//

import SwiftUI

class SwiftUIViewController: UIViewController {
    
    var typeView: MainViewController.Item.TypeSwifUIView
    
    init(typeView: MainViewController.Item.TypeSwifUIView) {
        self.typeView = typeView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    private func setupView() {
        if #available(iOS 13.0, *) {
            var hostingController: UIViewController
            switch typeView {
            case .scrollView:
                hostingController = UIHostingController(rootView: DemoScrollView())
            case .list:
                hostingController = UIHostingController(rootView: DemoList())
            }
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.pin(to: view)
        }
    }
}

@available(iOS 13.0, *)
struct DemoScrollView: View {
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<20) { _ in
                    Text("Eat some more of these soft French buns and drink some tea.")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(16)
                        .foregroundColor(Color(UIColor(hex: 0x11100C)))
                }
            }
            .padding()
            .foregroundColor(.green)
        }
    }
}

@available(iOS 13.0, *)
struct DemoList: View {
    
    var body: some View {
        List {
            ForEach(0..<20) { index in
                Text("Eat some more of these soft French buns and drink some tea.")
                    .font(.body)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(16)
                    .foregroundColor(Color(UIColor(hex: 0x11100C)))
            }
        }
        .listStyle(PlainListStyle())
    }
}
