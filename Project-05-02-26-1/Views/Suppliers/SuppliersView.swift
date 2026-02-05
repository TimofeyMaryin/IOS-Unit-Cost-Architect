import SwiftUI
import SwiftData

/// Supplier management view
struct SuppliersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Supplier.name) private var suppliers: [Supplier]
    
    @State private var showingAddSupplier = false
    @State private var searchText = ""
    
    var filteredSuppliers: [Supplier] {
        if searchText.isEmpty {
            return suppliers
        }
        return suppliers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if suppliers.isEmpty {
                    emptyState
                } else {
                    suppliersList
                }
            }
            .navigationTitle("Suppliers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSupplier = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search suppliers...")
            .sheet(isPresented: $showingAddSupplier) {
                SupplierEditView(supplier: nil)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Suppliers", systemImage: "building.2")
        } description: {
            Text("Add suppliers to track where your materials come from. Link materials to suppliers for better inventory management.")
        } actions: {
            Button {
                showingAddSupplier = true
            } label: {
                Label("Add Supplier", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Suppliers List
    private var suppliersList: some View {
        List {
            // Summary section
            Section {
                HStack {
                    Label("Total Suppliers", systemImage: "building.2.fill")
                    Spacer()
                    Text("\(suppliers.count)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("Preferred Suppliers", systemImage: "star.fill")
                        .foregroundStyle(.yellow)
                    Spacer()
                    Text("\(suppliers.filter { $0.isPreferred }.count)")
                        .fontWeight(.semibold)
                }
            }
            
            // Suppliers
            Section("All Suppliers") {
                ForEach(filteredSuppliers) { supplier in
                    NavigationLink(destination: SupplierDetailView(supplier: supplier)) {
                        SupplierRowView(supplier: supplier)
                    }
                }
                .onDelete(perform: deleteSuppliers)
            }
        }
    }
    
    private func deleteSuppliers(at offsets: IndexSet) {
        for index in offsets {
            let supplier = filteredSuppliers[index]
            modelContext.delete(supplier)
        }
        try? modelContext.save()
    }
}

// MARK: - Supplier Row View
struct SupplierRowView: View {
    let supplier: Supplier
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Text(supplier.name.prefix(2).uppercased())
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(supplier.name)
                        .font(.headline)
                    
                    if supplier.isPreferred {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(supplier.starRating)
                        .font(.caption)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("\(supplier.materialCount) materials")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supplier Detail View
struct SupplierDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var supplier: Supplier
    
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            // Header
            Section {
                VStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Text(supplier.name.prefix(2).uppercased())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text(supplier.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if supplier.isPreferred {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                        
                        Text(supplier.starRating)
                            .font(.title3)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Contact info
            Section("Contact Information") {
                if !supplier.contactPerson.isEmpty {
                    LabeledContent("Contact Person") {
                        Text(supplier.contactPerson)
                    }
                }
                
                if !supplier.email.isEmpty {
                    Link(destination: URL(string: "mailto:\(supplier.email)")!) {
                        LabeledContent("Email") {
                            Text(supplier.email)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                if !supplier.phone.isEmpty {
                    Link(destination: URL(string: "tel:\(supplier.phone)")!) {
                        LabeledContent("Phone") {
                            Text(supplier.phone)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                if !supplier.website.isEmpty {
                    Link(destination: URL(string: supplier.website) ?? URL(string: "https://example.com")!) {
                        LabeledContent("Website") {
                            Text(supplier.website)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                if !supplier.address.isEmpty {
                    LabeledContent("Address") {
                        Text(supplier.address)
                    }
                }
            }
            
            // Rating
            Section("Rating") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate this supplier")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                supplier.rating = star
                                try? modelContext.save()
                            } label: {
                                Image(systemName: star <= supplier.rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(star <= supplier.rating ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Toggle("Preferred Supplier", isOn: $supplier.isPreferred)
                    .onChange(of: supplier.isPreferred) {
                        try? modelContext.save()
                    }
            }
            
            // Materials from this supplier
            if let materials = supplier.materials, !materials.isEmpty {
                Section("Materials (\(materials.count))") {
                    ForEach(materials) { material in
                        HStack {
                            Image(systemName: material.category.icon)
                                .foregroundStyle(.blue)
                            
                            Text(material.name)
                            
                            Spacer()
                            
                            Text(material.formattedPricePerUnit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Notes
            if !supplier.notes.isEmpty {
                Section("Notes") {
                    Text(supplier.notes)
                }
            }
        }
        .navigationTitle("Supplier")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            SupplierEditView(supplier: supplier)
        }
    }
}

// MARK: - Supplier Edit View
struct SupplierEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let supplier: Supplier?
    
    @State private var name = ""
    @State private var contactPerson = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var website = ""
    @State private var notes = ""
    @State private var rating = 3
    @State private var isPreferred = false
    
    private var isEditing: Bool { supplier != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Company Name", text: $name)
                    TextField("Contact Person", text: $contactPerson)
                }
                
                Section("Contact") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Rating") {
                    Picker("Rating", selection: $rating) {
                        ForEach(1...5, id: \.self) { stars in
                            Text(String(repeating: "★", count: stars)).tag(stars)
                        }
                    }
                    
                    Toggle("Preferred Supplier", isOn: $isPreferred)
                }
                
                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Supplier" : "New Supplier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSupplier()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let supplier = supplier {
                    name = supplier.name
                    contactPerson = supplier.contactPerson
                    email = supplier.email
                    phone = supplier.phone
                    address = supplier.address
                    website = supplier.website
                    notes = supplier.notes
                    rating = supplier.rating
                    isPreferred = supplier.isPreferred
                }
            }
        }
    }
    
    private func saveSupplier() {
        if let supplier = supplier {
            supplier.name = name
            supplier.contactPerson = contactPerson
            supplier.email = email
            supplier.phone = phone
            supplier.address = address
            supplier.website = website
            supplier.notes = notes
            supplier.rating = rating
            supplier.isPreferred = isPreferred
            supplier.updatedAt = Date()
        } else {
            let newSupplier = Supplier(
                name: name,
                contactPerson: contactPerson,
                email: email,
                phone: phone,
                address: address,
                website: website,
                notes: notes,
                rating: rating,
                isPreferred: isPreferred
            )
            modelContext.insert(newSupplier)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    SuppliersView()
        .modelContainer(for: [Supplier.self, Material.self], inMemory: true)
}
