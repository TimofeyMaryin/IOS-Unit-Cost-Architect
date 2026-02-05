import SwiftUI

/// Chart legend item component
struct ChartLegendItem: View {
    let itemColor: Color
    let itemLabel: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(itemColor)
                .frame(width: 8, height: 8)
            Text(itemLabel)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HStack {
        ChartLegendItem(itemColor: .blue, itemLabel: "Materials")
        ChartLegendItem(itemColor: .orange, itemLabel: "Labor")
        ChartLegendItem(itemColor: .green, itemLabel: "Profit")
    }
}
