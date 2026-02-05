import SwiftUI
import SwiftData

/// Main content view with tab navigation for Unit Cost Architect
struct ContentView: View {
    @State private var selectedTab: Tab = .inventory
    
    enum Tab: String, CaseIterable {
        case inventory = "Inventory"
        case products = "Products"
        case tools = "Tools"
        case analytics = "Analytics"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .inventory: return "cube.box.fill"
            case .products: return "shippingbox.fill"
            case .tools: return "wrench.and.screwdriver.fill"
            case .analytics: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            InventoryTabView()
                .tabItem {
                    Label(Tab.inventory.rawValue, systemImage: Tab.inventory.icon)
                }
                .tag(Tab.inventory)
            
            ProductCatalogView()
                .tabItem {
                    Label(Tab.products.rawValue, systemImage: Tab.products.icon)
                }
                .tag(Tab.products)
            
            ToolsTabView()
                .tabItem {
                    Label(Tab.tools.rawValue, systemImage: Tab.tools.icon)
                }
                .tag(Tab.tools)
            
            AnalyticsTabView()
                .tabItem {
                    Label(Tab.analytics.rawValue, systemImage: Tab.analytics.icon)
                }
                .tag(Tab.analytics)
            
            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
    }
}

// MARK: - Inventory Tab View
struct InventoryTabView: View {
    var body: some View {
        NavigationStack {
            InventoryView()
                .toolbar {
                    ToolbarItem(placement: .secondaryAction) {
                        Menu {
                            NavigationLink(destination: StockTrackingView()) {
                                Label("Stock Tracking", systemImage: "chart.bar.doc.horizontal")
                            }
                            
                            NavigationLink(destination: SuppliersView()) {
                                Label("Suppliers", systemImage: "building.2")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
        }
    }
}

// MARK: - Tools Tab View
struct ToolsTabView: View {
    var body: some View {
        NavigationStack {
            List {
                // Calculators section
                Section("Calculators") {
                    NavigationLink(destination: QuickCalculatorView()) {
                        ToolRow(
                            icon: "function",
                            title: "Quick Calculator",
                            description: "Fast cost calculations without saving",
                            color: .blue
                        )
                    }
                }
                
                // Analysis tools
                Section("Analysis") {
                    NavigationLink(destination: ComparisonView()) {
                        ToolRow(
                            icon: "arrow.left.arrow.right",
                            title: "Compare Products",
                            description: "Side-by-side product comparison",
                            color: .purple
                        )
                    }
                    
                    NavigationLink(destination: ReportsView()) {
                        ToolRow(
                            icon: "doc.text.fill",
                            title: "Reports & Export",
                            description: "Generate reports and export CSV",
                            color: .green
                        )
                    }
                }
                
                // Templates
                Section("Productivity") {
                    NavigationLink(destination: TemplatesView()) {
                        ToolRow(
                            icon: "doc.on.doc.fill",
                            title: "Templates",
                            description: "Product templates and duplication",
                            color: .orange
                        )
                    }
                    
                    NavigationLink(destination: SuppliersView()) {
                        ToolRow(
                            icon: "building.2.fill",
                            title: "Suppliers",
                            description: "Manage material suppliers",
                            color: .indigo
                        )
                    }
                }
                
                // Inventory
                Section("Inventory") {
                    NavigationLink(destination: StockTrackingView()) {
                        ToolRow(
                            icon: "chart.bar.doc.horizontal.fill",
                            title: "Stock Tracking",
                            description: "Monitor inventory levels and alerts",
                            color: .red
                        )
                    }
                }
            }
            .navigationTitle("Tools")
        }
    }
}

struct ToolRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Analytics Tab View
struct AnalyticsTabView: View {
    var body: some View {
        NavigationStack {
            AnalyticsView()
                .toolbar {
                    ToolbarItem(placement: .secondaryAction) {
                        NavigationLink(destination: ReportsView()) {
                            Label("Reports", systemImage: "doc.text")
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Material.self,
            Labor.self,
            Product.self,
            Ingredient.self,
            AppSettings.self,
            CurrencySettings.self,
            PriceHistory.self,
            Supplier.self,
            ProductTemplate.self,
            ProductNote.self,
            UserPreferences.self
        ], inMemory: true)
}
