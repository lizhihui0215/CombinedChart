import SwiftUI

extension CombinedChartView {
    struct CombinedChartPager: View {
        let context: PagerContext

        private var highlightedEntryTitle: String? {
            context.highlightedEntry?.displayTitle
        }

        var body: some View {
            HStack(spacing: 12) {
                Button(action: context.onSelectPreviousPage) {
                    Image(systemName: "chevron.left")
                }
                .foregroundStyle(
                    context.canSelectPreviousPage
                        ? context.config.pager.activeControlColor
                        : context.config.pager.inactiveControlColor)
                .disabled(!context.canSelectPreviousPage)

                Spacer()

                Text(highlightedEntryTitle ?? "")
                    .font(context.config.pager.titleFont)
                    .foregroundStyle(context.config.pager.titleColor)

                Spacer()

                Button(action: context.onSelectNextPage) {
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(
                    context.canSelectNextPage
                        ? context.config.pager.activeControlColor
                        : context.config.pager.inactiveControlColor)
                .disabled(!context.canSelectNextPage)
            }
            .padding(.horizontal, 8)
        }
    }
}
