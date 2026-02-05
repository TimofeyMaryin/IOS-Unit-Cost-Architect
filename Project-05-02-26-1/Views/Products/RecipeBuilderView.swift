import SwiftUI
import SwiftData

/// Recipe builder for adding/removing ingredients from a product
struct RecipeBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Material.name) private var allMaterials: [Material]
    
    @Bindable var product: Product
    
    @State private var searchText = ""
    @State private var selectedCategory: MaterialCategory?
    @State private var showingAddSheet = false
    @State private var editingIngredient: Ingredient?
    @State private var showingValidationAlert = false
    
    var filteredMaterials: [Material] {
        var result = allMaterials
        
        // Exclude materials already in recipe
        let existingMaterialIds = Set((product.ingredients ?? []).compactMap { $0.material?.id })
        result = result.filter { !existingMaterialIds.contains($0.id) }
        
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
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Current recipe section
                if let ingredients = product.ingredients, !ingredients.isEmpty {
                    currentRecipeSection(ingredients: ingredients)
                }
                
                // Available materials section
                availableMaterialsSection
            }
            .navigationTitle("Recipe Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        if validateAndSave() {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .searchable(text: $searchText, prompt: "Search materials to add...")
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Some ingredients have invalid amounts. Please ensure all amounts are greater than 0.")
            }
        }
    }
    
    // MARK: - Current Recipe Section
    private func currentRecipeSection(ingredients: [Ingredient]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Current Recipe")
                    .font(.headline)
                Spacer()
                Text("\(ingredients.count) items • \(product.materialCost, format: .currency(code: "USD"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            
            List {
                ForEach(ingredients) { ingredient in
                    IngredientEditRow(ingredient: ingredient, modelContext: modelContext)
                }
                .onDelete(perform: deleteIngredients)
            }
            .listStyle(.plain)
            .frame(maxHeight: 250)
        }
    }
    
    // MARK: - Available Materials Section
    private var availableMaterialsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Add Materials")
                    .font(.headline)
                Spacer()
                Text("\(filteredMaterials.count) available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            
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
            
            if allMaterials.isEmpty {
                ContentUnavailableView {
                    Label("No Materials", systemImage: "cube.box")
                } description: {
                    Text("Add materials to your inventory first before building a recipe.")
                }
                .frame(maxHeight: .infinity)
            } else if filteredMaterials.isEmpty {
                ContentUnavailableView {
                    Label("All Added", systemImage: "checkmark.circle")
                } description: {
                    Text("All available materials have been added to this recipe.")
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredMaterials) { material in
                        MaterialAddRow(material: material) {
                            addMaterial(material)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Actions
    private func addMaterial(_ material: Material) {
        let ingredient = Ingredient(
            amountRequired: 1.0,
            material: material,
            product: product
        )
        
        modelContext.insert(ingredient)
        
        if product.ingredients == nil {
            product.ingredients = []
        }
        product.ingredients?.append(ingredient)
        product.updatedAt = Date()
        
        try? modelContext.save()
    }
    
    private func deleteIngredients(at offsets: IndexSet) {
        guard let ingredients = product.ingredients else { return }
        
        for index in offsets {
            let ingredient = ingredients[index]
            modelContext.delete(ingredient)
        }
        
        product.updatedAt = Date()
        try? modelContext.save()
    }
    
    private func validateAndSave() -> Bool {
        // Check all ingredients have valid amounts
        if let ingredients = product.ingredients {
            for ingredient in ingredients {
                if ingredient.amountRequired <= 0 {
                    showingValidationAlert = true
                    return false
                }
            }
        }
        
        try? modelContext.save()
        return true
    }
}

// MARK: - Ingredient Edit Row
struct IngredientEditRow: View {
    @Bindable var ingredient: Ingredient
    let modelContext: ModelContext
    
    var body: some View {
        HStack(spacing: 12) {
            if let material = ingredient.material {
                Image(systemName: material.category.icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(material.name)
                        .font(.subheadline)
                    
                    Text(material.formattedPricePerUnit)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                // Amount input
                HStack(spacing: 4) {
                    TextField("Amount", value: $ingredient.amountRequired, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: ingredient.amountRequired) {
                            try? modelContext.save()
                        }
                    
                    Text(material.unitType.symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .leading)
                }
                
                // Cost
                Text(ingredient.formattedCost)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }
}

// MARK: - Material Add Row
struct MaterialAddRow: View {
    let material: Material
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: material.category.icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(material.name)
                    .font(.subheadline)
                
                Text(material.formattedPricePerUnit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    RecipeBuilderView(product: Product(name: "Test Product"))
        .modelContainer(for: [Material.self, Product.self, Ingredient.self], inMemory: true)
}
