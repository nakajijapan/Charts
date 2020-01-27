//
//  CutomRadarChartView.swift
//  Charts
//
//  Created by Daichi Nakajima on 2020/01/21.
//

import Foundation
import CoreGraphics


/// Implementation of the RadarChart, a "spidernet"-like chart. It works best
/// when displaying 5-10 entries per DataSet.
open class CustomRadarChartView: PieRadarChartViewBase
{
    /// width of the web lines that come from the center.
    @objc open var webLineWidth = CGFloat(1.5)

    /// width of the web lines that are in between the lines coming from the center
    @objc open var innerWebLineWidth = CGFloat(0.75)

    /// color for the web lines that come from the center
    @objc open var webColor = NSUIColor(red: 122/255.0, green: 122/255.0, blue: 122.0/255.0, alpha: 1.0)

    /// color for the web lines in between the lines that come from the center.
    @objc open var innerWebColor = NSUIColor(red: 122/255.0, green: 122/255.0, blue: 122.0/255.0, alpha: 1.0)

    /// transparency the grid is drawn with (0.0 - 1.0)
    @objc open var webAlpha: CGFloat = 150.0 / 255.0

    /// flag indicating if the web lines should be drawn or not
    @objc open var drawWeb = true

    /// modulus that determines how many labels and web-lines are skipped before the next is drawn
    private var _skipWebLineCount = 0

    /// the object reprsenting the y-axis labels
    private var _yAxis: YAxis!

    public var _yAxisRenderer: YAxisRendererCustomRaderChart!
    public var _xAxisRenderer: XAxisRendererCustomRadarChart!

    // 外枠の円
    @objc open var lastCircleColor = NSUIColor(red: 1, green: 0.6784313725490196, blue: 0.8980392156862745, alpha: 1)
    @objc open var oddCircleColor = NSUIColor.gray
    @objc open var evenCircleColor = NSUIColor.white

    public override init(frame: CGRect)
    {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }

    open override func initialize()
    {
        super.initialize()

        _yAxis = YAxis(position: .left)
        renderer = CustomRadarChartRenderer(chart: self, animator: _animator, viewPortHandler: _viewPortHandler)

        _yAxisRenderer = YAxisRendererCustomRaderChart(viewPortHandler: _viewPortHandler, yAxis: _yAxis, chart: self)
        _xAxisRenderer = XAxisRendererCustomRadarChart(viewPortHandler: _viewPortHandler, xAxis: _xAxis, chart: self)

        highlighter = RadarHighlighter(chart: self)
    }

    open override func calcMinMax()
    {
        super.calcMinMax()

        guard let data = _data else { return }

        _yAxis.calculate(min: data.getYMin(axis: .left), max: data.getYMax(axis: .left))
        _xAxis.calculate(min: 0.0, max: Double(data.maxEntryCountSet?.entryCount ?? 0))
    }

    open override func notifyDataSetChanged()
    {
        calcMinMax()

        _yAxisRenderer?.computeAxis(min: _yAxis._axisMinimum, max: _yAxis._axisMaximum, inverted: _yAxis.isInverted)
        _xAxisRenderer?.computeAxis(min: _xAxis._axisMinimum, max: _xAxis._axisMaximum, inverted: false)

        if let data = _data,
            let legend = _legend,
            !legend.isLegendCustom
        {
            legendRenderer?.computeLegend(data: data)
        }

        calculateOffsets()

        setNeedsDisplay()
    }

