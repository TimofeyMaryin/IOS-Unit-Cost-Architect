import Foundation
import SwiftData

/// Supplier model for managing material sources
@Model
final class Supplier {
    var id: UUID
    var name: String
    var contactPerson: String
    var email: String
    var phone: String
    var address: String
    var website: String
    var notes: String
    var rating: Int // 1-5 stars
    var isPreferred: Bool
    var createdAt: Date
    var updatedAt: Date
    
    /// Materials from this supplier
    @Relationship(deleteRule: .nullify, inverse: \Material.supplier)
    var materials: [Material]?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        contactPerson: String = "",
        email: String = "",
        phone: String = "",
        address: String = "",
        website: String = "",
        notes: String = "",
        rating: Int = 3,
        isPreferred: Bool = false
    ) {
        self.id = id
        self.name = name
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.address = address
        self.website = website
        self.notes = notes
        self.rating = min(5, max(1, rating))
        self.isPreferred = isPreferred
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Number of materials from this supplier
    var materialCount: Int {
        materials?.count ?? 0
    }
    
    /// Star rating display
    var starRating: String {
        String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating)
    }
}
