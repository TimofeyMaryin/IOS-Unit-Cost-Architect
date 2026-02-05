import SwiftUI
import SwiftData

/// Product catalog showing all products with cost summary
struct ProductCatalogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]
    @Query private var laborSettings: [Labor]
    
    @State private var searchText = ""
    @State private var showingAddProduct = false
    @State private var viewMode: ViewMode = .grid
    
    enum ViewMode {
        case grid, list
    }
    
    private var hourlyRate: Double {
        laborSettings.first?.hourlyRate ?? 15.0
    }
    
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return products
        }
        return products.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) 
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    EmptyProductsView(showingAddProduct: $showingAddProduct)
                } else {
                    VStack(spacing: 0) {
                        // Stats bar
                        statsBar
                        
                        // Products grid/list
                        if viewMode == .grid {
                            productGrid
                        } else {
                            productList
                        }
                    }
                }
            }
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddProduct = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Picker("View Mode", selection: $viewMode) {
                            Label("Grid", systemImage: "square.grid.2x2").tag(ViewMode.grid)
                            Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                        }
                    } label: {
                        Image(systemName: viewMode == .grid ? "square.grid.2x2" : "list.bullet")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search products...")
            .sheet(isPresented: $showingAddProduct) {
                ProductEditView(product: nil)
            }
        }
    }
    
    private var statsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Products",
                    value: "\(products.count)",
                    icon: "shippingbox.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Avg. Prime Cost",
                    value: averagePrimeCost.formatted(.currency(code: "USD")),
                    icon: "dollarsign.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Total Potential Revenue",
                    value: totalPotentialRevenue.formatted(.currency(code: "USD")),
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    color: .green
                )
            }
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    private var productGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredProducts) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        ProductCardView(product: product, hourlyRate: hourlyRate)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    private var productList: some View {
        List {
            ForEach(filteredProducts) { product in
                NavigationLink(destination: ProductDetailView(product: product)) {
                    ProductRowView(product: product, hourlyRate: hourlyRate)
                }
            }
            .onDelete(perform: deleteProducts)
        }
        .listStyle(.plain)
    }
    
    private var averagePrimeCost: Double {
        guard !products.isEmpty else { return 0 }
        let total = products.reduce(0) { $0 + $1.primeCost(hourlyRate: hourlyRate) }
        return total / Double(products.count)
    }
    
    private var totalPotentialRevenue: Double {
        products.reduce(0) { $0 + $1.finalPrice(hourlyRate: hourlyRate) }
    }
    
    private func deleteProducts(at offsets: IndexSet) {
        for index in offsets {
            let product = filteredProducts[index]
            modelContext.delete(product)
        }
        try? modelContext.save()
    }
}

// MARK: - Product Card View
struct ProductCardView: View {
    let product: Product
    let hourlyRate: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: product.iconName)
                .font(.system(size: 40))
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
            
            // Name
            Text(product.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Ingredients count
            HStack(spacing: 4) {
                Image(systemName: "list.bullet")
                    .font(.caption2)
                Text("\(product.ingredientCount) ingredients")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            Divider()
            
            // Prime cost
            VStack(spacing: 2) {
                Text("Prime Cost")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(product.primeCost(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Product Row View
struct ProductRowView: View {
    let product: Product
    let hourlyRate: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: product.iconName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                
                Text("\(product.ingredientCount) ingredients • \(product.formattedTimeToProduce)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(product.primeCost(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Prime Cost")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Empty State
struct EmptyProductsView: View {
    @Binding var showingAddProduct: Bool
    
    var body: some View {
        ContentUnavailableView {
            Label("No Products", systemImage: "shippingbox")
        } description: {
            Text("Create your first product to start calculating costs. Add materials from your inventory to build the recipe.")
        } actions: {
            Button {
                showingAddProduct = true
            } label: {
                Label("Create Product", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ProductCatalogView()
        .modelContainer(for: [Material.self, Labor.self, Product.self, Ingredient.self, AppSettings.self], inMemory: true)
}
