import SwiftUI
import SwiftData

/// Templates management and product duplication view
struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProductTemplate.name) private var templates: [ProductTemplate]
    @Query(sort: \Product.name) private var products: [Product]
    @Query(sort: \Material.name) private var materials: [Material]
    
    @State private var showingCreateFromProduct = false
    @State private var selectedProduct: Product?
    @State private var showingUseTemplate = false
    @State private var selectedTemplate: ProductTemplate?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick actions
                quickActionsSection
                
                // Templates list
                templatesSection
                
                // Products for duplication
                productsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreateFromProduct) {
            if let product = selectedProduct {
                CreateTemplateSheet(product: product)
            }
        }
        .sheet(isPresented: $showingUseTemplate) {
            if let template = selectedTemplate {
                UseTemplateSheet(template: template, materials: materials)
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "New Template",
                    icon: "doc.badge.plus",
                    color: .blue
                ) {
                    if let firstProduct = products.first {
                        selectedProduct = firstProduct
                        showingCreateFromProduct = true
                    }
                }
                .disabled(products.isEmpty)
                
                QuickActionButton(
                    title: "Use Template",
                    icon: "doc.on.doc.fill",
                    color: .green
                ) {
                    if let firstTemplate = templates.first {
                        selectedTemplate = firstTemplate
                        showingUseTemplate = true
                    }
                }
                .disabled(templates.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Templates Section
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Templates")
                    .font(.headline)
                Spacer()
                Text("\(templates.count) templates")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if templates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.doc")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    
                    Text("No templates yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Create a template from an existing product to quickly create similar products.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(templates) { template in
                    TemplateCard(template: template) {
                        selectedTemplate = template
                        showingUseTemplate = true
                    } onDelete: {
                        modelContext.delete(template)
                        try? modelContext.save()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Products Section
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Template From Product")
                .font(.headline)
            
            if products.isEmpty {
                Text("No products available. Create a product first.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(products) { product in
                    ProductTemplateRow(product: product) {
                        selectedProduct = product
                        showingCreateFromProduct = true
                    } onDuplicate: {
                        duplicateProduct(product)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func duplicateProduct(_ product: Product) {
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

// MARK: - Supporting Views
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct TemplateCard: View {
    let template: ProductTemplate
    let onUse: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: template.iconName)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                    
                    Text("\(template.ingredientData.count) ingredients • Used \(template.usageCount)x")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button {
                        onUse()
                    } label: {
                        Label("Use Template", systemImage: "plus.circle")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Template details
            HStack(spacing: 16) {
                DetailChip(label: "Markup", value: "\(Int(template.defaultMarkupPercentage))%")
                DetailChip(label: "Overhead", value: "\(Int(template.defaultOverheadPercentage))%")
                DetailChip(label: "Time", value: String(format: "%.1fh", template.defaultTimeToProduce))
            }
            
            Button {
                onUse()
            } label: {
                Label("Create Product from Template", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailChip: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct ProductTemplateRow: View {
    let product: Product
    let onCreateTemplate: () -> Void
    let onDuplicate: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: product.iconName)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.subheadline)
                
                Text("\(product.ingredientCount) ingredients")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                onCreateTemplate()
            } label: {
                Label("Template", systemImage: "doc.badge.plus")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Create Template Sheet
struct CreateTemplateSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let product: Product
    
    @State private var templateName: String = ""
    @State private var templateDescription: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Info") {
                    TextField("Template Name", text: $templateName)
                    TextField("Description", text: $templateDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("From Product") {
                    LabeledContent("Product") {
                        Text(product.name)
                    }
                    LabeledContent("Ingredients") {
                        Text("\(product.ingredientCount)")
                    }
                    LabeledContent("Markup") {
                        Text("\(Int(product.markupPercentage))%")
                    }
                    LabeledContent("Overhead") {
                        Text("\(Int(product.overheadPercentage))%")
                    }
                }
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTemplate()
                    }
                    .disabled(templateName.isEmpty)
                }
            }
            .onAppear {
                templateName = "\(product.name) Template"
            }
        }
    }
    
    private func createTemplate() {
        let template = ProductTemplate.from(product: product)
        template.name = templateName
        template.templateDescription = templateDescription
        
        modelContext.insert(template)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Use Template Sheet
struct UseTemplateSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let template: ProductTemplate
    let materials: [Material]
    
    @State private var productName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("New Product") {
                    TextField("Product Name", text: $productName)
                }
                
                Section("Template Settings") {
                    LabeledContent("Markup") {
                        Text("\(Int(template.defaultMarkupPercentage))%")
                    }
                    LabeledContent("Overhead") {
                        Text("\(Int(template.defaultOverheadPercentage))%")
                    }
                    LabeledContent("Production Time") {
                        Text(String(format: "%.1f hours", template.defaultTimeToProduce))
                    }
                }
                
                Section("Ingredients (\(template.ingredientData.count))") {
                    ForEach(template.ingredientData, id: \.materialId) { ingredient in
                        HStack {
                            Text(ingredient.materialName)
                            Spacer()
                            Text(String(format: "%.2f", ingredient.amountRequired))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Use Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProduct()
                    }
                    .disabled(productName.isEmpty)
                }
            }
        }
    }
    
    private func createProduct() {
        let product = Product(
            name: productName,
            markupPercentage: template.defaultMarkupPercentage,
            overheadPercentage: template.defaultOverheadPercentage,
            timeToProduce: template.defaultTimeToProduce,
            iconName: template.iconName
        )
        
        modelContext.insert(product)
        
        // Add ingredients
        for ingredientData in template.ingredientData {
            if let material = materials.first(where: { $0.id == ingredientData.materialId }) {
                let ingredient = Ingredient(
                    amountRequired: ingredientData.amountRequired,
                    material: material,
                    product: product
                )
                modelContext.insert(ingredient)
            }
        }
        
        // Update template usage count
        template.usageCount += 1
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        TemplatesView()
    }
    .modelContainer(for: [ProductTemplate.self, Product.self, Material.self], inMemory: true)
}
