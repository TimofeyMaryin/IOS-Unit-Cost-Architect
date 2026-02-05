import SwiftUI
import SwiftData
import Charts

/// Break-even analysis view
struct BreakEvenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var laborSettings: [Labor]
    
    @Bindable var product: Product
    
    private var hourlyRate: Double {
        laborSettings.first?.hourlyRate ?? 15.0
    }
    
    private var analysis: BreakEvenResult {
        product.breakEvenAnalysis(hourlyRate: hourlyRate)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Main metrics
                mainMetrics
                
                // Break-even chart
                breakEvenChart
                
                // Settings
                settingsSection
                
                // Analysis details
                analysisDetails
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Break-Even Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Main Metrics
    private var mainMetrics: some View {
        VStack(spacing: 16) {
            // Break-even units - main highlight
            VStack(spacing: 8) {
                Text("Break-Even Point")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(analysis.breakEvenUnits)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    
                    Text("units")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Text("to cover fixed costs of \(analysis.fixedCosts, format: .currency(code: "USD"))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Secondary metrics
            HStack(spacing: 16) {
                MetricBox(
                    title: "Break-Even Revenue",
                    value: analysis.breakEvenRevenue,
                    format: .currency,
                    color: .orange
                )
                
                MetricBox(
                    title: "Contribution Margin",
                    value: analysis.contributionMargin,
                    format: .currency,
                    color: .green
                )
            }
            
            // Profit at target
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profit at Target (\(analysis.targetUnits) units)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(analysis.profitAtTarget, format: .currency(code: "USD"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(analysis.isProfitable ? .green : .red)
                }
                
                Spacer()
                
                // Safety margin gauge
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Safety Margin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.1f%%", analysis.safetyMarginPercent))
                        .font(.headline)
                        .foregroundStyle(analysis.safetyMarginPercent > 20 ? .green : .orange)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Break-Even Chart
    private var breakEvenChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profit/Loss by Volume")
                .font(.headline)
            
            Chart {
                // Fixed costs line (horizontal)
                RuleMark(y: .value("Fixed Costs", -analysis.fixedCosts))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .leading) {
                        Text("Fixed Costs")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                
                // Break-even point
                RuleMark(x: .value("Break-Even", analysis.breakEvenUnits))
                    .foregroundStyle(.blue.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                
                // Profit/Loss line
                ForEach(chartData, id: \.units) { point in
                    LineMark(
                        x: .value("Units", point.units),
                        y: .value("Profit", point.profit)
                    )
                    .foregroundStyle(point.profit >= 0 ? .green : .red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Units", point.units),
                        y: .value("Profit", point.profit)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [point.profit >= 0 ? .green.opacity(0.3) : .red.opacity(0.3), .clear],
                            startPoint: point.profit >= 0 ? .top : .bottom,
                            endPoint: point.profit >= 0 ? .bottom : .top
                        )
                    )
                }
                
                // Zero line
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(.gray.opacity(0.5))
                
                // Target point
                PointMark(
                    x: .value("Target", analysis.targetUnits),
                    y: .value("Profit", analysis.profitAtTarget)
                )
                .foregroundStyle(.purple)
                .symbolSize(150)
                .annotation(position: .top) {
                    Text("Target")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                }
            }
            .frame(height: 250)
            .chartXAxisLabel("Units Sold")
            .chartYAxisLabel("Profit/Loss ($)")
            
            // Legend
            HStack(spacing: 16) {
                ChartLegendItem(itemColor: .green, itemLabel: "Profit Zone")
                ChartLegendItem(itemColor: .red, itemLabel: "Loss Zone")
                ChartLegendItem(itemColor: .blue, itemLabel: "Break-Even")
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var chartData: [(units: Int, profit: Double)] {
        let maxUnits = max(analysis.targetUnits * 2, analysis.breakEvenUnits * 2, 100)
        let step = max(1, maxUnits / 20)
        
        return stride(from: 0, through: maxUnits, by: step).map { units in
            let revenue = Double(units) * product.finalPrice(hourlyRate: hourlyRate)
            let variableCosts = Double(units) * product.totalCost(hourlyRate: hourlyRate)
            let profit = revenue - variableCosts - analysis.fixedCosts
            return (units: units, profit: profit)
        }
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parameters")
                .font(.headline)
            
            VStack(spacing: 16) {
                HStack {
                    Label("Fixed Costs", systemImage: "dollarsign.circle")
                    Spacer()
                    TextField("Amount", value: $product.fixedCosts, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: product.fixedCosts) {
                            try? modelContext.save()
                        }
                }
                
                HStack {
                    Label("Target Units/Month", systemImage: "target")
                    Spacer()
                    TextField("Units", value: $product.targetUnitsPerMonth, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: product.targetUnitsPerMonth) {
                            try? modelContext.save()
                        }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("Fixed costs include one-time expenses like tooling, equipment, setup costs, etc.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Analysis Details
    private var analysisDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Analysis")
                .font(.headline)
            
            VStack(spacing: 8) {
                DetailRow(label: "Selling Price per Unit", value: product.finalPrice(hourlyRate: hourlyRate), format: .currency)
                DetailRow(label: "Variable Cost per Unit", value: product.totalCost(hourlyRate: hourlyRate), format: .currency)
                DetailRow(label: "Contribution Margin", value: analysis.contributionMargin, format: .currency)
                Divider()
                DetailRow(label: "Fixed Costs", value: analysis.fixedCosts, format: .currency)
                DetailRow(label: "Break-Even Units", value: Double(analysis.breakEvenUnits), format: .number)
                DetailRow(label: "Break-Even Revenue", value: analysis.breakEvenRevenue, format: .currency)
                Divider()
                DetailRow(label: "Target Volume", value: Double(analysis.targetUnits), format: .number)
                DetailRow(label: "Expected Profit", value: analysis.profitAtTarget, format: .currency, highlight: true)
                DetailRow(label: "Safety Margin", value: analysis.safetyMarginPercent, format: .percent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views
struct MetricBox: View {
    let title: String
    let value: Double
    let format: MetricFormat
    let color: Color
    
    enum MetricFormat {
        case currency, percent, number
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            switch format {
            case .currency:
                Text(value, format: .currency(code: "USD"))
                    .font(.headline)
                    .fontWeight(.bold)
            case .percent:
                Text(String(format: "%.1f%%", value))
                    .font(.headline)
                    .fontWeight(.bold)
            case .number:
                Text("\(Int(value))")
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailRow: View {
    let label: String
    let value: Double
    let format: MetricBox.MetricFormat
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(highlight ? .primary : .secondary)
            
            Spacer()
            
            Group {
                switch format {
                case .currency:
                    Text(value, format: .currency(code: "USD"))
                case .percent:
                    Text(String(format: "%.1f%%", value))
                case .number:
                    Text("\(Int(value))")
                }
            }
            .font(.subheadline)
            .fontWeight(highlight ? .bold : .medium)
            .foregroundStyle(highlight ? (value >= 0 ? .green : .red) : .primary)
        }
    }
}

#Preview {
    NavigationStack {
        BreakEvenView(product: Product(name: "Test", fixedCosts: 500, targetUnitsPerMonth: 200))
    }
    .modelContainer(for: [Labor.self, Product.self], inMemory: true)
}
