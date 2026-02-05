import SwiftUI
import SwiftData

/// PDF Export view for generating Technical Map
struct PDFExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    let product: Product
    let hourlyRate: Double
    
    @State private var isExporting = false
    @State private var exportSuccess = false
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Preview of the technical map
                    technicalMapPreview
                        .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Technical Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        exportPDF()
                    } label: {
                        if isExporting {
                            ProgressView()
                        } else {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .sensoryFeedback(.success, trigger: exportSuccess)
            .sheet(isPresented: $showingShareSheet) {
                if let pdfData = pdfData {
                    ShareSheet(items: [pdfData])
                }
            }
        }
    }
    
    // MARK: - Technical Map Preview
    private var technicalMapPreview: some View {
        TechnicalMapView(product: product, hourlyRate: hourlyRate)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    // MARK: - Export PDF
    @MainActor
    private func exportPDF() {
        isExporting = true
        
        let renderer = ImageRenderer(content: 
            TechnicalMapView(product: product, hourlyRate: hourlyRate)
                .frame(width: 595) // A4 width in points
                .background(Color.white)
        )
        
        renderer.scale = 2.0
        
        let url = URL.documentsDirectory.appending(path: "\(product.name)_TechnicalMap.pdf")
        
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                isExporting = false
                return
            }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            
            // Read the PDF data for sharing
            if let data = try? Data(contentsOf: url) {
                pdfData = data
                exportSuccess = true
                showingShareSheet = true
            }
            
            isExporting = false
        }
    }
}

// MARK: - Technical Map View (PDF Content)
struct TechnicalMapView: View {
    let product: Product
    let hourlyRate: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: product.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("TECHNICAL MAP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(product.name)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Unit Cost Architect")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(Date(), format: .dateTime.day().month().year())
                            .font(.caption)
                    }
                }
                
                Divider()
            }
            
            // Product info
            HStack(alignment: .top, spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Production Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(product.formattedTimeToProduce)
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overhead")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(product.overheadPercentage))%")
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Markup")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(product.markupPercentage))%")
                        .font(.headline)
                }
            }
            
            // Ingredients table
            VStack(alignment: .leading, spacing: 8) {
                Text("BILL OF MATERIALS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text("Material")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Amount")
                            .frame(width: 80, alignment: .trailing)
                        Text("Unit Price")
                            .frame(width: 80, alignment: .trailing)
                        Text("Cost")
                            .frame(width: 80, alignment: .trailing)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    
                    // Ingredient rows
                    if let ingredients = product.ingredients {
                        ForEach(ingredients) { ingredient in
                            HStack {
                                Text(ingredient.displayName)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(String(format: "%.2f", ingredient.amountRequired) + " " + ingredient.unitSymbol)
                                    .frame(width: 80, alignment: .trailing)
                                Text(ingredient.material?.formattedPricePerUnit ?? "-")
                                    .frame(width: 80, alignment: .trailing)
                                Text(ingredient.formattedCost)
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            
                            Divider()
                        }
                    }
                    
                    // Total materials
                    HStack {
                        Text("Total Materials")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(product.materialCost, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .font(.caption)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.1))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Cost breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("COST BREAKDOWN")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 0) {
                    CostBreakdownRow(
                        label: "Material Cost",
                        value: product.materialCost
                    )
                    
                    CostBreakdownRow(
                        label: "Labor Cost (\(product.formattedTimeToProduce) × $\(String(format: "%.2f", hourlyRate))/hr)",
                        value: product.laborCost(hourlyRate: hourlyRate)
                    )
                    
                    CostBreakdownRow(
                        label: "Prime Cost",
                        value: product.primeCost(hourlyRate: hourlyRate),
                        isHighlighted: true
                    )
                    
                    CostBreakdownRow(
                        label: "Overhead (+\(Int(product.overheadPercentage))%)",
                        value: product.totalCost(hourlyRate: hourlyRate) - product.primeCost(hourlyRate: hourlyRate)
                    )
                    
                    CostBreakdownRow(
                        label: "Total Cost",
                        value: product.totalCost(hourlyRate: hourlyRate),
                        isHighlighted: true
                    )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Final pricing
            VStack(alignment: .leading, spacing: 8) {
                Text("PRICING")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Final Price")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(product.finalPrice(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Profit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(product.netProfit(hourlyRate: hourlyRate), format: .currency(code: "USD"))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profit Margin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f%%", product.profitMargin(hourlyRate: hourlyRate)))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Footer
            Divider()
            
            Text("Generated by Unit Cost Architect • \(Date(), format: .dateTime)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
    }
}

// MARK: - Cost Breakdown Row
struct CostBreakdownRow: View {
    let label: String
    let value: Double
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(isHighlighted ? .semibold : .regular)
            Spacer()
            Text(value, format: .currency(code: "USD"))
                .fontWeight(isHighlighted ? .semibold : .regular)
        }
        .font(.caption)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    PDFExportView(
        product: Product(
            name: "Sample Widget",
            markupPercentage: 40,
            overheadPercentage: 15,
            timeToProduce: 2.5
        ),
        hourlyRate: 15.0
    )
}
