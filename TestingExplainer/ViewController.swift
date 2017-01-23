//
//  ViewController.swift
//  TestingExplainer
//
//  Created by Sam Watts on 20/01/2017.
//  Copyright © 2017 Sam Watts. All rights reserved.
//

import UIKit

extension UIColor {
    
    @objc(love_randomColor)
    class var random: UIColor {
        
        let hue = ( Double(Double(arc4random()).truncatingRemainder(dividingBy: 256.0) ) / 256.0 )
        let saturation = ( (Double(arc4random()).truncatingRemainder(dividingBy: 128)) / 256.0 ) + 0.5
        let brightness = ( (Double(arc4random()).truncatingRemainder(dividingBy: 128)) / 256.0 ) + 0.5
        
        return UIColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: 1.0)
    }
}

//MARK: Demo view controller

class DemoLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else { return }
        
        let padding: CGFloat = 10
        let columns: CGFloat = 3
        let itemWidth = (collectionView.bounds.width - (padding * (columns + 1))) / 3
        
        let itemHeight = itemWidth
        self.itemSize = CGSize(width: itemWidth, height: itemHeight)
        self.minimumLineSpacing = padding
        self.minimumInteritemSpacing = padding
        self.scrollDirection = .vertical
    }
}

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: DemoLayout())
        
        collectionView.register(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "cell")
        
        return collectionView
    }()
    
    let cellColours: [UIColor] = {
        return [
            .random,
            .random,
            .random,
            .random,
            .random,
            .random,
            .random,
            .random,
            .random,
            .random,
            .random,
            .random,
            .random,
            .random,
            .random
        ]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Collection View"
        
        self.view.addSubview(collectionView)
        collectionView.backgroundColor = .white
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Show Overlay", style: .plain, target: self, action: #selector(ViewController.showOverlay))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Bar Button", style: .plain, target: self, action: #selector(ViewController.showOverlayFromBarButtonItem))
    }
    
    func showOverlay() {
    
        let highlightView = collectionView.cellForItem(at: IndexPath(item: 2, section: 0))
        self.setOverlay(withHighlightView: highlightView)
    }
    
    func showOverlayFromBarButtonItem() {
        
        self.setOverlay(withBarButtonItem: self.navigationItem.leftBarButtonItem, padding: CGSize(width: 10, height: 10), offsetToRight: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellColours.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        cell.backgroundColor = cellColours[indexPath.item]
        
        return cell
    }
    
    
}

//MARK: Add overlay helpers

import ObjectiveC.runtime

var overlayWindowAssociatedObjectKey: UInt8 = 0

extension UIViewController {
    
