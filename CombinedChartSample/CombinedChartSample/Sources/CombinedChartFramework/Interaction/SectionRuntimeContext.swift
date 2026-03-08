import SwiftUI

extension CombinedChartView {
    struct SectionRuntimeContext {
        let pagingContext: PagingContext
        let dragPagingState: DragViewportState
        let layoutMetrics: ChartLayoutMetrics
        let renderContext: ChartRenderContext
    }
}
