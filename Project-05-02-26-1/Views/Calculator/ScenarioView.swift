import SwiftUI
import SwiftData
import Charts

/// Scenario planning / What-If analysis view
struct ScenarioView: View {
    @Query private var laborSettings: [Labor]
    
    let product: Product
    
    @State private var materialChange: Double = 0
    @State private var laborChange: Double = 0
    
    private var hourlyRate: Double {
        laborSettings.first?.hourlyRate ?? 15.0
    }
    
    private var scenario: ScenarioResult {
        product.scenarioAnalysis(
            materialPriceChange: materialChange,
            laborRateChange: laborChange,
            hourlyRate: hourlyRate
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Scenario controls
                controlsSection
                
                // Impact summary
                impactSummary
                
                // Comparison chart
                comparisonChart
                
                // Detailed breakdown
                detailedBreakdown
                
                // Presets
                presetsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("What-If Scenarios")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Adjust Variables")
                .font(.headline)
            
            // Material price change
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Material Costs", systemImage: "cube.box.fill")
                    Spacer()
                    Text(changeText(materialChange))
                        .font(.headline)
                        .foregroundStyle(materialChange >= 0 ? .red : .green)
                        .monospacedDigit()
                }
                
                Slider(value: $materialChange, in: -50...100, step: 1)
                    .tint(materialChange >= 0 ? .red : .green)
                
                HStack {
                    Text("-50%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("0%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("+100%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Labor rate change
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Labor Rate", systemImage: "person.fill")
                    Spacer()
                    Text(changeText(laborChange))
                        .font(.headline)
                        .foregroundStyle(laborChange >= 0 ? .red : .green)
                        .monospacedDigit()
                }
                
                Slider(value: $laborChange, in: -50...100, step: 1)
                    .tint(laborChange >= 0 ? .red : .green)
                
                HStack {
                    Text("-50%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("0%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("+100%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Reset button
            Button {
                withAnimation {
                    materialChange = 0
                    laborChange = 0
                }
            } label: {
                Label("Reset to Current", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(materialChange == 0 && laborChange == 0)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func changeText(_ value: Double) -> String {
        if value >= 0 {
            return "+\(Int(value))%"
        } else {
            return "\(Int(value))%"
        }
    }
    
    // MARK: - Impact Summary
    private var impactSummary: some View {
        VStack(spacing: 16) {
            // Main profit impact
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profit Impact")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(scenario.profitChange >= 0 ? "+" : "")
                        Text(scenario.profitChange, format: .currency(code: "USD"))
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(scenario.isPositive ? .green : .red)
                }
                
                Spacer()
                
                // Percentage change
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Change")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%+.1f%%", scenario.profitChangePercent))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(scenario.isPositive ? .green : .red)
                }
            }
            .padding()
            .background(scenario.isPositive ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Before/After comparison
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("CURRENT")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prime Cost")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(scenario.originalPrimeCost, format: .currency(code: "USD"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Final Price")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(scenario.originalFinalPrice, format: .currency(code: "USD"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(scenario.originalProfit, format: .currency(code: "USD"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("SCENARIO")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prime Cost")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text(scenario.newPrimeCost, format: .currency(code: "USD"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            changeIndicator(scenario.primeChange)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Final Price")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text(scenario.newFinalPrice, format: .currency(code: "USD"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            changeIndicator(scenario.priceChange)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text(scenario.newProfit, format: .currency(code: "USD"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(scenario.newProfit >= 0 ? .green : .red)
                            changeIndicator(scenario.profitChange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    @ViewBuilder
    private func changeIndicator(_ change: Double) -> some View {
        if abs(change) > 0.01 {
            HStack(spacing: 2) {
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                Text(abs(change), format: .currency(code: "USD"))
                    .font(.caption2)
            }
            .foregroundStyle(change >= 0 ? .red : .green)
        }
    }
    
    // MARK: - Comparison Chart
    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visual Comparison")
                .font(.headline)
            
            Chart {
                // Original values
                BarMark(
                    x: .value("Metric", "Prime Cost"),
                    y: .value("Value", scenario.originalPrimeCost)
                )
                .foregroundStyle(.blue.opacity(0.5))
                .position(by: .value("Type", "Current"))
                
                BarMark(
                    x: .value("Metric", "Prime Cost"),
                    y: .value("Value", scenario.newPrimeCost)
                )
                .foregroundStyle(.blue)
                .position(by: .value("Type", "Scenario"))
                
                BarMark(
                    x: .value("Metric", "Final Price"),
                    y: .value("Value", scenario.originalFinalPrice)
                )
                .foregroundStyle(.green.opacity(0.5))
                .position(by: .value("Type", "Current"))
                
                BarMark(
                    x: .value("Metric", "Final Price"),
                    y: .value("Value", scenario.newFinalPrice)
                )
                .foregroundStyle(.green)
                .position(by: .value("Type", "Scenario"))
                
                BarMark(
                    x: .value("Metric", "Profit"),
                    y: .value("Value", scenario.originalProfit)
                )
                .foregroundStyle(.purple.opacity(0.5))
                .position(by: .value("Type", "Current"))
                
                BarMark(
                    x: .value("Metric", "Profit"),
                    y: .value("Value", scenario.newProfit)
                )
                .foregroundStyle(.purple)
                .position(by: .value("Type", "Scenario"))
            }
            .frame(height: 200)
            
            HStack(spacing: 16) {
                ChartLegendItem(itemColor: .gray, itemLabel: "Current")
                ChartLegendItem(itemColor: .blue, itemLabel: "Scenario")
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Detailed Breakdown
    private var detailedBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Impact Details")
                .font(.headline)
            
            VStack(spacing: 8) {
                BreakdownRow(
                    label: "Material Cost Change",
                    original: product.materialCost,
                    new: product.materialCost * (1 + materialChange / 100)
                )
                
                BreakdownRow(
                    label: "Labor Cost Change",
                    original: product.laborCost(hourlyRate: hourlyRate),
                    new: product.laborCost(hourlyRate: hourlyRate * (1 + laborChange / 100))
                )
                
                Divider()
                
                BreakdownRow(
                    label: "Prime Cost",
                    original: scenario.originalPrimeCost,
                    new: scenario.newPrimeCost
                )
                
                BreakdownRow(
                    label: "Total Cost (with overhead)",
                    original: product.totalCost(hourlyRate: hourlyRate),
                    new: scenario.newPrimeCost * (1 + product.overheadPercentage / 100)
                )
                
                BreakdownRow(
                    label: "Final Price (with markup)",
                    original: scenario.originalFinalPrice,
                    new: scenario.newFinalPrice
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Presets Section
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Scenarios")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PresetButton(title: "Material +20%", icon: "arrow.up.circle.fill", color: .orange) {
                    withAnimation {
                        materialChange = 20
                        laborChange = 0
                    }
                }
                
                PresetButton(title: "Labor +15%", icon: "person.fill.badge.plus", color: .blue) {
                    withAnimation {
                        materialChange = 0
                        laborChange = 15
                    }
                }
                
                PresetButton(title: "All +10%", icon: "exclamationmark.triangle.fill", color: .red) {
                    withAnimation {
                        materialChange = 10
                        laborChange = 10
                    }
                }
                
                PresetButton(title: "Material -10%", icon: "arrow.down.circle.fill", color: .green) {
                    withAnimation {
                        materialChange = -10
                        laborChange = 0
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views
struct BreakdownRow: View {
    let label: String
    let original: Double
    let new: Double
    
    private var change: Double { new - original }
    private var changePercent: Double {
        guard original > 0 else { return 0 }
        return (change / original) * 100
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(new, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if abs(change) > 0.01 {
                    Text(String(format: "%+.1f%%", changePercent))
                        .font(.caption2)
                        .foregroundStyle(change >= 0 ? .red : .green)
                }
            }
        }
    }
}

struct PresetButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ScenarioView(product: Product(name: "Test Product", timeToProduce: 2))
    }
    .modelContainer(for: [Labor.self, Product.self], inMemory: true)
}