    open override func draw(_ rect: CGRect)
    {
        super.draw(rect)

        guard data != nil, let renderer = renderer else { return }

        let optionalContext = NSUIGraphicsGetCurrentContext()
        guard let context = optionalContext else { return }

        if _xAxis.isEnabled
        {
            _xAxisRenderer.computeAxis(min: _xAxis._axisMinimum, max: _xAxis._axisMaximum, inverted: false)
        }


        if _yAxis.isEnabled && _yAxis.isDrawLimitLinesBehindDataEnabled
        {
            _yAxisRenderer.renderLimitLines(context: context)
        }

        if drawWeb
        {
            renderer.drawWebBackGround(context: context)
        }

        renderer.drawData(context: context)

        if drawWeb
        {
            renderer.drawExtras(context: context)
        }

        if valuesToHighlight()
        {
            renderer.drawHighlighted(context: context, indices: _indicesToHighlight)
        }

        if _yAxis.isEnabled && !_yAxis.isDrawLimitLinesBehindDataEnabled
        {
            _yAxisRenderer.renderLimitLines(context: context)
        }

        _yAxisRenderer.renderAxisLabels(context: context)

        renderer.drawValues(context: context)

        //legendRenderer.renderLegend(context: context)

        drawDescription(context: context)

        drawMarkers(context: context)

        _xAxisRenderer?.renderAxisLabels(context: context)

    }

    /// The factor that is needed to transform values into pixels.
    @objc open var factor: CGFloat
    {
        let content = _viewPortHandler.contentRect
        return min(content.width / 2.0, content.height / 2.0)
            / CGFloat(_yAxis.axisRange)
    }

    /// The angle that each slice in the radar chart occupies.
    @objc open var sliceAngle: CGFloat
    {
        return 360.0 / CGFloat(_data?.maxEntryCountSet?.entryCount ?? 0)
    }

    open override func indexForAngle(_ angle: CGFloat) -> Int
    {
        // take the current angle of the chart into consideration
        let a = (angle - self.rotationAngle).normalizedAngle

        let sliceAngle = self.sliceAngle

        let max = _data?.maxEntryCountSet?.entryCount ?? 0
        return (0..<max).firstIndex {
            sliceAngle * CGFloat($0 + 1) - sliceAngle / 2.0 > a
            } ?? max
    }

    /// The object that represents all y-labels of the RadarChart.
    @objc open var yAxis: YAxis
    {
        return _yAxis
    }

    /// Sets the number of web-lines that should be skipped on chart web before the next one is drawn. This targets the lines that come from the center of the RadarChart.
    /// if count = 1 -> 1 line is skipped in between
    @objc open var skipWebLineCount: Int
        {
        get
        {
            return _skipWebLineCount
        }
        set
        {
            _skipWebLineCount = max(0, newValue)
        }
    }

    open override var requiredLegendOffset: CGFloat
    {
        return _legend.font.pointSize * 4.0
    }

    open override var requiredBaseOffset: CGFloat
    {
        return 64
        //return _xAxis.isEnabled && _xAxis.isDrawLabelsEnabled ? _xAxis.labelRotatedWidth : 10.0
    }

    open override var radius: CGFloat
    {
        let content = _viewPortHandler.contentRect
        return min(content.width / 2.0, content.height / 2.0)
    }

    /// The maximum value this chart can display on it's y-axis.
    open override var chartYMax: Double { return _yAxis._axisMaximum }

    /// The minimum value this chart can display on it's y-axis.
    open override var chartYMin: Double { return _yAxis._axisMinimum }

    /// The range of y-values this chart can display.
    @objc open var yRange: Double { return _yAxis.axisRange }

    open override func calculateOffsets()
    {
        var legendLeft = CGFloat(0.0)
        var legendRight = CGFloat(0.0)
        var legendBottom = CGFloat(0.0)
        var legendTop = CGFloat(0.0)


        legendLeft += self.requiredBaseOffset
        legendRight += self.requiredBaseOffset
        legendTop += self.requiredBaseOffset
        legendBottom += self.requiredBaseOffset

        /*
        legendTop += self.extraTopOffset
        legendRight += self.extraRightOffset
        legendBottom += self.extraBottomOffset
        legendLeft += self.extraLeftOffset
         */

        let offsetLeft = legendLeft + 16
        let offsetTop = legendTop + 16
        let offsetRight = legendRight + 16
        let offsetBottom = min(self.requiredBaseOffset, legendBottom)

        _viewPortHandler.restrainViewPort(offsetLeft: offsetLeft, offsetTop: offsetTop, offsetRight: offsetRight, offsetBottom: offsetBottom)
    }
}
