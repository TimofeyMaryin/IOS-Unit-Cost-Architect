import SwiftUI
import SwiftData

/// Onboarding flow for new users
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userPreferences: [UserPreferences]
    
    @State private var currentPage = 0
    @State private var selectedCurrency: CurrencyCode = .usd
    @State private var showingCurrencyPicker = false
    
    let onComplete: () -> Void
    
    private var preferences: UserPreferences? {
        userPreferences.first
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [currentPageColor.opacity(0.3), currentPageColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundStyle(.secondary)
                    .padding()
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(OnboardingPage.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                    
                    // Final setup page
                    setupPage
                        .tag(OnboardingPage.pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Page indicator and button
                VStack(spacing: 24) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<OnboardingPage.pages.count + 1, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? currentPageColor : Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    // Action button
                    Button {
                        if currentPage < OnboardingPage.pages.count {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < OnboardingPage.pages.count ? "Continue" : "Get Started")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentPageColor.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Setup Page
    private var setupPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 80))
                .foregroundStyle(.purple.gradient)
            
            VStack(spacing: 12) {
                Text("Quick Setup")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Choose your preferred currency for cost calculations.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Currency selector
            Button {
                showingCurrencyPicker = true
            } label: {
                HStack {
                    Text(selectedCurrency.flag)
                        .font(.title)
                    
                    VStack(alignment: .leading) {
                        Text(selectedCurrency.name)
                            .font(.headline)
                        Text(selectedCurrency.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerView(selectedCurrency: $selectedCurrency)
        }
    }
    
    private var currentPageColor: Color {
        if currentPage >= OnboardingPage.pages.count {
            return .purple
        }
        let colorName = OnboardingPage.pages[currentPage].color
        switch colorName {
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    private func completeOnboarding() {
        if let prefs = preferences {
            prefs.hasCompletedOnboarding = true
            prefs.selectedCurrency = selectedCurrency
            prefs.lastOpenedAt = Date()
        } else {
            let newPrefs = UserPreferences(
                hasCompletedOnboarding: true,
                selectedCurrency: selectedCurrency
            )
            modelContext.insert(newPrefs)
        }
        
        // Initialize currency settings
        let currencySettings = CurrencySettings(baseCurrency: selectedCurrency)
        modelContext.insert(currencySettings)
        
        try? modelContext.save()
        onComplete()
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    private var pageColor: Color {
        switch page.color {
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundStyle(pageColor.gradient)
                .symbolEffect(.pulse)
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Currency Picker
struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCurrency: CurrencyCode
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(CurrencyCode.allCases) { currency in
                    Button {
                        selectedCurrency = currency
                        dismiss()
                    } label: {
                        HStack {
                            Text(currency.flag)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(currency.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(currency.rawValue) • \(currency.symbol)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if currency == selectedCurrency {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [UserPreferences.self, CurrencySettings.self], inMemory: true)
}
