import SwiftUI
import SwiftData
import Charts
import UniformTypeIdentifiers

/// Reports and CSV Export view
struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]
    @Query(sort: \Material.name) private var materials: [Material]
    @Query private var laborSettings: [Labor]
    
    @State private var selectedReportType: ReportType = .profitability
    @State private var showingExportOptions = false
    @State private var exportFeedback = false
    
    private var hourlyRate: Double {
        laborSettings.first?.hourlyRate ?? 15.0
    }
    
    enum ReportType: String, CaseIterable {
        case profitability = "Profitability"
        case costStructure = "Cost Structure"
        case inventory = "Inventory"
        case monthly = "Monthly Summary"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Report type selector
                reportTypeSelector
                
                // Report content based on selection
                reportContent
                
                // Export options
                exportSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: exportFeedback)
    }
    
    // MARK: - Report Type Selector
    private var reportTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ReportType.allCases, id: \.self) { type in
                    Button {
                        selectedReportType = type
                    } label: {
                        Text(type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedReportType == type ? Color.blue : Color(.tertiarySystemGroupedBackground))
                            .foregroundStyle(selectedReportType == type ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Report Content
    @ViewBuilder
    private var reportContent: some View {
        switch selectedReportType {
        case .profitability:
            profitabilityReport
        case .costStructure:
            costStructureReport
        case .inventory:
            inventoryReport
        case .monthly:
            monthlySummaryReport
        }
    }
    
    // MARK: - Profitability Report
    private var profitabilityReport: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profitability Ranking")
                .font(.headline)
            
            // Profit ranking chart
            let sortedProducts = products.sorted { $0.netProfit(hourlyRate: hourlyRate) > $1.netProfit(hourlyRate: hourlyRate) }
            
            Chart {
                ForEach(sortedProducts) { product in
                    BarMark(
                        x: .value("Profit", product.netProfit(hourlyRate: hourlyRate)),
                        y: .value("Product", product.name)
                    )
                    .foregroundStyle(product.netProfit(hourlyRate: hourlyRate) >= 0 ? Color.green.gradient : Color.red.gradient)
                    .annotation(position: .trailing) {
                        Text(product.netProfit(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                            .font(.caption2)
                    }
                }
            }
            .frame(height: CGFloat(max(200, products.count * 40)))
            .chartXAxisLabel("Net Profit ($)")
            
            // Summary stats
            VStack(spacing: 8) {
                HStack {
                    Text("Total Potential Profit")
                    Spacer()
                    Text(totalProfit, format: .currency(code: "USD"))
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                
                HStack {
                    Text("Average Profit Margin")
                    Spacer()
                    Text(String(format: "%.1f%%", averageMargin))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Highest Profit Product")
                    Spacer()
                    Text(sortedProducts.first?.name ?? "-")
                        .fontWeight(.semibold)
                }
            }
            .font(.subheadline)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var totalProfit: Double {
        products.reduce(0) { $0 + $1.netProfit(hourlyRate: hourlyRate) }
    }
    
    private var averageMargin: Double {
        guard !products.isEmpty else { return 0 }
        return products.reduce(0) { $0 + $1.profitMargin(hourlyRate: hourlyRate) } / Double(products.count)
    }
    
    // MARK: - Cost Structure Report
    private var costStructureReport: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Structure Analysis")
                .font(.headline)
            
            // Aggregate cost breakdown
            let totalMaterial = products.reduce(0) { $0 + $1.materialCost }
            let totalLabor = products.reduce(0) { $0 + $1.laborCost(hourlyRate: hourlyRate) }
            let totalOverhead = products.reduce(0) { $0 + ($1.totalCost(hourlyRate: hourlyRate) - $1.primeCost(hourlyRate: hourlyRate)) }
            let grandTotal = totalMaterial + totalLabor + totalOverhead
            
            // Pie chart data
            let pieData: [(String, Double, Color)] = [
                ("Materials", totalMaterial, .blue),
                ("Labor", totalLabor, .orange),
                ("Overhead", totalOverhead, .purple)
            ]
            
            // Pie chart
            Chart {
                ForEach(pieData, id: \.0) { item in
                    SectorMark(
                        angle: .value("Cost", item.1),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.2)
                    .annotation(position: .overlay) {
                        Text(String(format: "%.0f%%", grandTotal > 0 ? (item.1 / grandTotal) * 100 : 0))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 250)
            
            // Legend with values
            VStack(spacing: 8) {
                ForEach(pieData, id: \.0) { item in
                    HStack {
                        Circle()
                            .fill(item.2)
                            .frame(width: 12, height: 12)
                        
                        Text(item.0)
                        
                        Spacer()
                        
                        Text(item.1, format: .currency(code: "USD"))
                            .fontWeight(.medium)
                        
                        Text(String(format: "(%.1f%%)", grandTotal > 0 ? (item.1 / grandTotal) * 100 : 0))
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(grandTotal, format: .currency(code: "USD"))
                        .fontWeight(.bold)
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Inventory Report
    private var inventoryReport: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Inventory Overview")
                .font(.headline)
            
            // Summary stats
            let totalValue = materials.reduce(0) { $0 + $1.bulkPrice }
            let lowStockCount = materials.filter { $0.stockStatus != .inStock }.count
            
            HStack(spacing: 16) {
                InventoryStatCard(
                    title: "Materials",
                    value: "\(materials.count)",
                    icon: "cube.box.fill",
                    color: .blue
                )
                
                InventoryStatCard(
                    title: "Total Value",
                    value: totalValue.formatted(.currency(code: "USD")),
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                InventoryStatCard(
                    title: "Low Stock",
                    value: "\(lowStockCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: lowStockCount > 0 ? .orange : .green
                )
                
                InventoryStatCard(
                    title: "Categories",
                    value: "\(Set(materials.map { $0.category }).count)",
                    icon: "folder.fill",
                    color: .purple
                )
            }
            
            // Category breakdown
            Text("By Category")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
            let categoryData = Dictionary(grouping: materials) { $0.category }
            
            ForEach(Array(categoryData.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { category in
                let items = categoryData[category] ?? []
                let value = items.reduce(0) { $0 + $1.bulkPrice }
                
                HStack {
                    Image(systemName: category.icon)
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    
                    Text(category.rawValue)
                    
                    Spacer()
                    
                    Text("\(items.count) items")
                        .foregroundStyle(.secondary)
                    
                    Text(value, format: .currency(code: "USD"))
                        .fontWeight(.medium)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Monthly Summary
    private var monthlySummaryReport: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Summary")
                .font(.headline)
            
            // Date info
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text(Date(), format: .dateTime.month().year())
                    .font(.subheadline)
                Spacer()
            }
            
            Divider()
            
            // Key metrics
            VStack(spacing: 12) {
                MonthlyMetricRow(
                    label: "Total Products",
                    value: "\(products.count)",
                    change: nil
                )
                
                MonthlyMetricRow(
                    label: "Total Materials",
                    value: "\(materials.count)",
                    change: nil
                )
                
                MonthlyMetricRow(
                    label: "Avg. Prime Cost",
                    value: averagePrimeCost.formatted(.currency(code: "USD")),
                    change: nil
                )
                
                MonthlyMetricRow(
                    label: "Avg. Final Price",
                    value: averageFinalPrice.formatted(.currency(code: "USD")),
                    change: nil
                )
                
                MonthlyMetricRow(
                    label: "Avg. Profit Margin",
                    value: String(format: "%.1f%%", averageMargin),
                    change: nil
                )
                
                MonthlyMetricRow(
                    label: "Potential Revenue",
                    value: totalRevenue.formatted(.currency(code: "USD")),
                    change: nil
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var averagePrimeCost: Double {
        guard !products.isEmpty else { return 0 }
        return products.reduce(0) { $0 + $1.primeCost(hourlyRate: hourlyRate) } / Double(products.count)
    }
    
    private var averageFinalPrice: Double {
        guard !products.isEmpty else { return 0 }
        return products.reduce(0) { $0 + $1.finalPrice(hourlyRate: hourlyRate) } / Double(products.count)
    }
    
    private var totalRevenue: Double {
        products.reduce(0) { $0 + $1.finalPrice(hourlyRate: hourlyRate) }
    }
    
    // MARK: - Export Section
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Data")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button {
                    exportProductsCSV()
                } label: {
                    Label("Products CSV", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    exportMaterialsCSV()
                } label: {
                    Label("Materials CSV", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            Button {
                exportFullReport()
            } label: {
                Label("Full Report CSV", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Export Functions
    private func exportProductsCSV() {
        var csv = "Name,Material Cost,Labor Cost,Prime Cost,Overhead %,Total Cost,Markup %,Final Price,Net Profit,Margin %,Time (hrs),Ingredients\n"
        
        for product in products {
            let row = [
                product.name,
                String(format: "%.2f", product.materialCost),
                String(format: "%.2f", product.laborCost(hourlyRate: hourlyRate)),
                String(format: "%.2f", product.primeCost(hourlyRate: hourlyRate)),
                String(format: "%.1f", product.overheadPercentage),
                String(format: "%.2f", product.totalCost(hourlyRate: hourlyRate)),
                String(format: "%.1f", product.markupPercentage),
                String(format: "%.2f", product.finalPrice(hourlyRate: hourlyRate)),
                String(format: "%.2f", product.netProfit(hourlyRate: hourlyRate)),
                String(format: "%.1f", product.profitMargin(hourlyRate: hourlyRate)),
                String(format: "%.2f", product.timeToProduce),
                "\(product.ingredientCount)"
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        shareCSV(csv, filename: "products_report.csv")
    }
    
    private func exportMaterialsCSV() {
        var csv = "Name,Category,Bulk Price,Bulk Amount,Unit,Price Per Unit,Current Stock,Min Stock,SKU,Supplier\n"
        
        for material in materials {
            let row = [
                material.name,
                material.category.rawValue,
                String(format: "%.2f", material.bulkPrice),
                String(format: "%.2f", material.bulkAmount),
                material.unitType.symbol,
                String(format: "%.4f", material.pricePerUnit),
                String(format: "%.2f", material.currentStock),
                String(format: "%.2f", material.minimumStock),
                material.sku,
                material.supplier?.name ?? ""
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        shareCSV(csv, filename: "materials_report.csv")
    }
    
    private func exportFullReport() {
        var csv = "=== UNIT COST ARCHITECT REPORT ===\n"
        csv += "Generated: \(Date().formatted())\n\n"
        
        csv += "=== SUMMARY ===\n"
        csv += "Total Products,\(products.count)\n"
        csv += "Total Materials,\(materials.count)\n"
        csv += "Labor Rate,$\(hourlyRate)/hr\n"
        csv += "Total Potential Revenue,$\(String(format: "%.2f", totalRevenue))\n"
        csv += "Total Potential Profit,$\(String(format: "%.2f", totalProfit))\n\n"
        
        csv += "=== PRODUCTS ===\n"
        csv += "Name,Prime Cost,Final Price,Profit,Margin %\n"
        for product in products {
            csv += "\(product.name),$\(String(format: "%.2f", product.primeCost(hourlyRate: hourlyRate))),$\(String(format: "%.2f", product.finalPrice(hourlyRate: hourlyRate))),$\(String(format: "%.2f", product.netProfit(hourlyRate: hourlyRate))),\(String(format: "%.1f", product.profitMargin(hourlyRate: hourlyRate)))%\n"
        }
        
        csv += "\n=== MATERIALS ===\n"
        csv += "Name,Category,Price/Unit,Stock\n"
        for material in materials {
            csv += "\(material.name),\(material.category.rawValue),$\(String(format: "%.4f", material.pricePerUnit)),\(String(format: "%.2f", material.currentStock)) \(material.unitType.symbol)\n"
        }
        
        shareCSV(csv, filename: "full_report.csv")
    }
    
    private func shareCSV(_ content: String, filename: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            
            let activityVC = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
                exportFeedback.toggle()
            }
        } catch {
            print("Export failed: \(error)")
        }
    }
}

// MARK: - Supporting Views
struct InventoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MonthlyMetricRow: View {
    let label: String
    let value: String
    let change: Double?
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
            
            if let change = change {
                HStack(spacing: 2) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    Text(String(format: "%.1f%%", abs(change)))
                }
                .font(.caption)
                .foregroundStyle(change >= 0 ? .green : .red)
            }
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        ReportsView()
    }
    .modelContainer(for: [Product.self, Material.self, Labor.self], inMemory: true)
}
