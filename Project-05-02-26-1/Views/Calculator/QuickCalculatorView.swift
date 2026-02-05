import SwiftUI
import SwiftData

/// Quick calculator for ad-hoc cost calculations without saving
struct QuickCalculatorView: View {
    @Query private var laborSettings: [Labor]
    
    // Input values
    @State private var materialCost: Double = 0
    @State private var laborHours: Double = 1
    @State private var overheadPercent: Double = 15
    @State private var markupPercent: Double = 30
    @State private var quantity: Int = 1
    
    // Calculated values
    private var hourlyRate: Double {
        laborSettings.first?.hourlyRate ?? 15.0
    }
    
    private var laborCost: Double {
        laborHours * hourlyRate
    }
    
    private var primeCost: Double {
        materialCost + laborCost
    }
    
    private var overheadAmount: Double {
        primeCost * (overheadPercent / 100)
    }
    
    private var totalCost: Double {
        primeCost + overheadAmount
    }
    
    private var markupAmount: Double {
        totalCost * (markupPercent / 100)
    }
    
    private var finalPrice: Double {
        totalCost + markupAmount
    }
    
    private var netProfit: Double {
        finalPrice - totalCost
    }
    
    private var profitMargin: Double {
        guard finalPrice > 0 else { return 0 }
        return (netProfit / finalPrice) * 100
    }
    
    // Batch calculations
    private var batchTotalCost: Double {
        totalCost * Double(quantity)
    }
    
    private var batchRevenue: Double {
        finalPrice * Double(quantity)
    }
    
    private var batchProfit: Double {
        netProfit * Double(quantity)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input section
                inputSection
                
                // Results section
                resultsSection
                
                // Batch calculation
                batchSection
                
                // Reset button
                Button {
                    resetCalculator()
                } label: {
                    Label("Reset Calculator", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Quick Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Inputs")
                .font(.headline)
            
            // Material cost
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Material Cost", systemImage: "cube.box.fill")
                    Spacer()
                    Text(materialCost, format: .currency(code: "USD"))
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                
                HStack {
                    Text("$0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Slider(value: $materialCost, in: 0...1000, step: 0.5)
                        .tint(.blue)
                    
                    Text("$1000")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Quick presets
                HStack(spacing: 8) {
                    ForEach([10.0, 25.0, 50.0, 100.0, 250.0], id: \.self) { value in
                        Button {
                            materialCost = value
                        } label: {
                            Text("$\(Int(value))")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(materialCost == value ? Color.blue : Color(.tertiarySystemGroupedBackground))
                                .foregroundStyle(materialCost == value ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
            
            // Labor hours
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Labor Time", systemImage: "clock.fill")
                    Spacer()
                    Text(laborHours == 1 ? "1 hour" : String(format: "%.1f hours", laborHours))
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
                
                Slider(value: $laborHours, in: 0.1...24, step: 0.1)
                    .tint(.orange)
                
                Text("Labor rate: $\(String(format: "%.2f", hourlyRate))/hr = \(laborCost, format: .currency(code: "USD"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Overhead
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Overhead", systemImage: "building.2.fill")
                    Spacer()
                    Text("\(Int(overheadPercent))%")
                        .fontWeight(.medium)
                        .foregroundStyle(.purple)
                }
                
                Slider(value: $overheadPercent, in: 0...50, step: 1)
                    .tint(.purple)
            }
            
            Divider()
            
            // Markup
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Markup", systemImage: "percent")
                    Spacer()
                    Text("\(Int(markupPercent))%")
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
                
                Slider(value: $markupPercent, in: 0...200, step: 1)
                    .tint(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unit Calculation")
                .font(.headline)
            
            VStack(spacing: 12) {
                ResultRow(
                    label: "Material Cost",
                    value: materialCost,
                    icon: "cube.box.fill",
                    color: .blue
                )
                
                ResultRow(
                    label: "Labor Cost",
                    value: laborCost,
                    icon: "person.fill",
                    color: .orange,
                    subtitle: "\(String(format: "%.1f", laborHours))h × $\(String(format: "%.2f", hourlyRate))"
                )
                
                Divider()
                
                ResultRow(
                    label: "Prime Cost",
                    value: primeCost,
                    icon: "equal.circle.fill",
                    color: .gray,
                    isHighlighted: true
                )
                
                ResultRow(
                    label: "Overhead (+\(Int(overheadPercent))%)",
                    value: overheadAmount,
                    icon: "building.2.fill",
                    color: .purple
                )
                
                ResultRow(
                    label: "Total Cost",
                    value: totalCost,
                    icon: "sum",
                    color: .indigo,
                    isHighlighted: true
                )
                
                ResultRow(
                    label: "Markup (+\(Int(markupPercent))%)",
                    value: markupAmount,
                    icon: "tag.fill",
                    color: .green
                )
                
                Divider()
                
                // Final price - highlighted
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Final Price")
                            .font(.headline)
                        Text("Selling price per unit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(finalPrice, format: .currency(code: "USD"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Profit summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Profit")
                            .font(.subheadline)
                        Text(netProfit, format: .currency(code: "USD"))
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Margin")
                            .font(.subheadline)
                        Text(String(format: "%.1f%%", profitMargin))
                            .font(.headline)
                            .foregroundStyle(profitMargin >= 20 ? .green : .orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Batch Section
    private var batchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Batch Calculation")
                .font(.headline)
            
            // Quantity stepper
            HStack {
                Text("Quantity")
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        if quantity > 1 { quantity -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("\(quantity)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(minWidth: 50)
                    
                    Button {
                        quantity += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            // Quick quantity presets
            HStack(spacing: 8) {
                ForEach([1, 10, 50, 100, 500, 1000], id: \.self) { qty in
                    Button {
                        quantity = qty
                    } label: {
                        Text("\(qty)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(quantity == qty ? Color.blue : Color(.tertiarySystemGroupedBackground))
                            .foregroundStyle(quantity == qty ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
            
            // Batch results
            HStack(spacing: 16) {
                BatchResultCard(
                    title: "Total Cost",
                    value: batchTotalCost,
                    color: .orange
                )
                
                BatchResultCard(
                    title: "Revenue",
                    value: batchRevenue,
                    color: .green
                )
                
                BatchResultCard(
                    title: "Profit",
                    value: batchProfit,
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func resetCalculator() {
        materialCost = 0
        laborHours = 1
        overheadPercent = 15
        markupPercent = 30
        quantity = 1
    }
}

// MARK: - Supporting Views
struct ResultRow: View {
    let label: String
    let value: Double
    let icon: String
    let color: Color
    var subtitle: String? = nil
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(isHighlighted ? .subheadline.weight(.semibold) : .subheadline)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Text(value, format: .currency(code: "USD"))
                .font(isHighlighted ? .headline : .subheadline)
                .fontWeight(isHighlighted ? .semibold : .regular)
        }
    }
}

struct BatchResultCard: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value, format: .currency(code: "USD"))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        QuickCalculatorView()
    }
    .modelContainer(for: Labor.self, inMemory: true)
}
