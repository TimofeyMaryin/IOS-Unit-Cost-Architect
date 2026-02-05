import SwiftUI
import SwiftData

/// Batch production calculator for calculating costs at different quantities
struct BatchCalculatorView: View {
    @Query private var laborSettings: [Labor]
    
    let product: Product
    
    @State private var customQuantity: Int = 100
    @State private var selectedPreset: Int? = nil
    
    private let presetQuantities = [1, 10, 50, 100, 500, 1000]
    
    private var hourlyRate: Double {
        laborSettings.first?.hourlyRate ?? 15.0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product header
                productHeader
                
                // Quantity selector
                quantitySelector
                
                // Calculations grid
                calculationsGrid
                
                // Comparison table
                comparisonTable
                
                // Insights
                insightsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Batch Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Product Header
    private var productHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: product.iconName)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                Text("Unit Cost: \(product.totalCost(hourlyRate: hourlyRate), format: .currency(code: "USD"))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Quantity Selector
    private var quantitySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Batch Size")
                .font(.headline)
            
            // Preset buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presetQuantities, id: \.self) { qty in
                        Button {
                            selectedPreset = qty
                            customQuantity = qty
                        } label: {
                            Text("\(qty)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedPreset == qty ? Color.blue : Color(.tertiarySystemGroupedBackground))
                                .foregroundStyle(selectedPreset == qty ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Custom quantity
            HStack {
                Text("Custom:")
                    .foregroundStyle(.secondary)
                
                TextField("Quantity", value: $customQuantity, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onChange(of: customQuantity) { _, _ in
                        selectedPreset = nil
                    }
                
                Text("units")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Calculations Grid
    private var calculationsGrid: some View {
        let calc = product.batchCost(quantity: max(1, customQuantity), hourlyRate: hourlyRate)
        
        return VStack(spacing: 16) {
            HStack(spacing: 16) {
                BatchMetricCard(
                    title: "Total Cost",
                    value: calc.batchTotalCost,
                    isCurrency: true,
                    color: .orange
                )
                
                BatchMetricCard(
                    title: "Total Revenue",
                    value: calc.batchFinalPrice,
                    isCurrency: true,
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                BatchMetricCard(
                    title: "Total Profit",
                    value: calc.batchProfit,
                    isCurrency: true,
                    color: .blue
                )
                
                BatchMetricCard(
                    title: "Production Time",
                    value: 0,
                    isCurrency: false,
                    color: .purple,
                    customText: calc.formattedProductionTime
                )
            }
            
            // Scale discount banner
            if calc.scaleDiscount > 0 {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(.green)
                    
                    Text("Volume discount: \(Int(calc.scaleDiscount * 100))% savings on materials!")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    
                    Spacer()
                    
                    Text("-\(calc.savingsPerUnit * Double(customQuantity), format: .currency(code: "USD"))")
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Comparison Table
    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quantity Comparison")
                .font(.headline)
            
            VStack(spacing: 1) {
                // Header
                HStack {
                    Text("Qty")
                        .frame(width: 50, alignment: .leading)
                    Text("Unit Cost")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("Total")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("Profit")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemGroupedBackground))
                
                // Rows
                ForEach(presetQuantities, id: \.self) { qty in
                    let calc = product.batchCost(quantity: qty, hourlyRate: hourlyRate)
                    
                    HStack {
                        Text("\(qty)")
                            .fontWeight(qty == customQuantity ? .bold : .regular)
                            .frame(width: 50, alignment: .leading)
                        
                        Text(calc.batchTotalCost / Double(qty), format: .currency(code: "USD"))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Text(calc.batchTotalCost, format: .currency(code: "USD"))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Text(calc.batchProfit, format: .currency(code: "USD"))
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(qty == customQuantity ? Color.blue.opacity(0.1) : Color(.systemBackground))
                }
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
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        let calc = product.batchCost(quantity: max(1, customQuantity), hourlyRate: hourlyRate)
        let calc1000 = product.batchCost(quantity: 1000, hourlyRate: hourlyRate)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
            
            VStack(spacing: 8) {
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Profit per unit",
                    value: String(format: "$%.2f", calc.unitProfit)
                )
                
                InsightRow(
                    icon: "percent",
                    title: "Profit margin",
                    value: String(format: "%.1f%%", product.profitMargin(hourlyRate: hourlyRate))
                )
                
                InsightRow(
                    icon: "clock",
                    title: "Time per unit",
                    value: product.formattedTimeToProduce
                )
                
                if customQuantity < 1000 {
                    let savings = (calc.unitPrimeCost - (calc1000.batchPrimeCost / 1000)) * Double(customQuantity)
                    InsightRow(
                        icon: "lightbulb.fill",
                        title: "At 1000 units you'd save",
                        value: String(format: "$%.2f", savings),
                        highlight: true
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views
struct BatchMetricCard: View {
    let title: String
    let value: Double
    let isCurrency: Bool
    let color: Color
    var customText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let text = customText {
                Text(text)
                    .font(.title3)
                    .fontWeight(.bold)
            } else if isCurrency {
                Text(value, format: .currency(code: "USD"))
                    .font(.title3)
                    .fontWeight(.bold)
            } else {
                Text("\(Int(value))")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(highlight ? .yellow : .blue)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(highlight ? .yellow : .primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        BatchCalculatorView(product: Product(name: "Test Product", timeToProduce: 2))
    }
    .modelContainer(for: [Labor.self, Product.self], inMemory: true)
}
