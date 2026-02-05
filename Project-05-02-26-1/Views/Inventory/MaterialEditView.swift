import SwiftUI
import SwiftData

/// Form view for creating or editing a material
struct MaterialEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let material: Material?
    
    @State private var name: String = ""
    @State private var category: MaterialCategory = .rawMaterial
    @State private var bulkPrice: Double = 0
    @State private var bulkAmount: Double = 1
    @State private var unitType: UnitType = .kg
    
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    private var isEditing: Bool {
        material != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Material Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Category", selection: $category) {
                        ForEach(MaterialCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }
                
                Section("Pricing") {
                    HStack {
                        Text("Bulk Price")
                        Spacer()
                        TextField("Price", value: $bulkPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Bulk Amount")
                        Spacer()
                        TextField("Amount", value: $bulkAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(unitType.symbol)
                            .foregroundStyle(.secondary)
                    }
                    
                    Picker("Unit Type", selection: $unitType) {
                        ForEach(UnitType.allCases, id: \.self) { unit in
                            Text("\(unit.displayName) (\(unit.symbol))").tag(unit)
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculated Unit Price")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "equal.circle.fill")
                                .foregroundStyle(.green)
                            Text(calculatedUnitPrice)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                } footer: {
                    Text("This is the price per single unit (\(unitType.symbol)) that will be used in cost calculations.")
                }
            }
            .navigationTitle(isEditing ? "Edit Material" : "New Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveMaterial()
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
                if let material = material {
                    name = material.name
                    category = material.category
                    bulkPrice = material.bulkPrice
                    bulkAmount = material.bulkAmount
                    unitType = material.unitType
                }
            }
        }
    }
    
    private var calculatedUnitPrice: String {
        guard bulkAmount > 0 else { return "$0.0000/\(unitType.symbol)" }
        let unitPrice = bulkPrice / bulkAmount
        return String(format: "$%.4f/%@", unitPrice, unitType.symbol)
    }
    
    private func saveMaterial() {
        // Validation
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Please enter a material name."
            showingValidationAlert = true
            return
        }
        
        guard bulkAmount > 0 else {
            validationMessage = "Bulk amount must be greater than 0."
            showingValidationAlert = true
            return
        }
        
        if let material = material {
            // Update existing
            material.name = name.trimmingCharacters(in: .whitespaces)
            material.category = category
            material.bulkPrice = bulkPrice
            material.bulkAmount = bulkAmount
            material.unitType = unitType
            material.updatedAt = Date()
        } else {
            // Create new
            let newMaterial = Material(
                name: name.trimmingCharacters(in: .whitespaces),
                category: category,
                bulkPrice: bulkPrice,
                bulkAmount: bulkAmount,
                unitType: unitType
            )
            modelContext.insert(newMaterial)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview("New Material") {
    MaterialEditView(material: nil)
        .modelContainer(for: Material.self, inMemory: true)
}