    // Yay stored properties in extensions
    var overlayWindow: UIWindow? {
        get {
            return objc_getAssociatedObject(self, &overlayWindowAssociatedObjectKey) as? UIWindow
        }
        set {
            objc_setAssociatedObject(self, &overlayWindowAssociatedObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    // Should be showOverlay or similar
    func setOverlay(withHighlightView highlightView: UIView?, padding: CGSize = .zero, offsetToRight: Bool = false) {
        guard let existingWindow = UIApplication.shared.keyWindow else { return }
        
        let window = UIWindow(frame: existingWindow.bounds)
        self.overlayWindow = window
        
        window.windowLevel = UIWindowLevelStatusBar

        
        window.rootViewController = OverlayViewController(highlightView: highlightView, padding: padding, offsetToRight: offsetToRight) { [weak self] in
            self?.overlayWindow = nil
        }
        
        window.makeKeyAndVisible()
    }
    
    func setOverlay(withBarButtonItem barButtonItem: UIBarButtonItem?, padding: CGSize = .zero, offsetToRight: Bool = false) {
        guard let existingWindow = UIApplication.shared.keyWindow else { return }
        
        let window = UIWindow(frame: existingWindow.bounds)
        self.overlayWindow = window
        
        window.windowLevel = UIWindowLevelStatusBar
        
        window.rootViewController = OverlayViewController(barButtonItem: barButtonItem, padding: padding, offsetToRight: offsetToRight) { [weak self] in
            self?.overlayWindow = nil
        }
        
        window.makeKeyAndVisible()
    }
    
}

//MARK: Overlay root view controller

class OverlayViewController: UIViewController {
    
    let completionClosure: () -> ()
    
    weak private(set) var highlightView: UIView?
    weak private(set) var barButtonItem: UIBarButtonItem?
    
    let padding: CGSize
    let offsetToRight: Bool
    
    required init(highlightView: UIView?, padding: CGSize, offsetToRight: Bool, completion: @escaping () -> ()) {
        self.completionClosure = completion
        self.highlightView = highlightView
        self.padding = padding
        self.offsetToRight = offsetToRight
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(barButtonItem: UIBarButtonItem?, padding: CGSize, offsetToRight: Bool, completion: @escaping () -> ()) {
        self.completionClosure = completion
        self.barButtonItem = barButtonItem
        self.padding = padding
        self.offsetToRight = offsetToRight
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable, message: "use init(completion:) instead")
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    private var highlightBorderView: UIView?
    private var explainerView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        self.view.layer.borderColor = UIColor.red.cgColor
        self.view.layer.borderWidth = 2
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(removeOverlay))
        tap.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tap)
        
        
        if let highlightView = highlightView {
            
            highlightBorderView = UIView()
            highlightBorderView?.layer.borderColor = UIColor.red.cgColor
            highlightBorderView?.layer.borderWidth = 5
            self.view.addSubview(highlightBorderView!)
            
                            // Last I remember (And google from 2012 agrees) bounds is not strictly KVO compliant  
            highlightView.layer.addObserver(self, forKeyPath: "bounds", options: [], context: nil)
            
            explainerView = UIView()
            explainerView?.backgroundColor = .red
            self.view.addSubview(explainerView!)
            
            explainerView?.translatesAutoresizingMaskIntoConstraints = false
            explainerView?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            explainerView?.heightAnchor.constraint(equalToConstant: 500).isActive = true
            explainerView?.widthAnchor.constraint(equalToConstant: 300).isActive = true
            
            if offsetToRight {
                explainerView?.leftAnchor.constraint(equalTo: highlightBorderView!.rightAnchor, constant: 50).isActive = true
            } else {
                explainerView?.rightAnchor.constraint(equalTo: highlightBorderView!.leftAnchor, constant: -50).isActive = true
            }
            
        } else if let _ = barButtonItem {
            
            highlightBorderView = UIView()
            highlightBorderView?.layer.borderColor = UIColor.red.cgColor
            highlightBorderView?.layer.borderWidth = 5
            self.view.addSubview(highlightBorderView!)
            
            explainerView = UIView()
            explainerView?.backgroundColor = .red
            self.view.addSubview(explainerView!)
            
            explainerView?.translatesAutoresizingMaskIntoConstraints = false
            explainerView?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            explainerView?.heightAnchor.constraint(equalToConstant: 500).isActive = true
            explainerView?.widthAnchor.constraint(equalToConstant: 300).isActive = true
            
            if offsetToRight {
                explainerView?.leftAnchor.constraint(equalTo: highlightBorderView!.rightAnchor, constant: 50).isActive = true
            } else {
                explainerView?.rightAnchor.constraint(equalTo: highlightBorderView!.leftAnchor, constant: -50).isActive = true
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let highlightView = highlightView else { return }
        
        let convertedFrame = self.view.convert(highlightView.frame, from: highlightView.superview)
        highlightBorderView?.frame = convertedFrame
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let highlightView = highlightView {
        
            let convertedFrame = self.view.convert(highlightView.frame, from: highlightView.superview)
            highlightBorderView?.frame = convertedFrame.insetBy(dx: -padding.width, dy: -padding.height)

                                                    // I bet this is undocumented, isn't it?
        } else if let barButtonItemView = barButtonItem?.value(forKey: "view") as? UIView {
            highlightBorderView?.frame = barButtonItemView.frame.offsetBy(dx: 0, dy: UIApplication.shared.statusBarFrame.height).insetBy(dx: -padding.width, dy: -padding.height)
        }
    }
    
    func removeOverlay() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.window?.alpha = 0.0
        }) { _ in
            self.view.window?.resignKey()
            self.completionClosure()
        }
    }
}

