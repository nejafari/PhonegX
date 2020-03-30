//
//  CanvasView.swift
//  Negpho
//
//  Created by Negar Jafari on 1/29/20.
//  Copyright © 2020 Negar Jafari. All rights reserved.
//

import UIKit

class CanvasView: UIView {

    var lineColor:UIColor!
    var lineWidth:CGFloat!
    var path:UIBezierPath!
    var touchPoint:CGPoint!
    var startingPoint:CGPoint!
    
    var actionLayers = [CALayer]() //object that manages image-based content and allows you to perform animations
    
    override func layoutSubviews() {
        self.clipsToBounds = true
        self.isMultipleTouchEnabled = false
        lineColor = UIColor.black
        lineWidth = 5
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        startingPoint = touch?.location(in: self)
        actionLayers.removeAll()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let layers = actionLayers
        undoManager?.registerUndo(withTarget: self, handler: { canvas in
            layers.forEach { $0.removeFromSuperlayer() }
            canvas.setNeedsDisplay()
        })
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        touchPoint = touch?.location(in: self)
        
        path = UIBezierPath()
        path.move(to: startingPoint)
        path.addLine(to: touchPoint)
        startingPoint = touchPoint
        
        drawLayer()
    }
    
    func drawLayer() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = lineColor.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(shapeLayer)
        self.setNeedsDisplay()
        
        actionLayers.append(shapeLayer)
        
    }
    
    func clearDraw() {
        path.removeAllPoints()
        self.layer.sublayers = nil
        self.setNeedsDisplay()
    }

}
