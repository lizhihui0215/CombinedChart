@testable import CombinedChartFramework
import SwiftUI
import XCTest

final class ChartDerivedStateTests: XCTestCase {
    @MainActor
    func testChartDerivedStateBuildsExpectedAxisDomainAndLabel() {
        let config = ChartConfig.default
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [
                    .liabilities: 10,
                    .saving: 20,
                    .investment: 5
                ]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [
                    .liabilities: 4,
                    .saving: 12
                ])
        ]
        let axisPointInfos = data.enumerated().map { index, point in
            point.axisPointInfo(index: index)
        }

        let derivedState = CombinedChartView.DerivedState(
            config: config,
            sortedGroups: [ChartTestBuilders.makeGroup(id: "2024", title: "2024", order: 0, points: data)],
            data: data,
            axisPointInfos: axisPointInfos,
            startIndex: 1,
            contentOffsetX: 100,
            unitWidth: 100)

        XCTAssertTrue(derivedState.hasData)
        XCTAssertEqual(derivedState.viewport.visibleStartLabel, "Jan")
        XCTAssertEqual(derivedState.axisPointInfos.count, 2)
        XCTAssertEqual(derivedState.yDomain.lowerBound, -13.5)
        XCTAssertEqual(derivedState.yDomain.upperBound, 28.5)
        XCTAssertEqual(derivedState.yAxisTickValues, [-30, -24, -18, -12, -6, 0, 6, 12, 18, 24, 30])
        XCTAssertEqual(derivedState.yAxisDisplayDomain, -30.06...30.06)
    }

    @MainActor
    func testAxisPresentationDescriptorBuildsSharedXAxisLabelsAndYGridValues() {
        let config = ChartConfig.default
        let pointInfos = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 10]
            ).axisPointInfo(index: 0),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [.saving: 20]
            ).axisPointInfo(index: 1)
        ]
        let xLabels = CombinedChartView.Renderer.makeXAxisLabelDescriptors(
            pointInfos: pointInfos,
            config: config)
        let descriptor = CombinedChartView.AxisPresentationDescriptor(
            xLabels: xLabels,
            xDomain: -0.5...1.5,
            yGridValues: [-10, 0, 10])
        let plotFrame = CombinedChartView.PlotFrameDescriptor(
            plotRect: CGRect(x: 0, y: 0, width: 180, height: 240),
            yAxisTickPositions: [-10: 220, 0: 120, 10: 20])

        XCTAssertEqual(xLabels.map(\.text), ["Jan", "Feb"])
        XCTAssertEqual(xLabels.map(\.xValue), [0, 1])
        XCTAssertEqual(descriptor.xLabel(forXValue: -1)?.text, "Jan")
        XCTAssertEqual(descriptor.xLabel(forXValue: 0.51)?.text, "Feb")
        XCTAssertEqual(descriptor.xLabel(forXValue: 99)?.text, "Feb")
        XCTAssertEqual(descriptor.yGridPositions(in: plotFrame), [220, 120, 20])
    }

    @MainActor
    func testMarksPresentationDescriptorBuildsSharedBarZeroLineAndSelectedPointMark() {
        let base = ChartConfig.default
        let config = ChartConfig(
            visibleValueCount: 2,
            chartHeight: 320,
            rendering: base.rendering,
            bar: base.bar,
            line: base.line,
            axis: base.axis,
            pager: base.pager,
            debug: base.debug)
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 10]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [.saving: 20])
        ]
        let dragState = CombinedChartView.DragState(
            contentOffsetX: 0,
            startIndex: 0,
            visibleValueCount: 2,
            maxStartIndex: 0,
            dragScrollMode: .free)
        let layoutMetrics = CombinedChartView.LayoutMetrics(
            availableWidth: 240,
            axisWidth: 40,
            visibleValueCount: 2,
            dataCount: data.count,
            dragState: dragState,
            dragTranslationX: 0,
            settlingOffsetX: 0,
            maxStartIndex: 0)
        let viewport = CombinedChartView.ViewportDescriptor(
            dataCount: data.count,
            visibleValueCount: 2,
            startIndex: 0,
            contentOffsetX: 0,
            visibleStartThreshold: 2.0 / 3.0,
            layoutMetrics: layoutMetrics)
        let context = CombinedChartView.RenderContext(
            selectedTab: .totalTrend,
            visibleData: data,
            yAxisTickValues: [-10, 0, 10, 20],
            yAxisDisplayDomain: -10...20,
            plotAreaHeight: 200,
            viewport: viewport,
            config: config,
            showDebugOverlay: false,
            selectionOverlay: nil,
            visibleSelection: .init(index: 1, pointID: data[1].id))
        let marksContext = CombinedChartView.Renderer.makeMarksRenderContext(context: context)
        let barItems = CombinedChartView.Renderer.makeBarMarkItems(
            visibleData: data,
            marksContext: marksContext,
            useTrendBarColor: CombinedChartView.Renderer.resolveUsesTrendBarColor(for: marksContext))

        let descriptor = CombinedChartView.Renderer.makeMarksPresentationContext(
            context: context,
            marksContext: marksContext,
            barMarkItems: barItems)

        XCTAssertEqual(descriptor.barMarks.count, barItems.count)
        XCTAssertEqual(
            descriptor.fallbackBarWidth,
            CombinedChartView.Renderer.resolveBarWidth(
                preferredBarWidth: config.bar.barWidth,
                unitWidth: viewport.unitWidth))
        XCTAssertEqual(descriptor.ruleMarks.first?.value, 0)
        XCTAssertEqual(descriptor.ruleMarks.first?.lineWidth, config.axis.zeroLineWidth)
        XCTAssertEqual(descriptor.pointMarks.first?.index, 1)
        XCTAssertEqual(descriptor.pointMarks.first?.xValue, 1)
        XCTAssertEqual(descriptor.pointMarks.first?.value, 20)
        XCTAssertEqual(descriptor.pointMarks.first?.pointSize, config.line.selection.pointSize)
        XCTAssertEqual(descriptor.pointMarks.first?.symbolSize, pow(config.line.selection.pointSize, 2))
        XCTAssertEqual(descriptor.trendLineStyle?.width, config.line.lineWidth)
    }

    @MainActor
    func testMarksPresentationDescriptorRespectsBreakdownPresentationMode() {
        let config = ChartConfig.default
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 10, .investment: 5])
        ]
        let dragState = CombinedChartView.DragState(
            contentOffsetX: 0,
            startIndex: 0,
            visibleValueCount: 1,
            maxStartIndex: 0,
            dragScrollMode: .free)
        let layoutMetrics = CombinedChartView.LayoutMetrics(
            availableWidth: 240,
            axisWidth: 40,
            visibleValueCount: 1,
            dataCount: data.count,
            dragState: dragState,
            dragTranslationX: 0,
            settlingOffsetX: 0,
            maxStartIndex: 0)
        let viewport = CombinedChartView.ViewportDescriptor(
            dataCount: data.count,
            visibleValueCount: 1,
            startIndex: 0,
            contentOffsetX: 0,
            visibleStartThreshold: 2.0 / 3.0,
            layoutMetrics: layoutMetrics)
        let context = CombinedChartView.RenderContext(
            selectedTab: .breakdown,
            visibleData: data,
            yAxisTickValues: [0, 10, 20],
            yAxisDisplayDomain: 0...20,
            plotAreaHeight: 200,
            viewport: viewport,
            config: config,
            showDebugOverlay: false,
            selectionOverlay: nil,
            visibleSelection: .init(index: 0, pointID: data[0].id))
        let marksContext = CombinedChartView.Renderer.makeMarksRenderContext(context: context)
        let barItems = CombinedChartView.Renderer.makeBarMarkItems(
            visibleData: data,
            marksContext: marksContext,
            useTrendBarColor: CombinedChartView.Renderer.resolveUsesTrendBarColor(for: marksContext))

        let descriptor = CombinedChartView.Renderer.makeMarksPresentationContext(
            context: context,
            marksContext: marksContext,
            barMarkItems: barItems)

        XCTAssertTrue(descriptor.showsBarMarks)
        XCTAssertNil(descriptor.trendLineStyle)
        XCTAssertTrue(descriptor.pointMarks.isEmpty)
    }

    @MainActor
    func testOverlayPresentationDescriptorBuildsSharedTrendSelectionAndDebugGuides() {
        let base = ChartConfig.default
        let config = ChartConfig(
            visibleValueCount: base.visibleValueCount,
            chartHeight: base.chartHeight,
            rendering: base.rendering,
            bar: base.bar,
            line: base.line,
            axis: base.axis,
            pager: base.pager,
            debug: .init(
                statusFont: base.debug.statusFont,
                statusColor: base.debug.statusColor,
                pointGuideColor: base.debug.pointGuideColor,
                thresholdGuideColor: base.debug.thresholdGuideColor,
                isLoggingEnabled: false))
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 10]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [.saving: 20])
        ]
        let dragState = CombinedChartView.DragState(
            contentOffsetX: 0,
            startIndex: 0,
            visibleValueCount: 2,
            maxStartIndex: 0,
            dragScrollMode: .free)
        let layoutMetrics = CombinedChartView.LayoutMetrics(
            availableWidth: 240,
            axisWidth: 40,
            visibleValueCount: 2,
            dataCount: data.count,
            dragState: dragState,
            dragTranslationX: 0,
            settlingOffsetX: 0,
            maxStartIndex: 0)
        let viewport = CombinedChartView.ViewportDescriptor(
            dataCount: data.count,
            visibleValueCount: 2,
            startIndex: 0,
            contentOffsetX: 0,
            visibleStartThreshold: 2.0 / 3.0,
            layoutMetrics: layoutMetrics)
        let context = CombinedChartView.RenderContext(
            selectedTab: .totalTrend,
            visibleData: data,
            yAxisTickValues: [-10, 0, 10, 20],
            yAxisDisplayDomain: -10...20,
            plotAreaHeight: 200,
            viewport: viewport,
            config: config,
            showDebugOverlay: true,
            selectionOverlay: { _ in AnyView(Text("Custom")) },
            visibleSelection: .init(index: 1, pointID: data[1].id))
        let renderer = CombinedChartView.Renderer(
            context: context,
            onSelectIndex: { _ in },
            onPlotAreaChange: { _ in },
            onYAxisTickPositions: { _ in })
        let xPositions = CombinedChartView.XPositionResolver.descriptors(.init(
            dataCount: data.count,
            xPosition: { index in
                [20 as CGFloat, 60][index]
            }))

        let descriptor = renderer.makeOverlayPresentationDescriptor(
            plotRect: CGRect(x: 0, y: 0, width: 120, height: 240),
            xPositions: xPositions,
            yPosition: { value in
                value == 10 ? 120 : (value == 20 ? 80 : nil)
            })

        XCTAssertEqual(descriptor.lineMarks.count, 1)
        XCTAssertEqual(descriptor.lineMarks.first?.segments.count, 1)
        XCTAssertEqual(
            descriptor.selection.mode,
            CombinedChartView.SelectionPresentationDescriptor.Mode.customOverlay)
        XCTAssertTrue(descriptor.selection.showsCustomOverlay)
        XCTAssertEqual(descriptor.selection.context?.point.id, data[1].id)
        XCTAssertEqual(
            descriptor.guideMarks.first(where: { $0.kind == .point })?.xPositions,
            [20, 60])
        XCTAssertEqual(
            descriptor.guideMarks.first(where: { $0.kind == .threshold })?.xPositions,
            CombinedChartView.DebugGuideResolver.thresholdGuideXPositions(
                unitWidth: viewport.unitWidth,
                visibleStartThreshold: config.pager.visibleStartThreshold,
                xPositions: xPositions))
    }

    @MainActor
    func testSelectionPresentationDescriptorBuildsDefaultLineAndBandHelpers() {
        let base = ChartConfig.default
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 10]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [.saving: 20])
        ]
        let dragState = CombinedChartView.DragState(
            contentOffsetX: 0,
            startIndex: 0,
            visibleValueCount: 2,
            maxStartIndex: 0,
            dragScrollMode: .free)
        let layoutMetrics = CombinedChartView.LayoutMetrics(
            availableWidth: 240,
            axisWidth: 40,
            visibleValueCount: 2,
            dataCount: data.count,
            dragState: dragState,
            dragTranslationX: 0,
            settlingOffsetX: 0,
            maxStartIndex: 0)
        let viewport = CombinedChartView.ViewportDescriptor(
            dataCount: data.count,
            visibleValueCount: 2,
            startIndex: 0,
            contentOffsetX: 0,
            visibleStartThreshold: 2.0 / 3.0,
            layoutMetrics: layoutMetrics)
        let xPositions = CombinedChartView.XPositionResolver.descriptors(.init(
            dataCount: data.count,
            xPosition: { index in
                [20 as CGFloat, 60][index]
            }))

        func makeRenderer(selectedTab: CombinedChartView.Tab) -> CombinedChartView.Renderer {
            let context = CombinedChartView.RenderContext(
                selectedTab: selectedTab,
                visibleData: data,
                yAxisTickValues: [-10, 0, 10, 20],
                yAxisDisplayDomain: -10...20,
                plotAreaHeight: 200,
                viewport: viewport,
                config: base,
                showDebugOverlay: false,
                selectionOverlay: nil,
                visibleSelection: .init(index: 1, pointID: data[1].id))
            return CombinedChartView.Renderer(
                context: context,
                onSelectIndex: { _ in },
                onPlotAreaChange: { _ in },
                onYAxisTickPositions: { _ in })
        }

        let totalTrendSelection = makeRenderer(selectedTab: .totalTrend)
            .makeSelectionPresentationDescriptor(
                plotRect: CGRect(x: 0, y: 0, width: 120, height: 240),
                xPositions: xPositions,
                yPosition: { value in
                    value == 10 ? 120 : (value == 20 ? 80 : nil)
                })

        XCTAssertEqual(totalTrendSelection.mode, .defaultOverlay)
        XCTAssertTrue(totalTrendSelection.showsDefaultOverlay)
        XCTAssertEqual(totalTrendSelection.lineIndicatorX, 60)
        XCTAssertNil(totalTrendSelection.bandIndicatorFrame)
        XCTAssertNotNil(totalTrendSelection.indicatorLineColor)
        XCTAssertNil(totalTrendSelection.indicatorFillColor)

        let breakdownSelection = makeRenderer(selectedTab: .breakdown)
            .makeSelectionPresentationDescriptor(
                plotRect: CGRect(x: 0, y: 0, width: 120, height: 240),
                xPositions: xPositions,
                yPosition: { value in
                    value == 10 ? 120 : (value == 20 ? 80 : nil)
                })

        XCTAssertEqual(breakdownSelection.mode, .defaultOverlay)
        XCTAssertTrue(breakdownSelection.showsDefaultOverlay)
        XCTAssertNil(breakdownSelection.lineIndicatorX)
        XCTAssertEqual(breakdownSelection.bandIndicatorFrame?.midX, 60)
        XCTAssertNil(breakdownSelection.indicatorLineColor)
        XCTAssertNotNil(breakdownSelection.indicatorFillColor)
    }

    @MainActor
    func testSelectionAndTrendLineDescriptorsPreserveScrolledChartsXOffsets() throws {
        let base = ChartConfig.default
        let data = [
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-01",
                xLabel: "Jan",
                values: [.saving: 10]),
            ChartTestBuilders.makeDataPoint(
                groupID: "2024",
                xKey: "2024-02",
                xLabel: "Feb",
                values: [.saving: 20])
        ]
        let dragState = CombinedChartView.DragState(
            contentOffsetX: 120,
            startIndex: 1,
            visibleValueCount: 2,
            maxStartIndex: 2,
            dragScrollMode: .free)
        let layoutMetrics = CombinedChartView.LayoutMetrics(
            availableWidth: 240,
            axisWidth: 40,
            visibleValueCount: 2,
            dataCount: data.count,
            dragState: dragState,
            dragTranslationX: 0,
            settlingOffsetX: 0,
            maxStartIndex: 2)
        let viewport = CombinedChartView.ViewportDescriptor(
            dataCount: data.count,
            visibleValueCount: 2,
            startIndex: 1,
            contentOffsetX: 120,
            visibleStartThreshold: 2.0 / 3.0,
            layoutMetrics: layoutMetrics)
        let plotRect = CGRect(x: -120, y: 0, width: 120, height: 240)
        let xPositions = CombinedChartView.XPositionResolver.descriptors(.init(
            dataCount: data.count,
            xPosition: { index in
                [-100 as CGFloat, -60][index]
            }))

        func makeRenderer(selectedTab: CombinedChartView.Tab) -> CombinedChartView.Renderer {
            let context = CombinedChartView.RenderContext(
                selectedTab: selectedTab,
                visibleData: data,
                yAxisTickValues: [-10, 0, 10, 20],
                yAxisDisplayDomain: -10...20,
                plotAreaHeight: 200,
                viewport: viewport,
                config: base,
                showDebugOverlay: false,
                selectionOverlay: nil,
                visibleSelection: .init(index: 1, pointID: data[1].id))
            return CombinedChartView.Renderer(
                context: context,
                onSelectIndex: { _ in },
                onPlotAreaChange: { _ in },
                onYAxisTickPositions: { _ in })
        }

        let totalTrendRenderer = makeRenderer(selectedTab: .totalTrend)
        let totalTrendSelection = totalTrendRenderer.makeSelectionPresentationDescriptor(
            plotRect: plotRect,
            xPositions: xPositions,
            yPosition: { value in
                value == 10 ? 120 : (value == 20 ? 80 : nil)
            })
        XCTAssertEqual(totalTrendSelection.lineIndicatorX, -60)

        let breakdownRenderer = makeRenderer(selectedTab: .breakdown)
        let breakdownSelection = breakdownRenderer.makeSelectionPresentationDescriptor(
            plotRect: plotRect,
            xPositions: xPositions,
            yPosition: { value in
                value == 10 ? 120 : (value == 20 ? 80 : nil)
            })
        XCTAssertEqual(breakdownSelection.bandIndicatorFrame?.midX, -60)

        let overlayDescriptor = totalTrendRenderer.makeOverlayPresentationDescriptor(
            plotRect: plotRect,
            xPositions: xPositions,
            yPosition: { value in
                value == 10 ? 120 : (value == 20 ? 80 : nil)
            })

        let lineBounds = try XCTUnwrap(overlayDescriptor.lineMarks.first?.segments.first?.path.boundingRect)
        XCTAssertEqual(lineBounds.minX, -100, accuracy: 0.001)
        XCTAssertEqual(lineBounds.maxX, -60, accuracy: 0.001)
    }

    @MainActor
    func testPublicContextsExposeStableInitializers() {
        let config = ChartConfig.default
        let point = CombinedChartView.Point(
            id: .init(groupID: "2024", xKey: "2024-01"),
            xKey: "2024-01",
            xLabel: "Jan",
            values: [.saving: 12])

        let selection = CombinedChartView.Selection(point: point, index: 0)
        let overlay = CombinedChartView.SelectionOverlay(
            point: point,
            value: 12,
            plotFrame: CGRect(x: 0, y: 0, width: 120, height: 240),
            indicatorFrame: CGRect(x: 20, y: 10, width: 24, height: 200),
            indicatorStyle: .line)
        let entry = CombinedChartView.PagerItem(
            id: "2024",
            displayTitle: "2024",
            startIndex: 0)
        let pager = CombinedChartView.PagerContext(
            config: config,
            entries: [entry],
            highlightedEntry: entry,
            canSelectPreviousPage: false,
            canSelectNextPage: true,
            onSelectPreviousPage: {},
            onSelectEntry: { _ in },
            onSelectNextPage: {})

        XCTAssertEqual(selection.point.id, point.id)
        XCTAssertEqual(selection.index, 0)
        XCTAssertEqual(overlay.point.id, point.id)
        XCTAssertEqual(overlay.indicatorStyle, .line)
        XCTAssertEqual(pager.entries, [entry])
        XCTAssertEqual(pager.highlightedEntry, entry)
        XCTAssertFalse(pager.canSelectPreviousPage)
        XCTAssertTrue(pager.canSelectNextPage)
    }

    @MainActor
    func testPublicAPIPrefersGenericNames() {
        let base = ChartConfig.default
        let config = ChartConfig(
            visibleValueCount: 6,
            chartHeight: 320,
            rendering: base.rendering,
            bar: base.bar,
            line: base.line,
            axis: base.axis,
            pager: .init(
                scrollTargetBehavior: .free,
                scrollEngine: .automatic,
                visibleStartThreshold: 0.5),
            debug: base.debug)
        let entry = CombinedChartView.PagerItem(
            id: "2024",
            displayTitle: "2024",
            startIndex: 2)
        let debugState = CombinedChartView.DebugState(
            selectedTabTitle: "Total Trend",
            scrollEngineTitle: "Charts",
            scrollTargetBehaviorTitle: "Free",
            isDragging: false,
            isDecelerating: false,
            startIndex: 0,
            visibleStartIndex: 0,
            visibleStartLabel: "Jan",
            visibleStartThreshold: 0.5,
            contentOffsetX: 0,
            dragTranslationX: 0,
            targetContentOffsetX: 0,
            targetIndex: 3,
            viewportWidth: 120,
            unitWidth: 30,
            chartWidth: 240,
            selectedPointIndex: nil,
            selectedPointGroupID: nil,
            selectedPointXKey: nil,
            selectedPointXLabel: nil,
            selectedPointValue: nil)

        XCTAssertEqual(config.visibleValueCount, 6)
        XCTAssertEqual(config.pager.scrollTargetBehavior, .free)
        XCTAssertEqual(config.pager.scrollEngine, .automatic)
        XCTAssertEqual(entry.startIndex, 2)
        XCTAssertEqual(debugState.scrollEngineTitle, "Charts")
        XCTAssertEqual(debugState.scrollTargetBehaviorTitle, "Free")
        XCTAssertEqual(debugState.targetIndex, 3)
    }

    @available(*, deprecated)
    @MainActor
    func testLegacyPublicAliasesRemainAvailable() {
        let base = ChartConfig.default
        let config = ChartConfig(
            visibleValueCount: 6,
            chartHeight: 320,
            rendering: base.rendering,
            bar: base.bar,
            line: base.line,
            axis: base.axis,
            pager: .init(
                scrollTargetBehavior: .free,
                scrollEngine: .automatic,
                visibleStartThreshold: 0.5),
            debug: base.debug)
        let entry = CombinedChartView.PagerItem(
            id: "2024",
            displayTitle: "2024",
            startIndex: 2)
        let debugState = CombinedChartView.DebugState(
            selectedTabTitle: "Total Trend",
            scrollEngineTitle: "Charts",
            scrollTargetBehaviorTitle: "Free",
            isDragging: false,
            isDecelerating: false,
            startIndex: 0,
            visibleStartIndex: 0,
            visibleStartLabel: "Jan",
            visibleStartThreshold: 0.5,
            contentOffsetX: 0,
            dragTranslationX: 0,
            targetContentOffsetX: 0,
            targetIndex: 3,
            viewportWidth: 120,
            unitWidth: 30,
            chartWidth: 240,
            selectedPointIndex: nil,
            selectedPointGroupID: nil,
            selectedPointXKey: nil,
            selectedPointXLabel: nil,
            selectedPointValue: nil)

        XCTAssertEqual(config.monthsPerPage, 6)
        XCTAssertEqual(config.pager.dragScrollMode, .free)
        XCTAssertEqual(config.pager.scrollImplementation, .automatic)
        XCTAssertEqual(entry.startMonthIndex, 2)
        XCTAssertEqual(debugState.scrollImplementationTitle, "Charts")
        XCTAssertEqual(debugState.dragScrollModeTitle, "Free")
        XCTAssertEqual(debugState.targetMonthIndex, 3)
    }

    @MainActor
    func testSlotsInitializerSupportsEmptyStateOnlyCustomization() {
        let slots = CombinedChartView.Slots {
            Text("No chart data")
        }

        XCTAssertNil(slots.selectionOverlay)
        XCTAssertNil(slots.pager)

        let groups = [
            CombinedChartView.DataGroup(
                id: "2024",
                displayTitle: "2024",
                groupOrder: 0,
                points: [
                    .init(
                        id: .init(groupID: "2024", xKey: "2024-01"),
                        xKey: "2024-01",
                        xLabel: "Jan",
                        values: [.saving: 1])
                ])
        ]
        let view = CombinedChartView(groups: groups, slots: slots)

        XCTAssertNotNil(view)
    }
}
