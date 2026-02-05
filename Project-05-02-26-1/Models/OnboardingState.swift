import Foundation
import SwiftData

/// Onboarding and app state tracking
@Model
final class UserPreferences {
    var id: UUID
    var hasCompletedOnboarding: Bool
    var selectedCurrency: CurrencyCode
    var defaultMarkup: Double
    var defaultOverhead: Double
    var showLowStockWarnings: Bool
    var lowStockThreshold: Double // percentage
    var createdAt: Date
    var lastOpenedAt: Date
    
    // Favorites
    var favoriteMaterialIds: [UUID]
    var favoriteProductIds: [UUID]
    
    init(
        id: UUID = UUID(),
        hasCompletedOnboarding: Bool = false,
        selectedCurrency: CurrencyCode = .usd,
        defaultMarkup: Double = 30.0,
        defaultOverhead: Double = 15.0,
        showLowStockWarnings: Bool = true,
        lowStockThreshold: Double = 20.0
    ) {
        self.id = id
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedCurrency = selectedCurrency
        self.defaultMarkup = defaultMarkup
        self.defaultOverhead = defaultOverhead
        self.showLowStockWarnings = showLowStockWarnings
        self.lowStockThreshold = lowStockThreshold
        self.createdAt = Date()
        self.lastOpenedAt = Date()
        self.favoriteMaterialIds = []
        self.favoriteProductIds = []
    }
    
    /// Check if material is favorite
    func isFavorite(materialId: UUID) -> Bool {
        favoriteMaterialIds.contains(materialId)
    }
    
    /// Check if product is favorite
    func isFavorite(productId: UUID) -> Bool {
        favoriteProductIds.contains(productId)
    }
    
    /// Toggle material favorite
    func toggleFavorite(materialId: UUID) {
        if let index = favoriteMaterialIds.firstIndex(of: materialId) {
            favoriteMaterialIds.remove(at: index)
        } else {
            favoriteMaterialIds.append(materialId)
        }
    }
    
    /// Toggle product favorite
    func toggleFavorite(productId: UUID) {
        if let index = favoriteProductIds.firstIndex(of: productId) {
            favoriteProductIds.remove(at: index)
        } else {
            favoriteProductIds.append(productId)
        }
    }
}

/// Onboarding page content
struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let color: String
    
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Unit Cost Architect",
            description: "The professional tool for calculating product costs, managing inventory, and maximizing your profit margins.",
            imageName: "building.columns.fill",
            color: "blue"
        ),
        OnboardingPage(
            title: "Manage Your Inventory",
            description: "Track raw materials, set prices, and organize by categories. Price changes automatically update all linked products.",
            imageName: "cube.box.fill",
            color: "orange"
        ),
        OnboardingPage(
            title: "Build Product Recipes",
            description: "Create detailed bills of materials (BOM) for each product. Add ingredients from your inventory with precise quantities.",
            imageName: "list.clipboard.fill",
            color: "green"
        ),
        OnboardingPage(
            title: "Calculate True Costs",
            description: "Automatic calculation of prime cost, overhead, labor, and final pricing. Adjust markup and see profit in real-time.",
            imageName: "function",
            color: "purple"
        ),
        OnboardingPage(
            title: "Analyze & Export",
            description: "Visualize your data with charts, compare products, track price history, and export professional PDF reports.",
            imageName: "chart.bar.xaxis",
            color: "pink"
        )
    ]
}
