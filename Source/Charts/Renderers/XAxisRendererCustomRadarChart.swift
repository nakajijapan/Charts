//
//  XAxisRendererCustomRadarChart.swift
//  Charts
//
//  Created by Daichi Nakajima on 2020/01/21.
//

import Foundation
import CoreGraphics

open class XAxisRendererCustomRadarChart: XAxisRenderer
{
    @objc open weak var chart: CustomRadarChartView?

    @objc public init(viewPortHandler: ViewPortHandler, xAxis: XAxis?, chart: CustomRadarChartView)
    {
        super.init(viewPortHandler: viewPortHandler, xAxis: xAxis, transformer: nil)

        self.chart = chart
    }

    open override func renderAxisLabels(context: CGContext)
    {
        guard let
            xAxis = axis as? XAxis,
            let chart = chart
            else { return }

        if !xAxis.isEnabled || !xAxis.isDrawLabelsEnabled
        {
            return
        }

        let labelFont = xAxis.labelFont
        let labelTextColor = xAxis.labelTextColor
        let labelRotationAngleRadians = xAxis.labelRotationAngle.RAD2DEG
        let drawLabelAnchor = CGPoint(x: 0.5, y: 0.25)

        let sliceangle = chart.sliceAngle

        // calculate the factor that is needed for transforming the value to pixels
        let factor = chart.factor

        let center = chart.centerOffsets

        for i in stride(from: 0, to: chart.data?.maxEntryCountSet?.entryCount ?? 0, by: 1)
        {

            let label = xAxis.valueFormatter?.stringForValue(Double(i), axis: xAxis) ?? ""
            let angle = (sliceangle * CGFloat(i) + chart.rotationAngle).truncatingRemainder(dividingBy: 360.0)
            var p = center.moving(distance: CGFloat(chart.yRange) * factor + xAxis.labelRotatedWidth / 2.0, atAngle: angle)
            p = xAxis.valueFormatter?.drawLabelPoint(basePoint: p, axis: xAxis, angle: angle) ?? p

            drawLabel(context: context,
                      formattedLabel: label,
                      x: p.x,
                      y: p.y + xAxis.labelRotatedHeight * 1.2,
                      attributes: [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: labelTextColor],
                      anchor: drawLabelAnchor,
                      angleRadians: labelRotationAngleRadians)

            if let image = xAxis.valueFormatter?.imageForValue(Double(i), axis: xAxis) {
                drawImage(
                    context: context,
                    image: image,
                    x: p.x,
                    y: p.y - xAxis.labelRotatedHeight / 2.0
                )
            }

            if let extraImage = xAxis.valueFormatter?.extraImageForValue(Double(i), axis: xAxis) {
                drawExtraImage(
                    context: context,
                    image: extraImage,
                    x: p.x,
                    y: p.y - xAxis.labelRotatedHeight * 2.0
                )
            }

        }
    }

    @objc open func drawLabel(
        context: CGContext,
        formattedLabel: String,
        x: CGFloat,
        y: CGFloat,
        attributes: [NSAttributedString.Key : Any],
        anchor: CGPoint,
        angleRadians: CGFloat)
    {
        ChartUtils.drawText(
            context: context,
            text: formattedLabel,
            point: CGPoint(x: x, y: y),
            attributes: attributes,
            anchor: anchor,
            angleRadians: angleRadians)
    }

    @objc open func drawImage(
        context: CGContext,
        image: NSUIImage,
        x: CGFloat,
        y: CGFloat
    )
    {
        ChartUtils.drawImage(
            context: context,
            image: image,
            x: x, y: y,
            size: image.size
        )
    }

    @objc open func drawExtraImage(
        context: CGContext,
        image: NSUIImage,
        x: CGFloat,
        y: CGFloat
    )
    {
        ChartUtils.extraDrawImage(
            context: context,
            image: image,
            x: x, y: y,
            size: image.size,
            angle: chart?.extraDrawImageAngle ?? 0
        )
    }

    open override func renderLimitLines(context: CGContext)
    {
        /// XAxis LimitLines on RadarChart not yet supported.
    }
}
