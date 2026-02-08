#if canImport(SwiftUI)
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
struct MetalDashboardPreview: PreviewProvider {
    static var previews: some View {
        MetalDashboardView(viewModel: MetalDashboardViewModel())
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

#endif
