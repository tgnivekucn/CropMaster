//
//  ImageCropEdiorView.swift
//  CropMaster
//
//  Created by SomnicsAndrew on 2023/12/18.
//

import UIKit

class ImageCropEdiorView: UIView {
    private var imageView: UIImageView?
    private let originalSelectAreaSize = CGSize(width: 200, height: 100)
    private var selectAreaFrame = CGRect(origin: .zero, size: CGSize(width: 200, height: 100)) {
        didSet {
            print("test88 selectAreaFrame: \(selectAreaFrame)")
        }
    }
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

    private var startPoint: CGPoint?
    private var fixedStartPoint: CGPoint?
    private var inMoveMode: Bool = false
    var passResultImageClosure: ((UIImage?) -> Void)?
    let rectShapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = CGFloat(5)
        return shapeLayer
    }()
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEvent()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEvent()
    }
    
    private func commonInit() {
         // Perform initialization tasks here
         // For example, setup subviews, add constraints, configure appearance
//         setupSubviews()
//         setupConstraints()
//         configureAppearance()
     }
     
     override func willMove(toSuperview newSuperview: UIView?) {
         super.willMove(toSuperview: newSuperview)
         // Called when the view is about to be added or removed from its superview
         if newSuperview != nil {
             // View is being added to a superview
         } else {
             // View is being removed from its superview
         }
     }
     
     override func layoutSubviews() {
         super.layoutSubviews()
         // Called when the view's bounds or constraints change
         // Perform layout-related tasks here, such as updating subview frames or constraints
     }
     
     override func draw(_ rect: CGRect) {
         super.draw(rect)
         // Called to draw the view's content
         // Perform custom drawing here using Core Graphics or other drawing APIs
     }
     
     override func didMoveToSuperview() {
         super.didMoveToSuperview()
         // Called when the view has been added or removed from its superview
         if superview != nil {
             // View has been added to a superview
         } else {
             // View has been removed from its superview
         }
     }
     
     override func didMoveToWindow() {
         super.didMoveToWindow()
         // Called when the view has been added or removed from a window
         if window != nil {
             // View has been added to a window
         } else {
             // View has been removed from a window
         }
     }
     
     override func removeFromSuperview() {
         // Perform cleanup tasks here
         // Remove any observers, release resources, etc.
         
         super.removeFromSuperview()
     }

    // MARK: - Internal methods
    func setupView(image: UIImage) {
        self.clipsToBounds = true
        self.imageToEdit = image
        updateSubViewLayout(viewWidth: self.frame.width,
                            viewHeight: self.frame.height,
                            areaInsets: .zero,
                            imageToEdit: image)
    }

    // MARK: - Private methods
    private func setupEvent() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        self.addGestureRecognizer(pinchGesture)
    }
    
    private func hide() {
        passResultImageClosure?(croppedImage)
    }

    private func updateSubViewLayout(viewWidth: CGFloat, viewHeight: CGFloat, areaInsets: UIEdgeInsets, imageToEdit: UIImage?) {
        // Remove the rectShapeLayer to avoid adding the rectShapeLayer repeatedly
        rectShapeLayer.removeFromSuperlayer()

        // Setup rectShapeLayer
        if let imageToEdit = imageToEdit {
            setupRectShapeLayer(imageSize: imageToEdit.size)
        }

        // Setup imageView
        if let imageToEdit = imageToEdit {
            setupImageView(imageSize: imageToEdit.size,
                      safeAreaWidth: viewWidth,
                      safeAreaHeight: viewHeight,
                      safeAreaInsets: areaInsets)
           
            imageView?.layer.addSublayer(rectShapeLayer)
        }
    }

    private func setupRectShapeLayer(imageSize: CGSize) {
        let targetSize = getDefaultImageViewSize(imageSize: imageSize, targetSize: self.frame.size)
        let originPoint = CGPoint(x: (targetSize.width / 2) - (originalSelectAreaSize.width / 2),
                                       y: (targetSize.height / 2) - (originalSelectAreaSize.height / 2))
        rectShapeLayer.path = UIBezierPath(rect: CGRect(origin: originPoint, size: selectAreaFrame.size)).cgPath
        selectAreaFrame = CGRect(origin: originPoint, size: selectAreaFrame.size)
    }

    private func setupImageView(imageSize: CGSize, safeAreaWidth: CGFloat, safeAreaHeight: CGFloat, safeAreaInsets: UIEdgeInsets) {
        // 1. Remove the image view to avoid adding the image view repeatedly
        imageView?.removeFromSuperview()

        // 2. setup imageView
        let targetSize = getDefaultImageViewSize(imageSize: imageSize, targetSize: self.frame.size)
        let originPoint = CGPoint(x: safeAreaInsets.left, y: safeAreaInsets.top)
        imageView = UIImageView(frame: CGRect(origin: originPoint,
                                              size: targetSize))
        if let imageView = imageView {
            self.addSubview(imageView)
        }
        imageView?.image = imageToEdit
        imageView?.contentMode = .scaleAspectFit
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

    private func getDefaultImageViewSize(imageSize: CGSize, targetSize: CGSize) -> CGSize {
        return calculateAspectFitSize(maxSize: targetSize, imageSize: imageSize)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let currentPoint: CGPoint
        
        if let predicted = event?.predictedTouches(for: touch), let lastPoint = predicted.last {
            currentPoint = lastPoint.location(in: imageView)
        } else {
            currentPoint = touch.location(in: imageView)
        }
        fixedStartPoint = getFixedStartPoint(frame: selectAreaFrame, currentPoint: currentPoint)
        inMoveMode = checkIsInMoveMode(frame: selectAreaFrame, currentPoint: currentPoint)
        print("test11 inMoveMode: \(inMoveMode), selectAreaFrame: \(selectAreaFrame)")
    }

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

        let expandedFrame = selectAreaFrame.insetBy(dx: -50, dy: -50)
        guard expandedFrame.contains(currentPoint) else { return }
        
        if inMoveMode {
            let originPoint = getSelectAreaOriginPoint(touchPoint: currentPoint,
                                                       selectAreaSize: selectAreaFrame.size,
                                                       imageSize: imageView.frame.size)
            let frame = CGRect(origin: originPoint, size: selectAreaFrame.size) //rect(from: startPoint, to: currentPoint)
            rectShapeLayer.path = UIBezierPath(rect: frame).cgPath
            fixedStartPoint = getFixedStartPoint(frame: selectAreaFrame, currentPoint: currentPoint)
            selectAreaFrame = frame
        } else {
            if let fixedStartPoint = fixedStartPoint {
                let frame = rect(from: fixedStartPoint, to: currentPoint)
                selectAreaFrame = frame
                rectShapeLayer.path = UIBezierPath(rect: frame).cgPath
            }
        }
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
        inMoveMode = checkIsInMoveMode(frame: selectAreaFrame, currentPoint: currentPoint)

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

    // MARK: - Utility methods
    private func checkIsInMoveMode(frame: CGRect, currentPoint: CGPoint) -> Bool {
        let centerAreaWidth = frame.width * 0.1
        let centerPoint = CGPoint(x: frame.origin.x + (frame.width / 2), y: frame.origin.y + (frame.height / 2))
        if (abs(currentPoint.x - centerPoint.x) < centerAreaWidth) && (abs(currentPoint.y - centerPoint.y) < centerAreaWidth) {
            return true
        }
        return false
    }

    private func calculateAspectFitSize(maxSize: CGSize, imageSize: CGSize) -> CGSize {
        let widthRatio = maxSize.width / imageSize.width
        let heightRatio = maxSize.height / imageSize.height
        let ratio = min(widthRatio, heightRatio)

        let newWidth = imageSize.width * ratio
        let newHeight = imageSize.height * ratio
        return CGSize(width: newWidth, height: newHeight)
    }
    
    private func getFixedStartPoint(frame: CGRect, currentPoint: CGPoint) -> CGPoint {
        let topLeftPoint = frame.origin
        let topRightPoint = CGPoint(x: (frame.origin.x + frame.width), y: frame.origin.y)
        let bottomLeftPoint = CGPoint(x: frame.origin.x, y: (frame.origin.y + frame.height))
        let bottomRightPoint = CGPoint(x: (frame.origin.x + frame.width), y: (frame.origin.y + frame.height))

        let topLeftPointWeight = abs(topLeftPoint.x - currentPoint.x) + abs(topLeftPoint.y - currentPoint.y)
        let topRightPointWeight = abs(topRightPoint.x - currentPoint.x) + abs(topRightPoint.y - currentPoint.y)
        let bottomLeftPointWeight = abs(bottomLeftPoint.x - currentPoint.x) + abs(bottomLeftPoint.y - currentPoint.y)
        let bottomRightPointWeight = abs(bottomRightPoint.x - currentPoint.x) + abs(bottomRightPoint.y - currentPoint.y)

        let min1 = min(topLeftPointWeight, topRightPointWeight)
        let min2 = min(bottomLeftPointWeight, bottomRightPointWeight)
        if min1 < min2 {
            if topLeftPointWeight < topRightPointWeight {
                return bottomRightPoint // topLeftPoint
            } else {
                return bottomLeftPoint // topRightPoint
            }
        } else {
            if bottomLeftPointWeight < bottomRightPointWeight {
                return topRightPoint // bottomLeftPoint
            } else {
                return topLeftPoint // bottomRightPoint
            }
        }
    }
}
