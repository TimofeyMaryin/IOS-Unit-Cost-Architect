import SwiftUI
import SwiftData

/// Inventory stock tracking view
struct StockTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Material.name) private var materials: [Material]
    @Query private var userPreferences: [UserPreferences]
    
    @State private var filterStatus: Material.StockStatus? = nil
    @State private var showingLowStockOnly = false
    
    private var preferences: UserPreferences? {
        userPreferences.first
    }
    
    private var filteredMaterials: [Material] {
        var result = materials
        
        if showingLowStockOnly {
            result = result.filter { $0.stockStatus != .inStock }
        }
        
        if let status = filterStatus {
            result = result.filter { $0.stockStatus == status }
        }
        
        return result.sorted { $0.stockLevelPercentage < $1.stockLevelPercentage }
    }
    
    private var lowStockCount: Int {
        materials.filter { $0.stockStatus != .inStock }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                summaryCards
                
                // Filters
                filterSection
                
                // Stock list
                stockList
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Stock Tracking")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Summary Cards
    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StockSummaryCard(
                    title: "Total Items",
                    value: "\(materials.count)",
                    icon: "cube.box.fill",
                    color: .blue
                )
                
                StockSummaryCard(
                    title: "Low Stock",
                    value: "\(lowStockCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: lowStockCount > 0 ? .orange : .green
                )
            }
            
            HStack(spacing: 12) {
                StockSummaryCard(
                    title: "Out of Stock",
                    value: "\(materials.filter { $0.stockStatus == .outOfStock }.count)",
                    icon: "xmark.circle.fill",
                    color: .red
                )
                
                StockSummaryCard(
                    title: "Reorder Needed",
                    value: "\(materials.filter { $0.stockStatus == .reorderNeeded }.count)",
                    icon: "arrow.clockwise.circle.fill",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $showingLowStockOnly) {
                Label("Show Alerts Only", systemImage: "bell.fill")
            }
            .tint(.orange)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: filterStatus == nil) {
                        filterStatus = nil
                    }
                    
                    FilterChip(title: "In Stock", isSelected: filterStatus == .inStock, color: .green) {
                        filterStatus = .inStock
                    }
                    
                    FilterChip(title: "Low Stock", isSelected: filterStatus == .lowStock, color: .yellow) {
                        filterStatus = .lowStock
                    }
                    
                    FilterChip(title: "Reorder", isSelected: filterStatus == .reorderNeeded, color: .orange) {
                        filterStatus = .reorderNeeded
                    }
                    
                    FilterChip(title: "Out of Stock", isSelected: filterStatus == .outOfStock, color: .red) {
                        filterStatus = .outOfStock
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Stock List
    private var stockList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Inventory Status")
                    .font(.headline)
                Spacer()
                Text("\(filteredMaterials.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if filteredMaterials.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    
                    Text("All items are in stock!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(filteredMaterials) { material in
                    StockItemRow(material: material, modelContext: modelContext)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views
struct StockSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.tertiarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct StockItemRow: View {
    @Bindable var material: Material
    let modelContext: ModelContext
    
    @State private var showingEditStock = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Status indicator
                Image(systemName: material.stockStatus.icon)
                    .foregroundStyle(statusColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(material.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(material.stockStatus.label)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(format: "%.1f", material.currentStock)) \(material.unitType.symbol)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Min: \(String(format: "%.1f", material.minimumStock))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Stock level bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geo.size.width * min(material.stockLevelPercentage / 100, 1))
                }
            }
            .frame(height: 8)
            
            // Quick actions
            HStack(spacing: 12) {
                Button {
                    showingEditStock = true
                } label: {
                    Label("Update", systemImage: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Stepper(value: $material.currentStock, in: 0...10000, step: material.unitType == .pcs ? 1 : 0.5) {
                    Text("")
                }
                .labelsHidden()
                .onChange(of: material.currentStock) {
                    material.updatedAt = Date()
                    try? modelContext.save()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingEditStock) {
            StockEditSheet(material: material, modelContext: modelContext)
        }
    }
    
    private var statusColor: Color {
        switch material.stockStatus {
        case .inStock: return .green
        case .lowStock: return .yellow
        case .outOfStock: return .red
        case .reorderNeeded: return .orange
        }
    }
}

struct StockEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var material: Material
    let modelContext: ModelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Stock") {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("Stock", value: $material.currentStock, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(material.unitType.symbol)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Stock Thresholds") {
                    HStack {
                        Text("Minimum Stock")
                        Spacer()
                        TextField("Min", value: $material.minimumStock, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(material.unitType.symbol)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Reorder Point")
                        Spacer()
                        TextField("Reorder", value: $material.reorderPoint, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(material.unitType.symbol)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("SKU") {
                    TextField("Stock Keeping Unit", text: $material.sku)
                }
            }
            .navigationTitle("Edit Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        material.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StockTrackingView()
    }
    .modelContainer(for: [Material.self, UserPreferences.self], inMemory: true)
}
