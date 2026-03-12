@testable import CombinedChartFramework
import XCTest

final class ChartRenderingLayoutTests: XCTestCase {
    func testPlotAreaHeightSubtractsTopInsetAndXAxisHeight() {
        let layout = CombinedChartView.RenderingLayout(
            rendering: .init(
                engine: .canvas,
                topInset: 12,
                xAxisHeight: 28))

        XCTAssertEqual(layout.contentHeight(for: 420), 408)
        XCTAssertEqual(layout.plotAreaHeight(for: 420), 380)
    }

    func testPlotAreaHeightClampsAtZero() {
        let layout = CombinedChartView.RenderingLayout(
            rendering: .init(
                engine: .canvas,
                topInset: 20,
                xAxisHeight: 40))

        XCTAssertEqual(layout.contentHeight(for: 10), 0)
        XCTAssertEqual(layout.plotAreaHeight(for: 10), 0)
        XCTAssertEqual(layout.plotAreaHeight(for: 50), 0)
    }

    func testCanvasTickPositionsMapDomainEdgesToPlotEdges() {
        let layout = CombinedChartView.RenderingLayout(
            rendering: .init(
                engine: .canvas,
                topInset: 12,
                xAxisHeight: 28))

        let positions = layout.canvasTickPositions(
            yAxisTickValues: [-100, 0, 100],
            yAxisDisplayDomain: -100...100,
            plotAreaHeight: 300)

        XCTAssertEqual(positions[-100] ?? -1, 300, accuracy: 0.001)
        XCTAssertEqual(positions[0] ?? -1, 150, accuracy: 0.001)
        XCTAssertEqual(positions[100] ?? -1, 0, accuracy: 0.001)
    }
}
