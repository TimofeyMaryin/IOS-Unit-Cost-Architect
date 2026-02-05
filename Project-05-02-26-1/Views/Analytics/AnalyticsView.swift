import SwiftUI
import SwiftData
import Charts

/// Analytics dashboard with cost and profit charts
struct AnalyticsView: View {
    @Query(sort: \Product.name) private var products: [Product]
    @Query private var laborSettings: [Labor]
    
    @State private var selectedChartType: ChartType = .costComparison
    
    enum ChartType: String, CaseIterable {
        case costComparison = "Cost Comparison"
        case profitByTime = "Profit vs Time"
        case marginAnalysis = "Margin Analysis"
    }
    
    private var hourlyRate: Double {
        laborSettings.first?.hourlyRate ?? 15.0
    }
    
    private var topProducts: [Product] {
        Array(products.sorted { 
            $0.finalPrice(hourlyRate: hourlyRate) > $1.finalPrice(hourlyRate: hourlyRate) 
        }.prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    EmptyAnalyticsView()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Summary cards
                            summaryCards
                            
                            // Chart selector
                            Picker("Chart Type", selection: $selectedChartType) {
                                ForEach(ChartType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            // Selected chart
                            Group {
                                switch selectedChartType {
                                case .costComparison:
                                    costComparisonChart
                                case .profitByTime:
                                    profitByTimeChart
                                case .marginAnalysis:
                                    marginAnalysisChart
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                            .padding(.horizontal)
                            
                            // Detailed breakdown table
                            detailedBreakdown
                        }
                        .padding(.vertical)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Analytics")
        }
    }
    
    // MARK: - Summary Cards
    private var summaryCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                AnalyticsSummaryCard(
                    title: "Total Products",
                    value: "\(products.count)",
                    icon: "shippingbox.fill",
                    color: .blue
                )
                
                AnalyticsSummaryCard(
                    title: "Avg. Prime Cost",
                    value: averagePrimeCost.formatted(.currency(code: "USD")),
                    icon: "dollarsign.circle.fill",
                    color: .orange
                )
                
                AnalyticsSummaryCard(
                    title: "Avg. Final Price",
                    value: averageFinalPrice.formatted(.currency(code: "USD")),
                    icon: "tag.fill",
                    color: .green
                )
                
                AnalyticsSummaryCard(
                    title: "Avg. Profit Margin",
                    value: String(format: "%.1f%%", averageProfitMargin),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Cost Comparison Chart (Bar Chart)
    private var costComparisonChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Breakdown - Top 5 Products")
                .font(.headline)
            
            if topProducts.isEmpty {
                Text("No products to display")
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(topProducts) { product in
                        BarMark(
                            x: .value("Product", product.name),
                            y: .value("Amount", product.primeCost(hourlyRate: hourlyRate))
                        )
                        .foregroundStyle(.blue)
                        .annotation(position: .top) {
                            Text(product.primeCost(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                                .font(.caption2)
                        }
                    }
                    
                    ForEach(topProducts) { product in
                        BarMark(
                            x: .value("Product", product.name),
                            y: .value("Amount", product.totalCost(hourlyRate: hourlyRate))
                        )
                        .foregroundStyle(.orange)
                    }
                    
                    ForEach(topProducts) { product in
                        BarMark(
                            x: .value("Product", product.name),
                            y: .value("Amount", product.finalPrice(hourlyRate: hourlyRate))
                        )
                        .foregroundStyle(.green)
                    }
                }
                .frame(height: 300)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                Text(name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                // Legend
                HStack(spacing: 16) {
                    ChartLegendItem(itemColor: .blue, itemLabel: "Prime Cost")
                    ChartLegendItem(itemColor: .orange, itemLabel: "Total Cost")
                    ChartLegendItem(itemColor: .green, itemLabel: "Final Price")
                }
                .font(.caption)
            }
        }
    }
    
    // MARK: - Profit by Time Chart (Scatter Plot)
    private var profitByTimeChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profit vs Production Time")
                .font(.headline)
            
            Chart {
                ForEach(products) { product in
                    PointMark(
                        x: .value("Time (hours)", product.timeToProduce),
                        y: .value("Profit", product.netProfit(hourlyRate: hourlyRate))
                    )
                    .foregroundStyle(.green.gradient)
                    .symbolSize(100)
                    .annotation(position: .top) {
                        Text(product.name)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
                
                // Trend line
                if products.count >= 2 {
                    let trendData = calculateTrendLine()
                    LineMark(
                        x: .value("Time", trendData.0.0),
                        y: .value("Profit", trendData.0.1)
                    )
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    LineMark(
                        x: .value("Time", trendData.1.0),
                        y: .value("Profit", trendData.1.1)
                    )
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
            }
            .frame(height: 300)
            .chartXAxisLabel("Production Time (hours)")
            .chartYAxisLabel("Net Profit ($)")
            
            Text("Products with higher production time should ideally yield higher profits to justify the labor investment.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Margin Analysis Chart
    private var marginAnalysisChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profit Margin by Product")
                .font(.headline)
            
            Chart {
                ForEach(products.sorted { $0.profitMargin(hourlyRate: hourlyRate) > $1.profitMargin(hourlyRate: hourlyRate) }) { product in
                    BarMark(
                        x: .value("Margin", product.profitMargin(hourlyRate: hourlyRate)),
                        y: .value("Product", product.name)
                    )
                    .foregroundStyle(marginColor(for: product.profitMargin(hourlyRate: hourlyRate)).gradient)
                    .annotation(position: .trailing) {
                        Text(String(format: "%.1f%%", product.profitMargin(hourlyRate: hourlyRate)))
                            .font(.caption2)
                    }
                }
                
                // Target line at 25%
                RuleMark(x: .value("Target", 25))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Target 25%")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
            }
            .frame(height: max(200, CGFloat(products.count * 50)))
            .chartXAxisLabel("Profit Margin (%)")
            
            // Margin health indicator
            HStack(spacing: 16) {
                ChartLegendItem(itemColor: .red, itemLabel: "< 10%")
                ChartLegendItem(itemColor: .orange, itemLabel: "10-20%")
                ChartLegendItem(itemColor: .yellow, itemLabel: "20-30%")
                ChartLegendItem(itemColor: .green, itemLabel: "> 30%")
            }
            .font(.caption)
        }
    }
    
    // MARK: - Detailed Breakdown
    private var detailedBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            // Table-like layout
            VStack(spacing: 1) {
                // Header
                HStack {
                    Text("Product")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Prime")
                        .frame(width: 70, alignment: .trailing)
                    Text("Total")
                        .frame(width: 70, alignment: .trailing)
                    Text("Price")
                        .frame(width: 70, alignment: .trailing)
                    Text("Margin")
                        .frame(width: 60, alignment: .trailing)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemGroupedBackground))
                
                // Rows
                ForEach(products) { product in
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: product.iconName)
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text(product.name)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(product.primeCost(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                            .frame(width: 70, alignment: .trailing)
                        
                        Text(product.totalCost(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                            .frame(width: 70, alignment: .trailing)
                        
                        Text(product.finalPrice(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                            .frame(width: 70, alignment: .trailing)
                            .foregroundStyle(.green)
                        
                        Text(String(format: "%.0f%%", product.profitMargin(hourlyRate: hourlyRate)))
                            .frame(width: 60, alignment: .trailing)
                            .foregroundStyle(marginColor(for: product.profitMargin(hourlyRate: hourlyRate)))
                    }
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Computed Properties
    private var averagePrimeCost: Double {
        guard !products.isEmpty else { return 0 }
        return products.reduce(0) { $0 + $1.primeCost(hourlyRate: hourlyRate) } / Double(products.count)
    }
    
    private var averageFinalPrice: Double {
        guard !products.isEmpty else { return 0 }
        return products.reduce(0) { $0 + $1.finalPrice(hourlyRate: hourlyRate) } / Double(products.count)
    }
    
    private var averageProfitMargin: Double {
        guard !products.isEmpty else { return 0 }
        return products.reduce(0) { $0 + $1.profitMargin(hourlyRate: hourlyRate) } / Double(products.count)
    }
    
    private func marginColor(for margin: Double) -> Color {
        if margin < 10 { return .red }
        if margin < 20 { return .orange }
        if margin < 30 { return .yellow }
        return .green
    }
    
    private func calculateTrendLine() -> ((Double, Double), (Double, Double)) {
        let minTime = products.map { $0.timeToProduce }.min() ?? 0
        let maxTime = products.map { $0.timeToProduce }.max() ?? 1
        let avgProfit = products.reduce(0) { $0 + $1.netProfit(hourlyRate: hourlyRate) } / Double(products.count)
        
        return ((minTime, avgProfit * 0.5), (maxTime, avgProfit * 1.5))
    }
}

// MARK: - Analytics Summary Card
struct AnalyticsSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 150)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - Empty State
struct EmptyAnalyticsView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Data", systemImage: "chart.bar.xaxis")
        } description: {
            Text("Add products with ingredients to see analytics and charts. The wealth chart will show cost comparisons and profit analysis.")
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Material.self, Labor.self, Product.self, Ingredient.self], inMemory: true)
}
