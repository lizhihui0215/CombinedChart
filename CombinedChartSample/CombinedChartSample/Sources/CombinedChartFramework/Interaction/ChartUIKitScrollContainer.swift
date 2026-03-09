import SwiftUI
import UIKit

struct ChartUIKitScrollContainer<Content: View>: UIViewRepresentable {
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
        var parent: ChartUIKitScrollContainer
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
