import Foundation
import SwiftData

/// Price history entry for tracking material price changes over time
@Model
final class PriceHistory {
    var id: UUID
    var bulkPrice: Double
    var bulkAmount: Double
    var pricePerUnit: Double
    var recordedAt: Date
    var note: String
    
    /// Link to material
    var material: Material?
    
    init(
        id: UUID = UUID(),
        bulkPrice: Double,
        bulkAmount: Double,
        note: String = "",
        material: Material? = nil
    ) {
        self.id = id
        self.bulkPrice = bulkPrice
        self.bulkAmount = bulkAmount
        self.pricePerUnit = bulkAmount > 0 ? bulkPrice / bulkAmount : 0
        self.recordedAt = Date()
        self.note = note
        self.material = material
    }
    
    /// Formatted date
    var formattedDate: String {
        recordedAt.formatted(date: .abbreviated, time: .shortened)
    }
    
    /// Price change percentage compared to previous price
    func changePercentage(from previousPrice: Double) -> Double {
        guard previousPrice > 0 else { return 0 }
        return ((pricePerUnit - previousPrice) / previousPrice) * 100
    }
}
