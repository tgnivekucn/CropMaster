//
//  HighlightedAreaView.swift
//  CropMaster
//
//  Created by 粘光裕 on 2023/12/18.
//
import UIKit

class HighlightedAreaView: UIView {
    private var highlightedAreaFrame: CGRect = CGRect(x: 50, y: 50, width: 100, height: 100) {
        didSet {
            setupHighlightedArea()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHighlightedArea()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupHighlightedArea()
    }

    func sethighlightedArea(frame: CGRect) {
        highlightedAreaFrame = frame
    }

    private func setupHighlightedArea() {
        let fullRectPath = UIBezierPath(rect: self.bounds)
        
        let highlightedPath = UIBezierPath(roundedRect: highlightedAreaFrame.insetBy(dx: -3, dy: -3), cornerRadius: 20)
        fullRectPath.append(highlightedPath)
        fullRectPath.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = fullRectPath.cgPath
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        maskLayer.fillColor = UIColor.blue.cgColor // Opaque part of the mask
        maskLayer.opacity = 0.5 // Adjust opacity as needed

        self.layer.mask = maskLayer
    }
}
