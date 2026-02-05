import SwiftUI
import SwiftData

/// Detailed product view with recipe builder and pricing strategy
struct ProductDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var laborSettings: [Labor]
    
    @Bindable var product: Product
    
    @State private var showingEditSheet = false
    @State private var showingRecipeBuilder = false
    @State private var showingExportSheet = false
    @State private var showingDeleteAlert = false
    @State private var recalculationFeedback = false
    
    private var hourlyRate: Double {
        laborSettings.first?.hourlyRate ?? 15.0
    }
    
    var body: some View {
        List {
            // Header
            productHeader
            
            // Cost breakdown
            costBreakdownSection
            
            // Pricing strategy with sliders
            pricingStrategySection
            
            // Profit analysis
            profitAnalysisSection
            
            // Ingredients/Recipe
            ingredientsSection
            
            // Advanced tools
            advancedToolsSection
            
            // Actions
            actionsSection
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Product", systemImage: "pencil")
                    }
                    
                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ProductEditView(product: product)
        }
        .sheet(isPresented: $showingRecipeBuilder) {
            RecipeBuilderView(product: product)
        }
        .sheet(isPresented: $showingExportSheet) {
            PDFExportView(product: product, hourlyRate: hourlyRate)
        }
        .alert("Delete Product?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(product)
                try? modelContext.save()
            }
        } message: {
            Text("This will permanently delete this product and its recipe.")
        }
        .sensoryFeedback(.success, trigger: recalculationFeedback)
    }
    
    // MARK: - Header Section
    private var productHeader: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: product.iconName)
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !product.productDescription.isEmpty {
                        Text(product.productDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Label("\(product.ingredientCount)", systemImage: "list.bullet")
                        Label(product.formattedTimeToProduce, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Cost Breakdown Section
    private var costBreakdownSection: some View {
        Section("Cost Breakdown") {
            CostRow(
                title: "Material Cost",
                value: product.materialCost,
                icon: "cube.box.fill",
                color: .blue
            )
            
            CostRow(
                title: "Labor Cost",
                value: product.laborCost(hourlyRate: hourlyRate),
                icon: "person.fill",
                color: .orange,
                subtitle: "\(product.formattedTimeToProduce) × $\(String(format: "%.2f", hourlyRate))/hr"
            )
            
            CostRow(
                title: "Prime Cost",
                value: product.primeCost(hourlyRate: hourlyRate),
                icon: "equal.circle.fill",
                color: .green,
                isHighlighted: true
            )
            
            CostRow(
                title: "Overhead (+\(String(format: "%.0f", product.overheadPercentage))%)",
                value: product.totalCost(hourlyRate: hourlyRate) - product.primeCost(hourlyRate: hourlyRate),
                icon: "building.2.fill",
                color: .purple
            )
            
            CostRow(
                title: "Total Cost",
                value: product.totalCost(hourlyRate: hourlyRate),
                icon: "sum",
                color: .indigo,
                isHighlighted: true
            )
        }
    }
    
    // MARK: - Pricing Strategy Section
    private var pricingStrategySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Overhead slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Overhead", systemImage: "building.2.fill")
                        Spacer()
                        Text("\(Int(product.overheadPercentage))%")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                    
                    Slider(value: $product.overheadPercentage, in: 0...100, step: 1) { editing in
                        if !editing {
                            product.updatedAt = Date()
                            try? modelContext.save()
                            recalculationFeedback.toggle()
                        }
                    }
                    .tint(.purple)
                }
                
                Divider()
                
                // Markup slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Markup", systemImage: "percent")
                        Spacer()
                        Text("\(Int(product.markupPercentage))%")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                    
                    Slider(value: $product.markupPercentage, in: 0...200, step: 1) { editing in
                        if !editing {
                            product.updatedAt = Date()
                            try? modelContext.save()
                            recalculationFeedback.toggle()
                        }
                    }
                    .tint(.green)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Pricing Strategy")
        } footer: {
            Text("Adjust overhead and markup to calculate the final selling price.")
        }
    }
    
    // MARK: - Profit Analysis Section
    private var profitAnalysisSection: some View {
        Section("Profit Analysis") {
            // Final Price
            HStack {
                VStack(alignment: .leading) {
                    Text("Final Price")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(product.finalPrice(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Net Profit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(product.netProfit(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 8)
            
            // Profit margin gauge
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Profit Margin")
                    Spacer()
                    Text(String(format: "%.1f%%", product.profitMargin(hourlyRate: hourlyRate)))
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(marginColor)
                            .frame(width: geo.size.width * min(product.profitMargin(hourlyRate: hourlyRate) / 100, 1))
                    }
                }
                .frame(height: 8)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var marginColor: Color {
        let margin = product.profitMargin(hourlyRate: hourlyRate)
        if margin < 10 { return .red }
        if margin < 20 { return .orange }
        if margin < 30 { return .yellow }
        return .green
    }
    
    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        Section {
            if product.hasIngredients {
                ForEach(product.ingredients ?? []) { ingredient in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(ingredient.displayName)
                                .font(.subheadline)
                            Text(String(format: "%.2f", ingredient.amountRequired) + " " + ingredient.unitSymbol)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(ingredient.formattedCost)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("No Ingredients", systemImage: "list.bullet")
                } description: {
                    Text("Add materials to calculate costs")
                }
            }
            
            Button {
                showingRecipeBuilder = true
            } label: {
                Label(product.hasIngredients ? "Edit Recipe" : "Add Ingredients", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text("Recipe / BOM")
                Spacer()
                Text("\(product.ingredientCount) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Advanced Tools Section
    private var advancedToolsSection: some View {
        Section("Advanced Tools") {
            NavigationLink(destination: BatchCalculatorView(product: product)) {
                ToolLinkRow(
                    title: "Batch Calculator",
                    description: "Calculate costs for 10, 100, 1000+ units",
                    icon: "square.grid.3x3.fill",
                    color: .blue
                )
            }
            
            NavigationLink(destination: BreakEvenView(product: product)) {
                ToolLinkRow(
                    title: "Break-Even Analysis",
                    description: "Find out how many units to sell to profit",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
            
            NavigationLink(destination: ScenarioView(product: product)) {
                ToolLinkRow(
                    title: "What-If Scenarios",
                    description: "Simulate material and labor price changes",
                    icon: "questionmark.circle.fill",
                    color: .orange
                )
            }
            
            NavigationLink(destination: ProductNotesView(product: product)) {
                HStack {
                    ToolLinkRow(
                        title: "Notes & Attachments",
                        description: "Add production notes and reminders",
                        icon: "note.text",
                        color: .purple
                    )
                    
                    if let noteCount = product.notes?.count, noteCount > 0 {
                        Text("\(noteCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        Section {
            Button {
                showingExportSheet = true
            } label: {
                Label("Export Technical Map (PDF)", systemImage: "doc.fill")
            }
            
            Button {
                duplicateProduct()
            } label: {
                Label("Duplicate Product", systemImage: "doc.on.doc")
            }
        }
    }
    
    private func duplicateProduct() {
        let newProduct = product.duplicate()
        modelContext.insert(newProduct)
        
        // Duplicate ingredients
        if let ingredients = product.ingredients {
            for ingredient in ingredients {
                let newIngredient = Ingredient(
                    amountRequired: ingredient.amountRequired,
                    material: ingredient.material,
                    product: newProduct
                )
                modelContext.insert(newIngredient)
            }
        }
        
        try? modelContext.save()
    }
}

// MARK: - Tool Link Row Component
struct ToolLinkRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Cost Row Component
struct CostRow: View {
    let title: String
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
                Text(title)
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
                .fontWeight(isHighlighted ? .bold : .medium)
                .foregroundStyle(isHighlighted ? color : .primary)
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: Product(
            name: "Custom Widget",
            productDescription: "A beautifully crafted widget",
            markupPercentage: 40,
            overheadPercentage: 15,
            timeToProduce: 2.5
        ))
    }
    .modelContainer(for: [Material.self, Labor.self, Product.self, Ingredient.self], inMemory: true)
}
