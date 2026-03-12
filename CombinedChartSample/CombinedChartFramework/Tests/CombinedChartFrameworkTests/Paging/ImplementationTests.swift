@testable import CombinedChartFramework
import XCTest

final class ImplementationTests: XCTestCase {
    @MainActor
    func testAutomaticConfigurationPrefersChartsOnSupportedPlatforms() {
        let config = ChartConfig.default

        if #available(iOS 17, macOS 14, *) {
            XCTAssertEqual(CombinedChartView.Implementation.resolve(config: config), .charts)
        } else {
            XCTAssertEqual(CombinedChartView.Implementation.resolve(config: config), .canvas)
        }
    }

    @MainActor
    func testCanvasRenderingFollowsRequestedLegacyScrollImplementation() {
        let swiftUIConfig = ChartConfig(
            visibleValueCount: 4,
            chartHeight: 420,
            rendering: .init(engine: .canvas),
            bar: ChartConfig.default.bar,
            line: ChartConfig.default.line,
            axis: ChartConfig.default.axis,
            pager: .init(scrollEngine: .swiftUIGesture))

        XCTAssertEqual(CombinedChartView.Implementation.resolve(config: swiftUIConfig), .canvas)

        let uiKitConfig = ChartConfig(
            visibleValueCount: 4,
            chartHeight: 420,
            rendering: .init(engine: .canvas),
            bar: ChartConfig.default.bar,
            line: ChartConfig.default.line,
            axis: ChartConfig.default.axis,
            pager: .init(scrollEngine: .uiKitScrollView))

        #if canImport(UIKit)
        XCTAssertEqual(CombinedChartView.Implementation.resolve(config: uiKitConfig), .uiKit)
        #else
        XCTAssertEqual(CombinedChartView.Implementation.resolve(config: uiKitConfig), .canvas)
        #endif
    }

    @MainActor
    func testAutomaticRenderingCanStillBeForcedIntoLegacyCanvasPath() {
        let config = ChartConfig(
            visibleValueCount: 4,
            chartHeight: 420,
            rendering: .init(engine: .automatic),
            bar: ChartConfig.default.bar,
            line: ChartConfig.default.line,
            axis: ChartConfig.default.axis,
            pager: .init(scrollEngine: .swiftUIGesture))

        XCTAssertEqual(CombinedChartView.Implementation.resolve(config: config), .canvas)
    }
}
