//
//  IntAxisValueFormatter.swift
//  ChartsDemo-iOS
//
//  Created by Jacob Christie on 2017-07-09.
//  Copyright © 2017 jc. All rights reserved.
//

import Foundation
import Charts

public class IntAxisValueFormatter: NSObject, IAxisValueFormatter {
    public func imageForValue(_ value: Double, axis: AxisBase?) -> NSUIImage? {
        nil
    }
    
    public func extraImageForValue(_ value: Double, axis: AxisBase?) -> NSUIImage? {
        nil
    }
    
    public func drawLabelPoint(basePoint: CGPoint, axis: AxisBase?, angle: CGFloat) -> CGPoint {
        .zero
    }
    
    public func extraImagePointForValue(_ value: Double, axis: AxisBase?, basePoint: CGPoint) -> CGPoint {
        .zero
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return "\(Int(value))"
    }
}
