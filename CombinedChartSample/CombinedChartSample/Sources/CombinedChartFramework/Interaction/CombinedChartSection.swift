import SwiftUI
import UIKit

extension CombinedChartView {
    struct CombinedChartSection: View {
        let context: ChartSectionContext
        let visibleSelection: VisibleSelection?
        @Binding var viewportState: ViewportState
        @Binding var layoutState: LayoutState
        @Binding var plotSyncState: PlotSyncState
        let onDispatchAction: (ViewAction) -> Void
        @State private var isDraggingScroll = false

        var body: some View {
            GeometryReader { geometry in
                let scrollState = makeScrollState(for: geometry)

                HStack(alignment: .top, spacing: 0) {
                    HStack(alignment: .top, spacing: 8) {
                        ChartYAxisLabels(
                            context: context.makeYAxisLabelsContext(
                                plotSyncState: plotSyncState))

                        if let plotAreaMinY = plotSyncState.plotAreaMinY, plotSyncState.plotAreaHeight > 0 {
                            Rectangle()
                                .fill(.black)
                                .frame(width: 1, height: plotSyncState.plotAreaHeight)
                                .offset(y: plotAreaMinY)
                        }
                    }

                    HorizontalChartScrollView(
                        viewportWidth: scrollState.layoutMetrics.viewportWidth,
                        chartWidth: scrollState.layoutMetrics.chartWidth,
                        contentOffsetX: viewportState.contentOffsetX,
                        onContentOffsetChange: { viewportState.contentOffsetX = $0 },
                        onDraggingChange: { isDraggingScroll = $0 },
                        onWillEndDragging: { proposedOffsetX in
                            let settleContext = scrollState.makeDragSettleContext(
                                for: proposedOffsetX)
                            onDispatchAction(.settleDrag(settleContext))
                            return settleContext.targetContentOffsetX
                        },
                        content: ChartRenderer(
                            context: scrollState.renderContext,
                            onSelectIndex: { onDispatchAction(.selectPoint(index: $0)) },
                            onPlotAreaChange: { plotRect in
                                syncPlotArea(plotRect, isDragging: isDraggingScroll)
                            },
                            onYAxisTickPositions: { positions in
                                syncYAxisTickPositions(positions, isDragging: isDraggingScroll)
                            }))
                            .frame(width: scrollState.layoutMetrics.viewportWidth)
                            .frame(maxHeight: .infinity)
                            .clipped()
                }
                .onAppear {
                    syncViewport(scrollState: scrollState)
                }
                .onChange(of: geometry.size) { _ in
                    syncViewport(scrollState: scrollState)
                }
            }
        }
    }
}

private extension CombinedChartView.CombinedChartSection {
    // MARK: - Scroll State

    func makeScrollState(for geometry: GeometryProxy) -> CombinedChartView.ChartScrollState {
        .init(
            context: context,
            viewportState: viewportState,
            plotAreaHeight: plotSyncState.plotAreaHeight,
            visibleSelection: visibleSelection,
            availableWidth: geometry.size.width,
            dragTranslationX: 0,
            settlingOffsetX: 0)
    }

    // MARK: - Sync

    func syncPlotArea(_ plotRect: CGRect, isDragging: Bool) {
        guard !isDragging else { return }
        plotSyncState.updatePlotArea(with: plotRect)
    }

    func syncYAxisTickPositions(_ positions: [Double: CGFloat], isDragging: Bool) {
        guard !isDragging else { return }
        plotSyncState.updateYAxisTickPositions(positions)
    }

    func syncViewport(scrollState: CombinedChartView.ChartScrollState) {
        scrollState.syncViewport(
            layoutState: &_layoutState.wrappedValue,
            viewportState: &viewportState)
    }
}

private struct HorizontalChartScrollView<Content: View>: UIViewRepresentable {
    let viewportWidth: CGFloat
    let chartWidth: CGFloat
    let contentOffsetX: CGFloat
    let onContentOffsetChange: (CGFloat) -> Void
    let onDraggingChange: (Bool) -> Void
    let onWillEndDragging: (CGFloat) -> CGFloat
    let content: Content

    func makeCoordinator() -> Coordinator {
        Coordinator(rootView: content)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isScrollEnabled = true
        scrollView.isDirectionalLockEnabled = true
        scrollView.bounces = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never

        let hostedView = context.coordinator.hostingController.view!
        hostedView.backgroundColor = .clear
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostedView)

        let widthConstraint = hostedView.widthAnchor.constraint(equalToConstant: chartWidth)
        context.coordinator.hostedWidthConstraint = widthConstraint

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            widthConstraint
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.hostingController.rootView = content
        context.coordinator.hostedWidthConstraint?.constant = max(chartWidth, viewportWidth)
        scrollView.alwaysBounceHorizontal = chartWidth > viewportWidth
        scrollView.layoutIfNeeded()

        guard !context.coordinator.isDragging else { return }
        if abs(scrollView.contentOffset.x - contentOffsetX) > 0.5 {
            scrollView.setContentOffset(CGPoint(x: contentOffsetX, y: 0), animated: false)
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: HorizontalChartScrollView
        let hostingController: UIHostingController<Content>
        var isDragging = false
        var hostedWidthConstraint: NSLayoutConstraint?

        init(rootView: Content) {
            parent = .init(
                viewportWidth: 0,
                chartWidth: 0,
                contentOffsetX: 0,
                onContentOffsetChange: { _ in },
                onDraggingChange: { _ in },
                onWillEndDragging: { $0 },
                content: rootView)
            hostingController = UIHostingController(rootView: rootView)
            hostingController.view.clipsToBounds = true
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.onContentOffsetChange(scrollView.contentOffset.x)
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isDragging = true
            parent.onDraggingChange(true)
        }

        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            let targetOffsetX = parent.onWillEndDragging(targetContentOffset.pointee.x)
            targetContentOffset.pointee.x = targetOffsetX
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                isDragging = false
                parent.onDraggingChange(false)
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isDragging = false
            parent.onDraggingChange(false)
        }
    }
}
