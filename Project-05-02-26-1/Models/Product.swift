import Foundation
import SwiftData

/// Product model representing finished goods with cost calculations
@Model
final class Product {
    var id: UUID
    var name: String
    var productDescription: String
    var markupPercentage: Double
    var overheadPercentage: Double
    var timeToProduce: Double // in hours
    var iconName: String
    var createdAt: Date
    var updatedAt: Date
    
    // NEW: Category for organization (with default for migration)
    var category: String = "General"
    
    // NEW: Break-even tracking (with defaults for migration)
    var fixedCosts: Double = 0 // One-time costs (tooling, setup, etc.)
    var targetUnitsPerMonth: Int = 100
    
    // NEW: Batch production defaults (with default for migration)
    var defaultBatchSize: Int = 1
    
    /// Ingredients list (one-to-many relationship)
    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]?
    
    /// NEW: Notes attached to product
    @Relationship(deleteRule: .cascade, inverse: \ProductNote.product)
    var notes: [ProductNote]?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        productDescription: String = "",
        markupPercentage: Double = 30.0,
        overheadPercentage: Double = 15.0,
        timeToProduce: Double = 1.0,
        iconName: String = "shippingbox.fill",
        category: String = "General",
        fixedCosts: Double = 0,
        targetUnitsPerMonth: Int = 100,
        defaultBatchSize: Int = 1
    ) {
        self.id = id
        self.name = name
        self.productDescription = productDescription
        self.markupPercentage = markupPercentage
        self.overheadPercentage = overheadPercentage
        self.timeToProduce = timeToProduce
        self.iconName = iconName
        self.category = category
        self.fixedCosts = fixedCosts
        self.targetUnitsPerMonth = targetUnitsPerMonth
        self.defaultBatchSize = defaultBatchSize
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Total material cost from all ingredients
    var materialCost: Double {
        (ingredients ?? []).reduce(0) { $0 + $1.cost }
    }
    
    /// Calculate labor cost with given hourly rate
    func laborCost(hourlyRate: Double) -> Double {
        timeToProduce * hourlyRate
    }
    
    /// Prime Cost = Material Cost + Labor Cost
    func primeCost(hourlyRate: Double) -> Double {
        materialCost + laborCost(hourlyRate: hourlyRate)
    }
    
    /// Total Cost = Prime Cost × (1 + Overhead%)
    func totalCost(hourlyRate: Double) -> Double {
        primeCost(hourlyRate: hourlyRate) * (1 + overheadPercentage / 100)
    }
    
    /// Final Price = Total Cost × (1 + Markup%)
    func finalPrice(hourlyRate: Double) -> Double {
        totalCost(hourlyRate: hourlyRate) * (1 + markupPercentage / 100)
    }
    
    /// Net Profit = Final Price - Total Cost
    func netProfit(hourlyRate: Double) -> Double {
        finalPrice(hourlyRate: hourlyRate) - totalCost(hourlyRate: hourlyRate)
    }
    
    /// Profit margin percentage
    func profitMargin(hourlyRate: Double) -> Double {
        let price = finalPrice(hourlyRate: hourlyRate)
        guard price > 0 else { return 0 }
        return (netProfit(hourlyRate: hourlyRate) / price) * 100
    }
    
    /// Number of ingredients
    var ingredientCount: Int {
        ingredients?.count ?? 0
    }
    
    /// Check if product has valid ingredients
    var hasIngredients: Bool {
        ingredientCount > 0
    }
    
    /// Formatted time to produce
    var formattedTimeToProduce: String {
        if timeToProduce < 1 {
            return String(format: "%.0f min", timeToProduce * 60)
        } else if timeToProduce == 1 {
            return "1 hour"
        } else {
            return String(format: "%.1f hours", timeToProduce)
        }
    }
    
    // MARK: - Batch Production Calculations
    
    /// Calculate costs for a batch
    func batchCost(quantity: Int, hourlyRate: Double) -> BatchCalculation {
        let unitPrime = primeCost(hourlyRate: hourlyRate)
        let unitTotal = totalCost(hourlyRate: hourlyRate)
        let unitFinal = finalPrice(hourlyRate: hourlyRate)
        let unitProfit = netProfit(hourlyRate: hourlyRate)
        
        // Batch discounts (economies of scale)
        let scaleDiscount: Double
        if quantity >= 1000 {
            scaleDiscount = 0.15 // 15% savings
        } else if quantity >= 100 {
            scaleDiscount = 0.10 // 10% savings
        } else if quantity >= 10 {
            scaleDiscount = 0.05 // 5% savings
        } else {
            scaleDiscount = 0
        }
        
        let batchMaterialCost = materialCost * Double(quantity) * (1 - scaleDiscount)
        let batchLaborCost = laborCost(hourlyRate: hourlyRate) * Double(quantity)
        let batchPrimeCost = batchMaterialCost + batchLaborCost
        let batchTotalCost = batchPrimeCost * (1 + overheadPercentage / 100)
        let batchFinalPrice = batchTotalCost * (1 + markupPercentage / 100)
        let batchProfit = batchFinalPrice - batchTotalCost
        
        return BatchCalculation(
            quantity: quantity,
            unitPrimeCost: unitPrime,
            unitTotalCost: unitTotal,
            unitFinalPrice: unitFinal,
            unitProfit: unitProfit,
            batchPrimeCost: batchPrimeCost,
            batchTotalCost: batchTotalCost,
            batchFinalPrice: batchFinalPrice,
            batchProfit: batchProfit,
            scaleDiscount: scaleDiscount,
            totalProductionTime: timeToProduce * Double(quantity)
        )
    }
    
    // MARK: - Break-Even Analysis
    
    /// Calculate break-even point
    func breakEvenAnalysis(hourlyRate: Double) -> BreakEvenResult {
        let unitTotal = totalCost(hourlyRate: hourlyRate)
        let unitPrice = finalPrice(hourlyRate: hourlyRate)
        let unitProfit = netProfit(hourlyRate: hourlyRate)
        
        // Contribution margin per unit
        let contributionMargin = unitPrice - unitTotal
        
        // Break-even units (to cover fixed costs)
        let breakEvenUnits: Int
        if contributionMargin > 0 {
            breakEvenUnits = Int(ceil(fixedCosts / contributionMargin))
        } else {
            breakEvenUnits = 0
        }
        
        // Break-even revenue
        let breakEvenRevenue = Double(breakEvenUnits) * unitPrice
        
        // Profit at target volume
        let profitAtTarget = (Double(targetUnitsPerMonth) * contributionMargin) - fixedCosts
        
        // Safety margin (how much sales can drop before loss)
        let safetyMargin: Double
        if targetUnitsPerMonth > breakEvenUnits {
            safetyMargin = Double(targetUnitsPerMonth - breakEvenUnits) / Double(targetUnitsPerMonth) * 100
        } else {
            safetyMargin = 0
        }
        
        return BreakEvenResult(
            breakEvenUnits: breakEvenUnits,
            breakEvenRevenue: breakEvenRevenue,
            contributionMargin: contributionMargin,
            fixedCosts: fixedCosts,
            profitAtTarget: profitAtTarget,
            targetUnits: targetUnitsPerMonth,
            safetyMarginPercent: safetyMargin
        )
    }
    
    // MARK: - Scenario Planning
    
    /// Calculate impact of material price change
    func scenarioAnalysis(materialPriceChange: Double, laborRateChange: Double, hourlyRate: Double) -> ScenarioResult {
        let currentPrime = primeCost(hourlyRate: hourlyRate)
        let currentFinal = finalPrice(hourlyRate: hourlyRate)
        let currentProfit = netProfit(hourlyRate: hourlyRate)
        
        // Calculate new costs with changes
        let newMaterialCost = materialCost * (1 + materialPriceChange / 100)
        let newLaborCost = laborCost(hourlyRate: hourlyRate * (1 + laborRateChange / 100))
        let newPrimeCost = newMaterialCost + newLaborCost
        let newTotalCost = newPrimeCost * (1 + overheadPercentage / 100)
        let newFinalPrice = newTotalCost * (1 + markupPercentage / 100)
        let newProfit = newFinalPrice - newTotalCost
        
        return ScenarioResult(
            originalPrimeCost: currentPrime,
            originalFinalPrice: currentFinal,
            originalProfit: currentProfit,
            newPrimeCost: newPrimeCost,
            newFinalPrice: newFinalPrice,
            newProfit: newProfit,
            primeChange: newPrimeCost - currentPrime,
            priceChange: newFinalPrice - currentFinal,
            profitChange: newProfit - currentProfit,
            profitChangePercent: currentProfit > 0 ? ((newProfit - currentProfit) / currentProfit) * 100 : 0
        )
    }
    
    // MARK: - Duplicate
    
    /// Create a copy of this product
    func duplicate() -> Product {
        Product(
            name: "\(name) (Copy)",
            productDescription: productDescription,
            markupPercentage: markupPercentage,
            overheadPercentage: overheadPercentage,
            timeToProduce: timeToProduce,
            iconName: iconName,
            category: category,
            fixedCosts: fixedCosts,
            targetUnitsPerMonth: targetUnitsPerMonth,
            defaultBatchSize: defaultBatchSize
        )
    }
}

