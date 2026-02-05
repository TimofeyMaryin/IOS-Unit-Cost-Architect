import Foundation
import SwiftData

/// Labor settings model - singleton pattern for app-wide labor rate
@Model
final class Labor {
    var id: UUID
    var hourlyRate: Double
    var currency: String
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        hourlyRate: Double = 15.0,
        currency: String = "USD"
    ) {
        self.id = id
        self.hourlyRate = hourlyRate
        self.currency = currency
        self.updatedAt = Date()
    }
    
    /// Formatted hourly rate
    var formattedHourlyRate: String {
        String(format: "$%.2f/hr", hourlyRate)
    }
    
    /// Calculate labor cost for given hours
    func cost(forHours hours: Double) -> Double {
        hours * hourlyRate
    }
}
