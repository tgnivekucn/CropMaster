//
//  CustomImageEditorViewController.swift
//  CustomSelectAreaOfImagePhotoPicker
//
//  Created by 粘光裕 on 2023/12/17.
//

import UIKit

class CustomImageEditorViewController: UIViewController {
    private var imageView: UIImageView?
    private let originalSelectAreaSize = CGSize(width: 200, height: 100)
    private var selectAreaFrame = CGRect(origin: .zero, size: CGSize(width: 200, height: 100))
    private var currentPointInImageView: CGPoint = .zero
    private var isPinching: Bool = false
    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 2
    private var scale: CGFloat = 1 {
        didSet {
            print("test11 current scale is: \(scale)")
            let newSize = CGSize(width: originalSelectAreaSize.width * scale,
                                 height: originalSelectAreaSize.height * scale)
            let newX = (currentPointInImageView.x)  - (newSize.width / 2)
            let newY = (currentPointInImageView.y)  - (newSize.height / 2)
            selectAreaFrame = CGRect(origin: CGPoint(x: newX, y: newY),
                                     size: newSize)
            rectShapeLayer.path = UIBezierPath(rect: selectAreaFrame).cgPath
        }
    }
    private var isAddRectShapeLayer = false
    private var croppedImage: UIImage?
    private var hasSetupView: Bool = false
    private let lineWidth = CGFloat(5)
    var imageToEdit: UIImage?

    var startPoint: CGPoint?
    var passResultImageClosure: ((UIImage?) -> Void)?
    let rectShapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = CGFloat(5)
        return shapeLayer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeAreaInsets = view.safeAreaInsets
        let safeAreaWidth = view.bounds.width - safeAreaInsets.left - safeAreaInsets.right
        let safeAreaHeight = view.bounds.height - safeAreaInsets.top - safeAreaInsets.bottom
        // Now you can use safeAreaWidth and safeAreaHeight
        print("test11 viewDidLayoutSubviews ~~")

        if let imageToEdit = imageToEdit {
            setupView(imageSize: imageToEdit.size,
                      safeAreaWidth: safeAreaWidth,
                      safeAreaHeight: safeAreaHeight,
                      safeAreaInsets: safeAreaInsets)
           
            imageView?.layer.addSublayer(rectShapeLayer)
            let targetSize = getDefaultImageViewSize(imageSize: imageToEdit.size)
            let originPoint = CGPoint(x: (targetSize.width / 2) - (originalSelectAreaSize.width / 2),
                                           y: (targetSize.height / 2) - (originalSelectAreaSize.height / 2))
            rectShapeLayer.path = UIBezierPath(rect: CGRect(origin: originPoint, size: selectAreaFrame.size)).cgPath
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        passResultImageClosure?(croppedImage)
    }

    func setupView(imageSize: CGSize, safeAreaWidth: CGFloat, safeAreaHeight: CGFloat, safeAreaInsets: UIEdgeInsets) {
        let targetSize = getDefaultImageViewSize(imageSize: imageSize)
        let originPoint = CGPoint(x: safeAreaInsets.left, y: safeAreaInsets.top)
        imageView = UIImageView(frame: CGRect(origin: originPoint,
                                              size: targetSize))
        if let imageView = imageView {
            self.view.addSubview(imageView)
        }
        imageView?.image = imageToEdit
    }

