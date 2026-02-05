import Foundation
import SwiftData

/// Unit types for materials measurement
enum UnitType: String, Codable, CaseIterable {
    case kg = "kg"
    case g = "g"
    case l = "l"
    case ml = "ml"
    case m = "m"
    case cm = "cm"
    case pcs = "pcs"
    
    var displayName: String {
        switch self {
        case .kg: return "Kilogram"
        case .g: return "Gram"
        case .l: return "Liter"
        case .ml: return "Milliliter"
        case .m: return "Meter"
        case .cm: return "Centimeter"
        case .pcs: return "Pieces"
        }
    }
    
    var symbol: String {
        rawValue
    }
}

/// Material categories for organization
enum MaterialCategory: String, Codable, CaseIterable {
    case rawMaterial = "Raw Material"
    case packaging = "Packaging"
    case consumable = "Consumable"
    case component = "Component"
    case chemical = "Chemical"
    case textile = "Textile"
    case metal = "Metal"
    case wood = "Wood"
    case plastic = "Plastic"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .rawMaterial: return "cube.box.fill"
        case .packaging: return "shippingbox.fill"
        case .consumable: return "arrow.triangle.2.circlepath"
        case .component: return "gearshape.2.fill"
        case .chemical: return "flask.fill"
        case .textile: return "tshirt.fill"
        case .metal: return "wrench.and.screwdriver.fill"
        case .wood: return "tree.fill"
        case .plastic: return "capsule.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// Material model representing raw materials in inventory
@Model
final class Material {
    var id: UUID
    var name: String
    var category: MaterialCategory
    var bulkPrice: Double
    var bulkAmount: Double
    var unitType: UnitType
    var createdAt: Date
    var updatedAt: Date
    
    // NEW: Inventory tracking (with default values for migration)
    var currentStock: Double = 0
    var minimumStock: Double = 0
    var reorderPoint: Double = 0
    var sku: String = "" // Stock Keeping Unit
    
    // NEW: Currency support (with default value for migration)
    var currencyCode: CurrencyCode = CurrencyCode.usd
    
    /// Ingredients that use this material (inverse relationship)
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.material)
    var ingredients: [Ingredient]?
    
    /// NEW: Supplier relationship
    var supplier: Supplier?
    
    /// NEW: Price history
    @Relationship(deleteRule: .cascade, inverse: \PriceHistory.material)
    var priceHistory: [PriceHistory]?
    
    /// Computed property: price per single unit
    var pricePerUnit: Double {
        guard bulkAmount > 0 else { return 0 }
        return bulkPrice / bulkAmount
    }
    
    init(
        id: UUID = UUID(),
        name: String = "",
        category: MaterialCategory = .rawMaterial,
        bulkPrice: Double = 0,
        bulkAmount: Double = 1,
        unitType: UnitType = .kg,
        currentStock: Double = 0,
        minimumStock: Double = 0,
        reorderPoint: Double = 0,
        sku: String = "",
        currencyCode: CurrencyCode = .usd
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.bulkPrice = bulkPrice
        self.bulkAmount = bulkAmount
        self.unitType = unitType
        self.currentStock = currentStock
        self.minimumStock = minimumStock
        self.reorderPoint = reorderPoint
        self.sku = sku
        self.currencyCode = currencyCode
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Formatted price per unit string
    var formattedPricePerUnit: String {
        String(format: "%@%.4f/%@", currencyCode.symbol, pricePerUnit, unitType.symbol)
    }
    
    /// Formatted bulk price string
    var formattedBulkPrice: String {
        String(format: "%@%.2f for %.2f %@", currencyCode.symbol, bulkPrice, bulkAmount, unitType.symbol)
    }
    
    // MARK: - Stock Status
    
    /// Stock status enum
    enum StockStatus {
        case inStock
        case lowStock
        case outOfStock
        case reorderNeeded
        
        var color: String {
            switch self {
            case .inStock: return "green"
            case .lowStock: return "yellow"
            case .outOfStock: return "red"
            case .reorderNeeded: return "orange"
            }
        }
        
        var icon: String {
            switch self {
            case .inStock: return "checkmark.circle.fill"
            case .lowStock: return "exclamationmark.triangle.fill"
            case .outOfStock: return "xmark.circle.fill"
            case .reorderNeeded: return "arrow.clockwise.circle.fill"
            }
        }
        
        var label: String {
            switch self {
            case .inStock: return "In Stock"
            case .lowStock: return "Low Stock"
            case .outOfStock: return "Out of Stock"
            case .reorderNeeded: return "Reorder Needed"
            }
        }
    }
    
    /// Current stock status
    var stockStatus: StockStatus {
        if currentStock <= 0 {
            return .outOfStock
        } else if currentStock <= reorderPoint {
            return .reorderNeeded
        } else if currentStock <= minimumStock {
            return .lowStock
        }
        return .inStock
    }
    
    /// Stock level percentage (for progress bars)
    var stockLevelPercentage: Double {
        guard minimumStock > 0 else { return currentStock > 0 ? 100 : 0 }
        return min(100, (currentStock / minimumStock) * 100)
    }
    
    /// Record current price to history
    func recordPriceHistory(note: String = "", context: ModelContext) {
        let history = PriceHistory(
            bulkPrice: bulkPrice,
            bulkAmount: bulkAmount,
            note: note,
            material: self
        )
        context.insert(history)
    }
    
    /// Get price change since last recorded
    var priceChangePercentage: Double? {
        guard let history = priceHistory?.sorted(by: { $0.recordedAt > $1.recordedAt }),
              history.count >= 2 else { return nil }
        
        let current = pricePerUnit
        let previous = history[1].pricePerUnit
        
        guard previous > 0 else { return nil }
        return ((current - previous) / previous) * 100
    }
}