// MARK: - Product Icons
extension Product {
    static let availableIcons: [String] = [
        "shippingbox.fill",
        "cube.box.fill",
        "gift.fill",
        "bag.fill",
        "cart.fill",
        "storefront.fill",
        "tshirt.fill",
        "shoe.fill",
        "cup.and.saucer.fill",
        "fork.knife",
        "birthday.cake.fill",
        "wineglass.fill",
        "takeoutbag.and.cup.and.straw.fill",
        "leaf.fill",
        "drop.fill",
        "bolt.fill",
        "hammer.fill",
        "wrench.fill",
        "paintbrush.fill",
        "pencil.and.ruler.fill"
    ]
    
    static let categories: [String] = [
        "General",
        "Food & Beverage",
        "Apparel",
        "Electronics",
        "Home & Garden",
        "Beauty & Personal Care",
        "Toys & Games",
        "Sports & Outdoors",
        "Automotive",
        "Industrial"
    ]
}

// MARK: - Supporting Structures

/// Batch calculation result
struct BatchCalculation {
    let quantity: Int
    let unitPrimeCost: Double
    let unitTotalCost: Double
    let unitFinalPrice: Double
    let unitProfit: Double
    let batchPrimeCost: Double
    let batchTotalCost: Double
    let batchFinalPrice: Double
    let batchProfit: Double
    let scaleDiscount: Double
    let totalProductionTime: Double
    
    var formattedProductionTime: String {
        if totalProductionTime < 1 {
            return String(format: "%.0f min", totalProductionTime * 60)
        } else if totalProductionTime < 24 {
            return String(format: "%.1f hours", totalProductionTime)
        } else {
            let days = totalProductionTime / 24
            return String(format: "%.1f days", days)
        }
    }
    
    var savingsPerUnit: Double {
        unitPrimeCost - (batchPrimeCost / Double(quantity))
    }
}

/// Break-even analysis result
struct BreakEvenResult {
    let breakEvenUnits: Int
    let breakEvenRevenue: Double
    let contributionMargin: Double
    let fixedCosts: Double
    let profitAtTarget: Double
    let targetUnits: Int
    let safetyMarginPercent: Double
    
    var isProfitable: Bool {
        profitAtTarget > 0
    }
}

/// Scenario analysis result
struct ScenarioResult {
    let originalPrimeCost: Double
    let originalFinalPrice: Double
    let originalProfit: Double
    let newPrimeCost: Double
    let newFinalPrice: Double
    let newProfit: Double
    let primeChange: Double
    let priceChange: Double
    let profitChange: Double
    let profitChangePercent: Double
    
    var isPositive: Bool {
        profitChange >= 0
    }
}