    @objc private func pinch(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isPinching = true
            
        case .changed, .ended:
            if gesture.scale <= minScale {
                scale = minScale
            } else if gesture.scale >= maxScale {
                scale = maxScale
            } else {
                scale = gesture.scale
            }
            if gesture.state == .ended {
                setTargetImage(frame: selectAreaFrame)
            }
        case .cancelled, .failed:
            isPinching = false
            scale = 1.0
        default:
            break
        }
    }

    private func getDefaultImageViewSize(imageSize: CGSize) -> CGSize {
        let screenWidth = UIScreen.main.bounds.size.width
        var resultSize = CGSize.zero
        if imageSize.width > screenWidth {
            let ratio = screenWidth / imageSize.width
            resultSize = CGSize(width: screenWidth, height: imageSize.height * ratio)
        } else {
            let ratio = imageSize.width / screenWidth
            resultSize = CGSize(width: screenWidth, height: imageSize.height * ratio)
        }
        return resultSize
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let imageView = imageView else { return }
        guard let touch = touches.first else { return }

        let currentPoint: CGPoint

        if let predicted = event?.predictedTouches(for: touch), let lastPoint = predicted.last {
            currentPoint = lastPoint.location(in: imageView)
        } else {
            currentPoint = touch.location(in: imageView)
        }
        currentPointInImageView = currentPoint

        let originPoint = getSelectAreaOriginPoint(touchPoint: currentPoint,
                                                   selectAreaSize: selectAreaFrame.size,
                                                   imageSize: imageView.frame.size)
        let frame = CGRect(origin: originPoint, size: selectAreaFrame.size) //rect(from: startPoint, to: currentPoint)

        rectShapeLayer.path = UIBezierPath(rect: frame).cgPath
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let imageView = self.imageView else { return }
        guard let touch = touches.first else { return }

        let currentPoint = touch.location(in: imageView)
        currentPointInImageView = currentPoint

        let originPoint = getSelectAreaOriginPoint(touchPoint: currentPoint,
                                                   selectAreaSize: selectAreaFrame.size,
                                                   imageSize: imageView.frame.size)
        let frame = CGRect(origin: originPoint, size: selectAreaFrame.size) //rect(from: startPoint, to: currentPoint)
        
        setTargetImage(frame: frame)
    }

    private func rect(from: CGPoint, to: CGPoint) -> CGRect {
        return CGRect(x: min(from.x, to.x),
               y: min(from.y, to.y),
               width: abs(to.x - from.x),
               height: abs(to.y - from.y))
    }

    private func getSelectAreaOriginPoint(touchPoint: CGPoint, selectAreaSize: CGSize, imageSize: CGSize) -> CGPoint {
        var tmpY = touchPoint.y - (selectAreaSize.height / 2)
        var tmpX = touchPoint.x - (selectAreaSize.width / 2)

        if (tmpX - lineWidth) < 0 {
            tmpX = (lineWidth / 2)
        }
        if (tmpX + selectAreaSize.width + lineWidth) > imageSize.width {
            tmpX = (imageSize.width - selectAreaSize.width - (lineWidth / 2))
        }
        
        if (tmpY - lineWidth) < 0 {
            tmpY = 0
        }
        if (tmpY + selectAreaSize.height + lineWidth) > imageSize.height {
            tmpY = (imageSize.height - selectAreaSize.height)
        }
        return CGPoint(x: tmpX, y: tmpY)
    }

    private func setTargetImage(frame: CGRect) {
        guard let imageView = imageView else { return }
        rectShapeLayer.removeFromSuperlayer()
        let image = imageView.snapshot(rect: frame, afterScreenUpdates: true)
        imageView.layer.addSublayer(rectShapeLayer)

        print("test11 image: \(image)")
        self.croppedImage = image
    }
}

extension UIView {

    /// Create image snapshot of view.
    ///
    /// - Parameters:
    ///   - rect: The coordinates (in the view's own coordinate space) to be captured. If omitted, the entire `bounds` will be captured.
    ///   - afterScreenUpdates: A Boolean value that indicates whether the snapshot should be rendered after recent changes have been incorporated. Specify the value false if you want to render a snapshot in the view hierarchy’s current state, which might not include recent changes.
    /// - Returns: The `UIImage` snapshot.
    func snapshot(rect: CGRect? = nil, afterScreenUpdates: Bool = true) -> UIImage {
        return UIGraphicsImageRenderer(bounds: rect ?? bounds).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
        }
    }
}
