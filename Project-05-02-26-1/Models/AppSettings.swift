import Foundation
import SwiftData

/// App-wide settings including overhead expenses
@Model
final class AppSettings {
    var id: UUID
    
    // Overhead expense categories (as percentages)
    var electricityPercentage: Double
    var rentPercentage: Double
    var utilitiesPercentage: Double
    var insurancePercentage: Double
    var maintenancePercentage: Double
    var otherOverheadPercentage: Double
    
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        electricityPercentage: Double = 3.0,
        rentPercentage: Double = 5.0,
        utilitiesPercentage: Double = 2.0,
        insurancePercentage: Double = 1.0,
        maintenancePercentage: Double = 2.0,
        otherOverheadPercentage: Double = 2.0
    ) {
        self.id = id
        self.electricityPercentage = electricityPercentage
        self.rentPercentage = rentPercentage
        self.utilitiesPercentage = utilitiesPercentage
        self.insurancePercentage = insurancePercentage
        self.maintenancePercentage = maintenancePercentage
        self.otherOverheadPercentage = otherOverheadPercentage
        self.updatedAt = Date()
    }
    
    /// Total overhead percentage
    var totalOverheadPercentage: Double {
        electricityPercentage +
        rentPercentage +
        utilitiesPercentage +
        insurancePercentage +
        maintenancePercentage +
        otherOverheadPercentage
    }
    
    /// Overhead breakdown for display
    var overheadBreakdown: [(String, String, Double)] {
        [
            ("Electricity", "bolt.fill", electricityPercentage),
            ("Rent", "building.2.fill", rentPercentage),
            ("Utilities", "drop.fill", utilitiesPercentage),
            ("Insurance", "shield.fill", insurancePercentage),
            ("Maintenance", "wrench.fill", maintenancePercentage),
            ("Other", "ellipsis.circle.fill", otherOverheadPercentage)
        ]
    }
}
