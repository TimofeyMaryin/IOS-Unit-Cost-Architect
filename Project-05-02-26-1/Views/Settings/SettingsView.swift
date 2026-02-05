import SwiftUI
import SwiftData

/// Settings view for labor costs and overhead expenses
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var laborSettings: [Labor]
    @Query private var appSettings: [AppSettings]
    
    @State private var showingResetAlert = false
    
    private var labor: Labor? {
        laborSettings.first
    }
    
    private var settings: AppSettings? {
        appSettings.first
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Labor section
                laborSection
                
                // Overhead expenses section
                overheadSection
                
                // Summary section
                summarySection
                
            }
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Labor Section
    private var laborSection: some View {
        Section {
            if let labor = labor {
                LaborSettingsRow(labor: labor, modelContext: modelContext)
            } else {
                Text("Labor settings not initialized")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("Labor Cost", systemImage: "person.fill")
        } footer: {
            Text("The hourly labor rate is used to calculate the labor cost component of each product based on production time.")
        }
    }
    
    // MARK: - Overhead Section
    private var overheadSection: some View {
        Section {
            if let settings = settings {
                OverheadSettingsView(settings: settings, modelContext: modelContext)
            } else {
                Text("Settings not initialized")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("Indirect Expenses (Overhead)", systemImage: "building.2.fill")
        } footer: {
            Text("These percentages represent indirect costs that are added to the prime cost. You can customize the overhead percentage for each product individually.")
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        Section("Quick Reference") {
            if let labor = labor {
                LabeledContent("Labor Rate") {
                    Text(labor.formattedHourlyRate)
                        .fontWeight(.semibold)
                }
            }
            
            if let settings = settings {
                LabeledContent("Total Overhead") {
                    Text(String(format: "%.1f%%", settings.totalOverheadPercentage))
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                }
            }
            
            // Example calculation
            VStack(alignment: .leading, spacing: 8) {
                Text("Example Calculation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let _ = labor, let settings = settings {
                    let examplePrime: Double = 100
                    let exampleTotal = examplePrime * (1 + settings.totalOverheadPercentage / 100)
                    
                    HStack {
                        Text("If Prime Cost = $100")
                        Spacer()
                        Text("Total Cost = \(exampleTotal, format: .currency(code: "USD"))")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
            }
            .padding(.vertical, 4)
        }
    }
    

    private func resetToDefaults() {
        if let labor = labor {
            labor.hourlyRate = 15.0
            labor.updatedAt = Date()
        }
        
        if let settings = settings {
            settings.electricityPercentage = 3.0
            settings.rentPercentage = 5.0
            settings.utilitiesPercentage = 2.0
            settings.insurancePercentage = 1.0
            settings.maintenancePercentage = 2.0
            settings.otherOverheadPercentage = 2.0
            settings.updatedAt = Date()
        }
        
        try? modelContext.save()
    }
}

// MARK: - Labor Settings Row
struct LaborSettingsRow: View {
    @Bindable var labor: Labor
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading) {
                    Text("Hourly Rate")
                        .font(.subheadline)
                    Text("Cost per hour of labor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack {
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("Rate", value: $labor.hourlyRate, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: labor.hourlyRate) {
                            labor.updatedAt = Date()
                            try? modelContext.save()
                        }
                    Text("/hr")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Quick presets
            HStack(spacing: 8) {
                Text("Presets:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ForEach([10.0, 15.0, 25.0, 50.0], id: \.self) { rate in
                    Button {
                        labor.hourlyRate = rate
                        labor.updatedAt = Date()
                        try? modelContext.save()
                    } label: {
                        Text("$\(Int(rate))")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(labor.hourlyRate == rate ? Color.orange : Color(.tertiarySystemGroupedBackground))
                            .foregroundStyle(labor.hourlyRate == rate ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Overhead Settings View
struct OverheadSettingsView: View {
    @Bindable var settings: AppSettings
    let modelContext: ModelContext
    
    var body: some View {
        ForEach(settings.overheadBreakdown, id: \.0) { item in
            OverheadRow(
                title: item.0,
                icon: item.1,
                percentage: bindingFor(item.0),
                modelContext: modelContext,
                settings: settings
            )
        }
    }
    
    private func bindingFor(_ name: String) -> Binding<Double> {
        switch name {
        case "Electricity":
            return $settings.electricityPercentage
        case "Rent":
            return $settings.rentPercentage
        case "Utilities":
            return $settings.utilitiesPercentage
        case "Insurance":
            return $settings.insurancePercentage
        case "Maintenance":
            return $settings.maintenancePercentage
        case "Other":
            return $settings.otherOverheadPercentage
        default:
            return .constant(0)
        }
    }
}

// MARK: - Overhead Row
struct OverheadRow: View {
    let title: String
    let icon: String
    @Binding var percentage: Double
    let modelContext: ModelContext
    let settings: AppSettings
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 4) {
                TextField("", value: $percentage, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: percentage) {
                        settings.updatedAt = Date()
                        try? modelContext.save()
                    }
                
                Text("%")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Labor.self, AppSettings.self], inMemory: true)
}
