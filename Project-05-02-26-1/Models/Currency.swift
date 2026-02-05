import Foundation
import SwiftData

/// Supported currencies with exchange rates
enum CurrencyCode: String, Codable, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case rub = "RUB"
    case gbp = "GBP"
    case cny = "CNY"
    case jpy = "JPY"
    case inr = "INR"
    case brl = "BRL"
    case cad = "CAD"
    case aud = "AUD"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .rub: return "₽"
        case .gbp: return "£"
        case .cny: return "¥"
        case .jpy: return "¥"
        case .inr: return "₹"
        case .brl: return "R$"
        case .cad: return "C$"
        case .aud: return "A$"
        }
    }
    
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .rub: return "Russian Ruble"
        case .gbp: return "British Pound"
        case .cny: return "Chinese Yuan"
        case .jpy: return "Japanese Yen"
        case .inr: return "Indian Rupee"
        case .brl: return "Brazilian Real"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        }
    }
    
    var flag: String {
        switch self {
        case .usd: return "🇺🇸"
        case .eur: return "🇪🇺"
        case .rub: return "🇷🇺"
        case .gbp: return "🇬🇧"
        case .cny: return "🇨🇳"
        case .jpy: return "🇯🇵"
        case .inr: return "🇮🇳"
        case .brl: return "🇧🇷"
        case .cad: return "🇨🇦"
        case .aud: return "🇦🇺"
        }
    }
    
    /// Default exchange rate to USD (can be updated by user)
    var defaultRateToUSD: Double {
        switch self {
        case .usd: return 1.0
        case .eur: return 1.08
        case .rub: return 0.011
        case .gbp: return 1.27
        case .cny: return 0.14
        case .jpy: return 0.0067
        case .inr: return 0.012
        case .brl: return 0.20
        case .cad: return 0.74
        case .aud: return 0.65
        }
    }
}

/// Currency settings model for storing exchange rates
@Model
final class CurrencySettings {
    var id: UUID
    var baseCurrency: CurrencyCode
    var exchangeRates: [String: Double] // CurrencyCode.rawValue -> rate to base
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        baseCurrency: CurrencyCode = .usd
    ) {
        self.id = id
        self.baseCurrency = baseCurrency
        self.updatedAt = Date()
        
        // Initialize default exchange rates
        var rates: [String: Double] = [:]
        for currency in CurrencyCode.allCases {
            if currency == baseCurrency {
                rates[currency.rawValue] = 1.0
            } else {
                // Convert default USD rate to base currency rate
                let usdRate = currency.defaultRateToUSD
                let baseToUSD = baseCurrency.defaultRateToUSD
                rates[currency.rawValue] = usdRate / baseToUSD
            }
        }
        self.exchangeRates = rates
    }
    
    /// Get exchange rate for a currency
    func rate(for currency: CurrencyCode) -> Double {
        exchangeRates[currency.rawValue] ?? currency.defaultRateToUSD
    }
    
    /// Convert amount from one currency to another
    func convert(_ amount: Double, from: CurrencyCode, to: CurrencyCode) -> Double {
        if from == to { return amount }
        
        let fromRate = rate(for: from)
        let toRate = rate(for: to)
        
        // Convert to base, then to target
        let inBase = amount * fromRate
        return inBase / toRate
    }
    
    /// Format amount in specified currency
    func format(_ amount: Double, currency: CurrencyCode) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.currencySymbol = currency.symbol
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)\(amount)"
    }
}
