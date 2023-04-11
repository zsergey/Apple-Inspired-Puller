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
        if #available(iOS 15.0, *) {
            var hostingController: UIViewController
            switch typeView {
            case .scrollView:
                hostingController = UIHostingController(rootView: DemoScrollView())
            case .list:
                hostingController = UIHostingController(rootView: DemoList())
            }
            addChild(hostingController)
            hostingController.didMove(toParent: self)
            view.addSubview(hostingController.view)
            hostingController.view.pin(to: view)
        }
    }
}

@available(iOS 15.0, *)
struct DemoScrollView: View {
    
    @State private var isPresented = false

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
                        .foregroundColor(Color(.grapiteColor))
                }
                .onTapGesture {
                    isPresented = true
                }
                .puller(isPresented: $isPresented,
                        model: PresentationSettings.sharedInstance.makePullerModel(detents: [.medium]),
                        content: DemoPullerContent.init)
            }
            .padding()
        }
    }
}

@available(iOS 15.0, *)
struct DemoList: View {

    @State private var isPresented = false

    var body: some View {
        List {
            ForEach(0..<20) { index in
                Text("Eat some more of these soft French buns and drink some tea.")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(16)
                    .foregroundColor(Color(.grapiteColor))
            }
            .onTapGesture {
                isPresented = true
            }
            .puller(isPresented: $isPresented,
                    model: PresentationSettings.sharedInstance.makePullerModel(detents: [.medium]),
                    content: DemoPullerContent.init)

        }
        .listStyle(PlainListStyle())
    }
}

@available(iOS 15.0, *)
struct DemoPullerContent: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Color.yellow.edgesIgnoringSafeArea(.all)
            Text("Eat some more of these soft French buns and drink some tea.")
                .font(.title)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(Color(.grapiteColor))
            Color.yellow.edgesIgnoringSafeArea(.all)
            Button("Close") {
                dismiss()
            }
            .foregroundColor(Color(.grapiteColor))
            .buttonStyle(.bordered)
            .tint(.pink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.yellow)
    }
}
