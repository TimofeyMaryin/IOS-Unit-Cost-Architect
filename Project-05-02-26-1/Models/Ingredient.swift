import Foundation
import SwiftData

/// Ingredient model - links materials to products with specific amounts
@Model
final class Ingredient {
    var id: UUID
    var amountRequired: Double
    var createdAt: Date
    
    /// Linked material (many-to-one relationship)
    var material: Material?
    
    /// Parent product (many-to-one relationship)
    var product: Product?
    
    init(
        id: UUID = UUID(),
        amountRequired: Double = 0,
        material: Material? = nil,
        product: Product? = nil
    ) {
        self.id = id
        self.amountRequired = amountRequired
        self.material = material
        self.product = product
        self.createdAt = Date()
    }
    
    /// Calculated cost for this ingredient
    var cost: Double {
        guard let material = material else { return 0 }
        return amountRequired * material.pricePerUnit
    }
    
    /// Formatted cost string
    var formattedCost: String {
        String(format: "$%.4f", cost)
    }
    
    /// Display name from material
    var displayName: String {
        material?.name ?? "Unknown Material"
    }
    
    /// Unit type from material
    var unitSymbol: String {
        material?.unitType.symbol ?? ""
    }
}
