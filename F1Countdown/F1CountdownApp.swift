//
//  F1CountdownApp.swift
//  F1Countdown
//
//  Main application entry point with SwiftData configuration
//

import SwiftUI
import SwiftData

@main
struct F1CountdownApp: App {
    // MARK: - SwiftData
    
    /// The model container for SwiftData persistence
    let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init() {
        // Configure SwiftData model container
        do {
            let schema = Schema([
                RaceRecord.self,
                CircuitRecord.self,
                UserPreferences.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier("group.com.f1countdown.app"),
                cloudKitDatabase: .private("iCloud.com.f1countdown.app")
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            // Fallback to in-memory storage if CloudKit fails
            do {
                modelContainer = try ModelContainer(
                    for: RaceRecord.self, CircuitRecord.self, UserPreferences.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                fatalError("Failed to create model container: \(error)")
            }
        }
        
        // Configure appearance
        configureAppearance()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhase(newPhase)
        }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Helpers
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold, width: .expanded)
        ]
        appearance.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold, width: .expanded)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure accent color
        UIView.appearance().tintColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0)
    }
    
    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Refresh data when app becomes active
            Task {
                // Background refresh would be handled here
            }
        case .inactive:
            break
        case .background:
            // Schedule background refresh
            // BackgroundTaskHandler.shared.registerBackgroundTasks(with: dataService)
            break
        @unknown default:
            break
        }
    }
}
