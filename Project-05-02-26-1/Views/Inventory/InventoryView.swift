import SwiftUI
import SwiftData

/// Main inventory/warehouse view showing all raw materials
struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Material.name) private var materials: [Material]
    
    @State private var searchText = ""
    @State private var selectedCategory: MaterialCategory?
    @State private var showingAddMaterial = false
    @State private var sortOrder: SortOrder = .name
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case category = "Category"
        case price = "Price"
        case recent = "Recent"
    }
    
    var filteredMaterials: [Material] {
        var result = materials
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Sort
        switch sortOrder {
        case .name:
            result.sort { $0.name < $1.name }
        case .category:
            result.sort { $0.category.rawValue < $1.category.rawValue }
        case .price:
            result.sort { $0.pricePerUnit > $1.pricePerUnit }
        case .recent:
            result.sort { $0.updatedAt > $1.updatedAt }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if materials.isEmpty {
                    EmptyInventoryView(showingAddMaterial: $showingAddMaterial)
                } else {
                    materialsList
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMaterial = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Picker("Sort By", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search materials...")
            .sheet(isPresented: $showingAddMaterial) {
                MaterialEditView(material: nil)
            }
        }
    }
    
    private var materialsList: some View {
        VStack(spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(
                        title: "All",
                        icon: "square.grid.2x2.fill",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(MaterialCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            
            // Stats bar
            HStack {
                Label("\(filteredMaterials.count) items", systemImage: "cube.box")
                Spacer()
                Text("Total Value: \(totalValue, format: .currency(code: "USD"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemGroupedBackground))
            
            // Materials list
            List {
                ForEach(filteredMaterials) { material in
                    NavigationLink(destination: MaterialDetailView(material: material)) {
                        MaterialRowView(material: material)
                    }
                }
                .onDelete(perform: deleteMaterials)
            }
            .listStyle(.plain)
        }
    }
    
    private var totalValue: Double {
        filteredMaterials.reduce(0) { $0 + $1.bulkPrice }
    }
    
    private func deleteMaterials(at offsets: IndexSet) {
        for index in offsets {
            let material = filteredMaterials[index]
            modelContext.delete(material)
        }
        try? modelContext.save()
    }
}

// MARK: - Material Row View
struct MaterialRowView: View {
    let material: Material
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: material.category.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(categoryColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(material.name)
                    .font(.headline)
                
                Text(material.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(material.formattedPricePerUnit)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(material.formattedBulkPrice)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
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
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State
struct EmptyInventoryView: View {
    @Binding var showingAddMaterial: Bool
    
    var body: some View {
        ContentUnavailableView {
            Label("No Materials", systemImage: "cube.box")
        } description: {
            Text("Start by adding raw materials to your inventory. Materials are the building blocks for calculating product costs.")
        } actions: {
            Button {
                showingAddMaterial = true
            } label: {
                Label("Add First Material", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    InventoryView()
        .modelContainer(for: [Material.self, Labor.self, Product.self, Ingredient.self, AppSettings.self], inMemory: true)
}
