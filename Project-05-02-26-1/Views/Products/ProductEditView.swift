import SwiftUI
import SwiftData

/// Form for creating or editing a product
struct ProductEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let product: Product?
    
    @State private var name: String = ""
    @State private var productDescription: String = ""
    @State private var markupPercentage: Double = 30.0
    @State private var overheadPercentage: Double = 15.0
    @State private var timeToProduce: Double = 1.0
    @State private var iconName: String = "shippingbox.fill"
    
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    private var isEditing: Bool {
        product != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Product Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (optional)", text: $productDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 44)), count: 5), spacing: 12) {
                        ForEach(Product.availableIcons, id: \.self) { icon in
                            Button {
                                iconName = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(iconName == icon ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                                    .foregroundStyle(iconName == icon ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Production") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Time to Produce")
                            Spacer()
                            Text(formattedTime)
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $timeToProduce, in: 0.1...24, step: 0.1)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Overhead")
                            Spacer()
                            Text("\(Int(overheadPercentage))%")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $overheadPercentage, in: 0...100, step: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Markup")
                            Spacer()
                            Text("\(Int(markupPercentage))%")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $markupPercentage, in: 0...200, step: 1)
                    }
                } header: {
                    Text("Default Pricing Strategy")
                } footer: {
                    Text("You can adjust these values later in the Pricing Strategy dashboard.")
                }
            }
            .navigationTitle(isEditing ? "Edit Product" : "New Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveProduct()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                if let product = product {
                    name = product.name
                    productDescription = product.productDescription
                    markupPercentage = product.markupPercentage
                    overheadPercentage = product.overheadPercentage
                    timeToProduce = product.timeToProduce
                    iconName = product.iconName
                }
            }
        }
    }
    
    private var formattedTime: String {
        if timeToProduce < 1 {
            return String(format: "%.0f minutes", timeToProduce * 60)
        } else if timeToProduce == 1 {
            return "1 hour"
        } else {
            return String(format: "%.1f hours", timeToProduce)
        }
    }
    
    private func saveProduct() {
        // Validation
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Please enter a product name."
            showingValidationAlert = true
            return
        }
        
        if let product = product {
            // Update existing
            product.name = name.trimmingCharacters(in: .whitespaces)
            product.productDescription = productDescription
            product.markupPercentage = markupPercentage
            product.overheadPercentage = overheadPercentage
            product.timeToProduce = timeToProduce
            product.iconName = iconName
            product.updatedAt = Date()
        } else {
            // Create new
            let newProduct = Product(
                name: name.trimmingCharacters(in: .whitespaces),
                productDescription: productDescription,
                markupPercentage: markupPercentage,
                overheadPercentage: overheadPercentage,
                timeToProduce: timeToProduce,
                iconName: iconName
            )
            modelContext.insert(newProduct)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ProductEditView(product: nil)
        .modelContainer(for: Product.self, inMemory: true)
}
