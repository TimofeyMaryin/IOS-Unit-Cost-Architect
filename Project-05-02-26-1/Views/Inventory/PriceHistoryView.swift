import SwiftUI
import SwiftData
import Charts

/// Price history tracking view with chart
struct PriceHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    let material: Material
    
    @State private var showingAddEntry = false
    @State private var newNote = ""
    
    private var sortedHistory: [PriceHistory] {
        (material.priceHistory ?? []).sorted { $0.recordedAt > $1.recordedAt }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current price card
                currentPriceCard
                
                // Price chart
                if sortedHistory.count > 1 {
                    priceChart
                }
                
                // History list
                historyList
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Price History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    recordCurrentPrice()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            addNoteSheet
        }
    }
    
    // MARK: - Current Price Card
    private var currentPriceCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: material.category.icon)
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(material.name)
                        .font(.headline)
                    Text(material.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Unit Price")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(material.formattedPricePerUnit)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                
                Spacer()
                
                if let change = material.priceChangePercentage {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("vs. Previous")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text(String(format: "%.1f%%", abs(change)))
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(change >= 0 ? .red : .green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Price Chart
    private var priceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Trend")
                .font(.headline)
            
            Chart {
                ForEach(sortedHistory.reversed()) { entry in
                    LineMark(
                        x: .value("Date", entry.recordedAt),
                        y: .value("Price", entry.pricePerUnit)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Date", entry.recordedAt),
                        y: .value("Price", entry.pricePerUnit)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(50)
                }
                
                // Average line
                let avg = sortedHistory.reduce(0) { $0 + $1.pricePerUnit } / Double(sortedHistory.count)
                RuleMark(y: .value("Average", avg))
                    .foregroundStyle(.orange.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg: \(String(format: "%.4f", avg))")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
            }
            .frame(height: 200)
            .chartYAxisLabel("Price per \(material.unitType.symbol)")
            
            // Statistics
            HStack(spacing: 20) {
                StatItem(label: "Min", value: minPrice)
                StatItem(label: "Max", value: maxPrice)
                StatItem(label: "Avg", value: avgPrice)
                StatItem(label: "Records", value: "\(sortedHistory.count)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var minPrice: String {
        guard let min = sortedHistory.map({ $0.pricePerUnit }).min() else { return "-" }
        return String(format: "%.4f", min)
    }
    
    private var maxPrice: String {
        guard let max = sortedHistory.map({ $0.pricePerUnit }).max() else { return "-" }
        return String(format: "%.4f", max)
    }
    
    private var avgPrice: String {
        guard !sortedHistory.isEmpty else { return "-" }
        let avg = sortedHistory.reduce(0) { $0 + $1.pricePerUnit } / Double(sortedHistory.count)
        return String(format: "%.4f", avg)
    }
    
    // MARK: - History List
    private var historyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History Log")
                    .font(.headline)
                Spacer()
                Text("\(sortedHistory.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if sortedHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    
                    Text("No price history yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button("Record Current Price") {
                        recordCurrentPrice()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(sortedHistory) { entry in
                    PriceHistoryRow(entry: entry, previousEntry: previousEntry(for: entry))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func previousEntry(for entry: PriceHistory) -> PriceHistory? {
        guard let index = sortedHistory.firstIndex(where: { $0.id == entry.id }),
              index + 1 < sortedHistory.count else { return nil }
        return sortedHistory[index + 1]
    }
    
    // MARK: - Add Note Sheet
    private var addNoteSheet: some View {
        NavigationStack {
            Form {
                Section("Current Price") {
                    LabeledContent("Bulk Price") {
                        Text(material.bulkPrice, format: .currency(code: "USD"))
                    }
                    LabeledContent("Bulk Amount") {
                        Text("\(String(format: "%.2f", material.bulkAmount)) \(material.unitType.symbol)")
                    }
                    LabeledContent("Unit Price") {
                        Text(material.formattedPricePerUnit)
                            .fontWeight(.semibold)
                    }
                }
                
                Section("Note (Optional)") {
                    TextField("Reason for price change...", text: $newNote, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Record Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddEntry = false
                        newNote = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func recordCurrentPrice() {
        showingAddEntry = true
    }
    
    private func saveEntry() {
        material.recordPriceHistory(note: newNote, context: modelContext)
        try? modelContext.save()
        newNote = ""
        showingAddEntry = false
    }
}

// MARK: - Supporting Views
struct PriceHistoryRow: View {
    let entry: PriceHistory
    let previousEntry: PriceHistory?
    
    private var changePercent: Double? {
        guard let prev = previousEntry else { return nil }
        return entry.changePercentage(from: prev.pricePerUnit)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.formattedDate)
                    .font(.subheadline)
                
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.4f", entry.pricePerUnit))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let change = changePercent {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        Text(String(format: "%.1f%%", abs(change)))
                    }
                    .font(.caption)
                    .foregroundStyle(change >= 0 ? .red : .green)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        PriceHistoryView(material: Material(name: "Test Material", bulkPrice: 100, bulkAmount: 10))
    }
    .modelContainer(for: [Material.self, PriceHistory.self], inMemory: true)
}
