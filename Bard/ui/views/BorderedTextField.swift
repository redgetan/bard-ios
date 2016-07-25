//
//  BorderedTextField.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-25.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit

// http://stackoverflow.com/a/30191658/803865

@IBDesignable
class BorderedTextField: UITextField {
    
    @IBInspectable var linesWidth: CGFloat = 1.0 { didSet{ drawLines() } }
    
    @IBInspectable var linesColor: UIColor = UIColor.blackColor() { didSet{ drawLines() } }
    
    @IBInspectable var leftLine: Bool = false { didSet{ drawLines() } }
    @IBInspectable var rightLine: Bool = false { didSet{ drawLines() } }
    @IBInspectable var bottomLine: Bool = false { didSet{ drawLines() } }
    @IBInspectable var topLine: Bool = false { didSet{ drawLines() } }
    
    
    
    func drawLines() {
        
        if bottomLine {
            add(CGRectMake(0.0, frame.size.height - linesWidth, frame.size.width, linesWidth))
        }
        
        if topLine {
            add(CGRectMake(0.0, 0.0, frame.size.width, linesWidth))
        }
        
        if rightLine {
            add(CGRectMake(frame.size.width - linesWidth, 0.0, linesWidth, frame.size.height))
        }
        
        if leftLine {
            add(CGRectMake(0.0, 0.0, linesWidth, frame.size.height))
        }
        
    }
    
    typealias Line = CGRect
    private func add(line: Line) {
        let border = CALayer()
        border.frame = line
        border.backgroundColor = linesColor.CGColor
        layer.addSublayer(border)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawLines()
    }
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 10, 10);
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 10, 10);
    }
    
    
}
