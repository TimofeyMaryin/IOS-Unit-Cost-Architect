import Foundation
import SwiftData

/// Product template for quick creation of similar products
@Model
final class ProductTemplate {
    var id: UUID
    var name: String
    var templateDescription: String
    var defaultMarkupPercentage: Double
    var defaultOverheadPercentage: Double
    var defaultTimeToProduce: Double
    var iconName: String
    var category: String
    var createdAt: Date
    var usageCount: Int
    
    /// Template ingredients (stored as JSON-like structure)
    var ingredientData: [TemplateIngredient]
    
    init(
        id: UUID = UUID(),
        name: String = "",
        templateDescription: String = "",
        defaultMarkupPercentage: Double = 30.0,
        defaultOverheadPercentage: Double = 15.0,
        defaultTimeToProduce: Double = 1.0,
        iconName: String = "doc.on.doc.fill",
        category: String = "General",
        ingredientData: [TemplateIngredient] = []
    ) {
        self.id = id
        self.name = name
        self.templateDescription = templateDescription
        self.defaultMarkupPercentage = defaultMarkupPercentage
        self.defaultOverheadPercentage = defaultOverheadPercentage
        self.defaultTimeToProduce = defaultTimeToProduce
        self.iconName = iconName
        self.category = category
        self.ingredientData = ingredientData
        self.createdAt = Date()
        self.usageCount = 0
    }
    
    /// Create template from existing product
    static func from(product: Product) -> ProductTemplate {
        let ingredientData = (product.ingredients ?? []).compactMap { ingredient -> TemplateIngredient? in
            guard let material = ingredient.material else { return nil }
            return TemplateIngredient(
                materialId: material.id,
                materialName: material.name,
                amountRequired: ingredient.amountRequired
            )
        }
        
        return ProductTemplate(
            name: "\(product.name) Template",
            templateDescription: "Template based on \(product.name)",
            defaultMarkupPercentage: product.markupPercentage,
            defaultOverheadPercentage: product.overheadPercentage,
            defaultTimeToProduce: product.timeToProduce,
            iconName: product.iconName,
            ingredientData: ingredientData
        )
    }
}

/// Template ingredient data structure
struct TemplateIngredient: Codable, Hashable {
    var materialId: UUID
    var materialName: String
    var amountRequired: Double
}
