import Foundation
import SwiftData

/// Note/comment attached to a product
@Model
final class ProductNote {
    var id: UUID
    var content: String
    var category: NoteCategory
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
    
    /// Link to product
    var product: Product?
    
    init(
        id: UUID = UUID(),
        content: String = "",
        category: NoteCategory = .general,
        isPinned: Bool = false,
        product: Product? = nil
    ) {
        self.id = id
        self.content = content
        self.category = category
        self.isPinned = isPinned
        self.product = product
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Note categories
enum NoteCategory: String, Codable, CaseIterable {
    case general = "General"
    case production = "Production"
    case quality = "Quality"
    case improvement = "Improvement"
    case warning = "Warning"
    case reminder = "Reminder"
    
    var icon: String {
        switch self {
        case .general: return "note.text"
        case .production: return "gearshape.2.fill"
        case .quality: return "checkmark.seal.fill"
        case .improvement: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .reminder: return "bell.fill"
        }
    }
    
    var color: String {
        switch self {
        case .general: return "gray"
        case .production: return "blue"
        case .quality: return "green"
        case .improvement: return "yellow"
        case .warning: return "orange"
        case .reminder: return "purple"
        }
    }
}
