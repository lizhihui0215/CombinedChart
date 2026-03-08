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
                .foregroundStyle(context.canSelectPreviousPage ? .primary : .secondary)
                .disabled(!context.canSelectPreviousPage)

                Spacer()

                Text(highlightedEntryTitle ?? "")
                    .font(.callout.weight(.semibold))

                Spacer()

                Button(action: context.onSelectNextPage) {
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(context.canSelectNextPage ? .primary : .secondary)
                .disabled(!context.canSelectNextPage)
            }
            .padding(.horizontal, 8)
        }
    }
}
