import SwiftUI
import SwiftData
import Charts

/// Product comparison view - compare up to 3 products side by side
struct ComparisonView: View {
    @Query(sort: \Product.name) private var products: [Product]
    @Query private var laborSettings: [Labor]
    
    @State private var selectedProducts: [Product] = []
    @State private var showingProductPicker = false
    
    private var hourlyRate: Double {
        laborSettings.first?.hourlyRate ?? 15.0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product selector
                productSelector
                
                if selectedProducts.count >= 2 {
                    // Comparison chart
                    comparisonChart
                    
                    // Detailed comparison table
                    comparisonTable
                    
                    // Winner summary
                    winnerSummary
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Compare Products")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingProductPicker) {
            ProductPickerView(
                products: products,
                selectedProducts: $selectedProducts,
                maxSelection: 3
            )
        }
    }
    
    // MARK: - Product Selector
    private var productSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Products")
                    .font(.headline)
                Spacer()
                Text("\(selectedProducts.count)/3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    if index < selectedProducts.count {
                        // Selected product card
                        SelectedProductCard(
                            product: selectedProducts[index],
                            color: productColor(index: index)
                        ) {
                            selectedProducts.remove(at: index)
                        }
                    } else {
                        // Empty slot
                        Button {
                            showingProductPicker = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.dashed")
                                    .font(.title)
                                Text("Add")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if selectedProducts.count < 2 {
                Text("Select at least 2 products to compare")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func productColor(index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .orange
        case 2: return .purple
        default: return .gray
        }
    }
    
    // MARK: - Comparison Chart
    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Comparison")
                .font(.headline)
            
            Chart {
                ForEach(Array(selectedProducts.enumerated()), id: \.element.id) { index, product in
                    BarMark(
                        x: .value("Metric", "Prime Cost"),
                        y: .value("Value", product.primeCost(hourlyRate: hourlyRate))
                    )
                    .foregroundStyle(productColor(index: index))
                    .position(by: .value("Product", product.name))
                    
                    BarMark(
                        x: .value("Metric", "Total Cost"),
                        y: .value("Value", product.totalCost(hourlyRate: hourlyRate))
                    )
                    .foregroundStyle(productColor(index: index))
                    .position(by: .value("Product", product.name))
                    
                    BarMark(
                        x: .value("Metric", "Final Price"),
                        y: .value("Value", product.finalPrice(hourlyRate: hourlyRate))
                    )
                    .foregroundStyle(productColor(index: index))
                    .position(by: .value("Product", product.name))
                    
                    BarMark(
                        x: .value("Metric", "Profit"),
                        y: .value("Value", product.netProfit(hourlyRate: hourlyRate))
                    )
                    .foregroundStyle(productColor(index: index))
                    .position(by: .value("Product", product.name))
                }
            }
            .frame(height: 250)
            
            // Legend
            HStack(spacing: 16) {
                ForEach(Array(selectedProducts.enumerated()), id: \.element.id) { index, product in
                    ChartLegendItem(itemColor: productColor(index: index), itemLabel: product.name)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Comparison Table
    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Comparison")
                .font(.headline)
            
            VStack(spacing: 1) {
                // Header row
                HStack {
                    Text("Metric")
                        .frame(width: 100, alignment: .leading)
                    
                    ForEach(Array(selectedProducts.enumerated()), id: \.element.id) { index, product in
                        Text(product.name)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(productColor(index: index))
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemGroupedBackground))
                
                // Data rows
                ComparisonRow(label: "Material Cost", values: selectedProducts.map { $0.materialCost })
                ComparisonRow(label: "Labor Cost", values: selectedProducts.map { $0.laborCost(hourlyRate: hourlyRate) })
                ComparisonRow(label: "Prime Cost", values: selectedProducts.map { $0.primeCost(hourlyRate: hourlyRate) })
                ComparisonRow(label: "Overhead %", values: selectedProducts.map { $0.overheadPercentage }, isPercent: true)
                ComparisonRow(label: "Total Cost", values: selectedProducts.map { $0.totalCost(hourlyRate: hourlyRate) })
                ComparisonRow(label: "Markup %", values: selectedProducts.map { $0.markupPercentage }, isPercent: true)
                ComparisonRow(label: "Final Price", values: selectedProducts.map { $0.finalPrice(hourlyRate: hourlyRate) }, highlight: true)
                ComparisonRow(label: "Net Profit", values: selectedProducts.map { $0.netProfit(hourlyRate: hourlyRate) }, highlight: true)
                ComparisonRow(label: "Margin %", values: selectedProducts.map { $0.profitMargin(hourlyRate: hourlyRate) }, isPercent: true, highlight: true)
                ComparisonRow(label: "Prod. Time", values: selectedProducts.map { $0.timeToProduce }, suffix: "hr")
                ComparisonRow(label: "Ingredients", values: selectedProducts.map { Double($0.ingredientCount) }, isInt: true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Winner Summary
    private var winnerSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis")
                .font(.headline)
            
            VStack(spacing: 8) {
                WinnerRow(
                    title: "Lowest Cost",
                    winner: lowestCostProduct,
                    color: productColorForProduct(lowestCostProduct)
                )
                
                WinnerRow(
                    title: "Highest Profit",
                    winner: highestProfitProduct,
                    color: productColorForProduct(highestProfitProduct)
                )
                
                WinnerRow(
                    title: "Best Margin",
                    winner: bestMarginProduct,
                    color: productColorForProduct(bestMarginProduct)
                )
                
                WinnerRow(
                    title: "Fastest to Produce",
                    winner: fastestProduct,
                    color: productColorForProduct(fastestProduct)
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var lowestCostProduct: Product? {
        selectedProducts.min { $0.totalCost(hourlyRate: hourlyRate) < $1.totalCost(hourlyRate: hourlyRate) }
    }
    
    private var highestProfitProduct: Product? {
        selectedProducts.max { $0.netProfit(hourlyRate: hourlyRate) < $1.netProfit(hourlyRate: hourlyRate) }
    }
    
    private var bestMarginProduct: Product? {
        selectedProducts.max { $0.profitMargin(hourlyRate: hourlyRate) < $1.profitMargin(hourlyRate: hourlyRate) }
    }
    
    private var fastestProduct: Product? {
        selectedProducts.min { $0.timeToProduce < $1.timeToProduce }
    }
    
    private func productColorForProduct(_ product: Product?) -> Color {
        guard let product = product,
              let index = selectedProducts.firstIndex(where: { $0.id == product.id }) else {
            return .gray
        }
        return productColor(index: index)
    }
}

// MARK: - Supporting Views
struct SelectedProductCard: View {
    let product: Product
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            Image(systemName: product.iconName)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(product.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ComparisonRow: View {
    let label: String
    let values: [Double]
    var isPercent: Bool = false
    var isInt: Bool = false
    var suffix: String = ""
    var highlight: Bool = false
    
    private var minIndex: Int? {
        values.enumerated().min(by: { $0.element < $1.element })?.offset
    }
    
    private var maxIndex: Int? {
        values.enumerated().max(by: { $0.element < $1.element })?.offset
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                HStack(spacing: 2) {
                    if isPercent {
                        Text(String(format: "%.1f%%", value))
                    } else if isInt {
                        Text("\(Int(value))")
                    } else {
                        Text(value, format: .currency(code: "USD"))
                    }
                    
                    if !suffix.isEmpty {
                        Text(suffix)
                    }
                }
                .font(.caption)
                .fontWeight(highlight ? .semibold : .regular)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(highlight ? Color.green.opacity(0.05) : Color(.systemBackground))
    }
}

struct WinnerRow: View {
    let title: String
    let winner: Product?
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if let winner = winner {
                HStack(spacing: 8) {
                    Image(systemName: winner.iconName)
                        .foregroundStyle(color)
                    Text(winner.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Product Picker
struct ProductPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let products: [Product]
    @Binding var selectedProducts: [Product]
    let maxSelection: Int
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(products) { product in
                    Button {
                        toggleSelection(product)
                    } label: {
                        HStack {
                            Image(systemName: product.iconName)
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(product.name)
                                    .foregroundStyle(.primary)
                                Text("\(product.ingredientCount) ingredients")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedProducts.contains(where: { $0.id == product.id }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .disabled(selectedProducts.count >= maxSelection && !selectedProducts.contains(where: { $0.id == product.id }))
                }
            }
            .navigationTitle("Select Products")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleSelection(_ product: Product) {
        if let index = selectedProducts.firstIndex(where: { $0.id == product.id }) {
            selectedProducts.remove(at: index)
        } else if selectedProducts.count < maxSelection {
            selectedProducts.append(product)
        }
    }
}

#Preview {
    NavigationStack {
        ComparisonView()
    }
    .modelContainer(for: [Product.self, Labor.self], inMemory: true)
}
