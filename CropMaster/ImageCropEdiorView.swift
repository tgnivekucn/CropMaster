//
//  ImageCropEdiorView.swift
//  CropMaster
//
//  Created by SomnicsAndrew on 2023/12/18.
//
import UIKit

class ImageCropEdiorView: UIView {
    private var imageView: UIImageView?
    private var maskViewOfImage: HighlightedAreaView = HighlightedAreaView()
    private let originalSelectAreaSize = CGSize(width: 200, height: 100)
    private var selectAreaFrame = CGRect(origin: .zero, size: CGSize(width: 200, height: 100)) {
        didSet {
            maskViewOfImage.sethighlightedArea(frame: selectAreaFrame)
        }
    }
    private var currentPointInImageView: CGPoint = .zero
    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 2
    private var scale: CGFloat = 1 {
        didSet {
            let newSize = CGSize(width: originalSelectAreaSize.width * scale,
                                 height: originalSelectAreaSize.height * scale)
            let newX = (currentPointInImageView.x)  - (newSize.width / 2)
            let newY = (currentPointInImageView.y)  - (newSize.height / 2)
            selectAreaFrame = CGRect(origin: CGPoint(x: newX, y: newY),
                                     size: newSize)
            setupRoundRectForLayer(rect: selectAreaFrame, layer: rectShapeLayer)
        }
    }
    private let lineWidth = CGFloat(5)
    private var imageToEdit: UIImage?
    private var fixedStartPoint: CGPoint?
    private var inMoveMode: Bool = false
    private let rectShapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = CGFloat(5)
        return shapeLayer
    }()

    var passResultImageClosure: ((UIImage?) -> Void)?

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
    func setupView(image: UIImage, closure: ((UIImage?) -> Void)?) {
        self.clipsToBounds = true
        self.imageToEdit = image
        self.passResultImageClosure = closure

        updateSubViewLayout(viewWidth: self.frame.width,
                            viewHeight: self.frame.height,
                            areaInsets: .zero,
                            imageToEdit: image)
    }

    // MARK: - Pinch related methods
    @objc private func pinch(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            break
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
            scale = 1.0
        default:
            break
        }
    }

    // MARK: - Touch related methods
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
            setupRoundRectForLayer(rect: frame, layer: rectShapeLayer)
            fixedStartPoint = getFixedStartPoint(frame: selectAreaFrame, currentPoint: currentPoint)
            selectAreaFrame = frame
        } else {
            if let fixedStartPoint = fixedStartPoint {
                let frame = rect(from: fixedStartPoint, to: currentPoint)
                selectAreaFrame = frame
                setupRoundRectForLayer(rect: frame, layer: rectShapeLayer)
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
        let frame = CGRect(origin: originPoint, size: selectAreaFrame.size)
        inMoveMode = checkIsInMoveMode(frame: selectAreaFrame, currentPoint: currentPoint)
        
        setTargetImage(frame: frame)
    }

    // MARK: - Private methods
    private func setupEvent() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        self.addGestureRecognizer(pinchGesture)
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
            
            let targetSize = getDefaultImageViewSize(imageSize: imageToEdit.size, targetSize: self.frame.size)
            self.frame.size = targetSize

        }
        
        maskViewOfImage.frame = imageView?.frame ?? .zero
        maskViewOfImage.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        self.addSubview(maskViewOfImage)
        maskViewOfImage.sethighlightedArea(frame: selectAreaFrame)
    }
    
    private func setupRectShapeLayer(imageSize: CGSize) {
        let targetSize = getDefaultImageViewSize(imageSize: imageSize, targetSize: self.frame.size)
        let originPoint = CGPoint(x: (targetSize.width / 2) - (originalSelectAreaSize.width / 2),
                                  y: (targetSize.height / 2) - (originalSelectAreaSize.height / 2))
        selectAreaFrame = CGRect(origin: .zero, size: targetSize)
        setupRoundRectForLayer(rect: selectAreaFrame, layer: rectShapeLayer)
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
        self.passResultImageClosure?(image)
    }

    private func getDefaultImageViewSize(imageSize: CGSize, targetSize: CGSize) -> CGSize {
        return calculateAspectFitSize(maxSize: targetSize, imageSize: imageSize)
    }

    private func checkIsInMoveMode(frame: CGRect, currentPoint: CGPoint) -> Bool {
        let centerAreaWidth = max(frame.width * 0.1, CGFloat(50))
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
        let topRightPoint = CGPoint(x: frame.maxX, y: frame.minY)
        let bottomLeftPoint = CGPoint(x: frame.minX, y: frame.maxY)
        let bottomRightPoint = CGPoint(x: frame.maxX, y: frame.maxY)
        
        let points = [topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint]
        let diagonallyOppositePointArr = [bottomRightPoint, bottomLeftPoint, topRightPoint, topLeftPoint]
        
        let minDiffPoint = points.min(by: {
            abs($0.x - currentPoint.x) + abs($0.y - currentPoint.y) <
                abs($1.x - currentPoint.x) + abs($1.y - currentPoint.y)
        }) ?? frame.origin
        
        if let index = points.firstIndex(of: minDiffPoint) {
            return diagonallyOppositePointArr[index]
        }
        return frame.origin
    }
    
    private func setupRoundRectForLayer(rect: CGRect, layer: CAShapeLayer) {
        let cornerRadius = CGFloat(20)

        // Create a path
        let path = UIBezierPath()

        // Add top-left rounded corner
        path.move(to: CGPoint(x: rect.origin.x + (1.5 * cornerRadius), y: rect.minY))
        path.addLine(to: CGPoint(x: rect.origin.x + cornerRadius, y: rect.origin.y))
        path.addArc(withCenter: CGPoint(x: rect.origin.x + cornerRadius, y: rect.origin.y + cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat.pi * 1.5,
                    endAngle: CGFloat.pi,
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + 1.5 * cornerRadius))

        
        // Add top-right rounded corner
        path.move(to: CGPoint(x: rect.maxX - (1.5 * cornerRadius), y: rect.origin.y))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.origin.y))
        path.addArc(withCenter: CGPoint(x: rect.maxX - cornerRadius, y: rect.origin.y + cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat.pi * 1.5,
                    endAngle: CGFloat.pi * 2,
                    clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.origin.y + 1.5 * cornerRadius))

        
        // Add lower-right rounded corner
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - (1.5 * cornerRadius)))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addArc(withCenter: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat.pi * 2,
                    endAngle: -CGFloat.pi * 1.5,
                    clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX - (1.5 * cornerRadius), y: rect.maxY))

        // Add lower-left rounded corner
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - (1.5 * cornerRadius)))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius))
        path.addArc(withCenter: CGPoint(x: rect.origin.x + cornerRadius, y: rect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: -CGFloat.pi,
                    endAngle: -CGFloat.pi * 1.5,
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + (1.5 * cornerRadius), y: rect.maxY))
        
        print("test11 finalPath: \(path)")
        rectShapeLayer.path = path.cgPath
    }
}
