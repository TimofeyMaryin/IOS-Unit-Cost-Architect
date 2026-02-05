import SwiftUI
import SwiftData

/// Detailed view of a single material with editing capability
struct MaterialDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var material: Material
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            headerSection
            pricingSection
            unitPriceSection
            stockSection
            toolsSection
            usageSection
            quickEditSection
            deleteSection
        }
        .navigationTitle("Material Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            MaterialEditView(material: material)
        }
        .alert("Delete Material?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteMaterial()
            }
        } message: {
            Text("This will remove the material and all its usage in products. This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: material.category.icon)
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(categoryColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(material.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(material.category.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Updated \(material.updatedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        Section("Pricing Information") {
            LabeledContent("Bulk Price") {
                Text(material.bulkPrice, format: .currency(code: "USD"))
                    .fontWeight(.medium)
            }
            
            LabeledContent("Bulk Amount") {
                Text(bulkAmountText)
                    .fontWeight(.medium)
            }
            
            LabeledContent("Unit Type") {
                Text(material.unitType.displayName)
            }
        }
    }
    
    private var bulkAmountText: String {
        String(format: "%.2f %@", material.bulkAmount, material.unitType.symbol)
    }
    
    // MARK: - Unit Price Section
    private var unitPriceSection: some View {
        Section {
            VStack(alignment: .center, spacing: 8) {
                Text("Unit Price")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(material.formattedPricePerUnit)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                
                Text("Per single \(material.unitType.symbol)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Stock Section
    private var stockSection: some View {
        Section("Stock Status") {
            HStack {
                Image(systemName: material.stockStatus.icon)
                    .foregroundStyle(stockStatusColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(material.stockStatus.label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Current: \(String(format: "%.1f", material.currentStock)) \(material.unitType.symbol)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Stock level gauge
                Gauge(value: min(material.stockLevelPercentage, 100), in: 0...100) {
                    Text("")
                } currentValueLabel: {
                    Text(String(format: "%.0f%%", material.stockLevelPercentage))
                        .font(.caption2)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(stockStatusColor)
                .scaleEffect(0.8)
            }
            
            // Stock details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Minimum Stock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Min", value: $material.minimumStock, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: material.minimumStock) {
                            material.updatedAt = Date()
                            try? modelContext.save()
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reorder Point")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Reorder", value: $material.reorderPoint, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: material.reorderPoint) {
                            material.updatedAt = Date()
                            try? modelContext.save()
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Stock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Stock", value: $material.currentStock, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: material.currentStock) {
                            material.updatedAt = Date()
                            try? modelContext.save()
                        }
                }
            }
            
            if !material.sku.isEmpty {
                LabeledContent("SKU") {
                    Text(material.sku)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var stockStatusColor: Color {
        switch material.stockStatus {
        case .inStock: return .green
        case .lowStock: return .yellow
        case .outOfStock: return .red
        case .reorderNeeded: return .orange
        }
    }
    
    // MARK: - Tools Section
    private var toolsSection: some View {
        Section("Tools") {
            NavigationLink(destination: PriceHistoryView(material: material)) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Price History")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Track price changes over time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let historyCount = material.priceHistory?.count, historyCount > 0 {
                        Text("\(historyCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Supplier link
            if let supplier = material.supplier {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.indigo)
                    
                    VStack(alignment: .leading) {
                        Text("Supplier")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(supplier.name)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    if supplier.isPreferred {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
            }
            
            // Record price button
            Button {
                material.recordPriceHistory(note: "", context: modelContext)
                try? modelContext.save()
            } label: {
                Label("Record Current Price", systemImage: "clock.badge.checkmark")
            }
        }
    }
    
    // MARK: - Usage Section
    @ViewBuilder
    private var usageSection: some View {
        if let ingredients = material.ingredients, !ingredients.isEmpty {
            Section("Used In Products") {
                ForEach(ingredients) { ingredient in
                    IngredientUsageRow(ingredient: ingredient, material: material)
                }
            }
        }
    }
    
    // MARK: - Quick Edit Section
    private var quickEditSection: some View {
        Section {
            HStack {
                Text("Bulk Price")
                Spacer()
                TextField("Price", value: $material.bulkPrice, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: material.bulkPrice) {
                        material.updatedAt = Date()
                        try? modelContext.save()
                    }
            }
            
            HStack {
                Text("Bulk Amount")
                Spacer()
                TextField("Amount", value: $material.bulkAmount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: material.bulkAmount) {
                        if material.bulkAmount > 0 {
                            material.updatedAt = Date()
                            try? modelContext.save()
                        }
                    }
                Text(material.unitType.symbol)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Quick Price Update")
        } footer: {
            Text("Changes here update all linked product costs automatically.")
        }
    }
    
    // MARK: - Delete Section
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete Material", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helpers
    private var categoryColor: Color {
        switch material.category {
        case .rawMaterial: return .blue
        case .packaging: return .orange
        case .consumable: return .green
        case .component: return .purple
        case .chemical: return .red
        case .textile: return .pink
        case .metal: return .gray
        case .wood: return .brown
        case .plastic: return .cyan
        case .other: return .indigo
        }
    }
    
    private func deleteMaterial() {
        modelContext.delete(material)
        try? modelContext.save()
    }
}

// MARK: - Ingredient Usage Row
struct IngredientUsageRow: View {
    let ingredient: Ingredient
    let material: Material
    
    var body: some View {
        if let product = ingredient.product {
            HStack {
                Image(systemName: product.iconName)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading) {
                    Text(product.name)
                        .font(.subheadline)
                    Text(usageText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(ingredient.formattedCost)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
            }
        }
    }
    
    private var usageText: String {
        String(format: "%.2f %@ per unit", ingredient.amountRequired, material.unitType.symbol)
    }
}

#Preview {
    NavigationStack {
        MaterialDetailView(material: Material(
            name: "Steel Sheet",
            category: .metal,
            bulkPrice: 150,
            bulkAmount: 10,
            unitType: .kg
        ))
    }
    .modelContainer(for: Material.self, inMemory: true)
}
