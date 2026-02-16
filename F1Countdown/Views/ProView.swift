//
//  ProView.swift
//  F1Countdown
//
//  Pro upgrade view with purchase flow
//

import SwiftUI

// MARK: - Pro View

/// View for displaying Pro features and purchase options
struct ProView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @StateObject private var storeService = StoreService.shared
    @State private var isPurchasing = false
    @State private var showSuccessAlert = false
    @State private var showRestoreAlert = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection
                    
                    // Features section
                    featuresSection
                    
                    // Price and purchase section
                    purchaseSection
                    
                    // Restore button
                    restoreSection
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Welcome to Pro!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for supporting F1 Countdown! All Pro features are now unlocked.")
            }
            .alert("Purchases Restored", isPresented: $showRestoreAlert) {
                Button("OK") { }
            } message: {
                Text("Your previous purchases have been restored successfully.")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Pro icon
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.6, green: 0.3, blue: 0.8),
                                Color(red: 0.9, green: 0.4, blue: 0.6),
                                Color(red: 1.0, green: 0.6, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(.largeTitle))
                    .foregroundColor(.white)
            }
            
            Text("F1 Countdown Pro")
                .font(.system(.title, design: .rounded))
                .fontWeight(.heavy)
            
            Text(storeService.isProUser ? "Thank you for your support!" : "Unlock the ultimate F1 experience")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(ProFeature.allCases, id: \.self) { feature in
                ProFeatureRow(
                    icon: feature.iconName,
                    title: feature.displayName,
                    description: feature.description,
                    isUnlocked: storeService.isProUser
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var purchaseSection: some View {
        Group {
            if storeService.isProUser {
                // Already Pro
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.largeTitle))
                        .foregroundColor(.green)
                    
                    Text("You're a Pro Member")
                        .font(.system(.headline, design: .rounded))
                    
                    Text("All features are unlocked and ready to use.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if let product = storeService.products.first {
                // Purchase button
                VStack(spacing: 12) {
                    // Price
                    VStack(spacing: 4) {
                        Text(product.displayPrice)
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.heavy)
                        
                        Text("One-time purchase")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    // Purchase button
                    Button {
                        Task {
                            await handlePurchase(product: product)
                        }
                    } label: {
                        if isPurchasing || storeService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Unlock Pro")
                                .font(.system(.headline, design: .rounded))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.6, green: 0.3, blue: 0.8),
                                Color(red: 0.9, green: 0.4, blue: 0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isPurchasing || storeService.isLoading)
                    .padding(.horizontal)
                    
                    // Transaction state
                    if let state = storeService.transactionState {
                        transactionStateBadge(state)
                    }
                }
            } else if storeService.isLoading {
                ProgressView("Loading...")
                    .padding()
            } else {
                // Error state
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(.largeTitle))
                        .foregroundColor(.orange)
                    
                    Text("Unable to load products")
                        .font(.system(.headline, design: .rounded))
                    
                    Button("Retry") {
                        Task {
                            try? await storeService.loadProducts()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private var restoreSection: some View {
        Group {
            if !storeService.isProUser {
                Button {
                    Task {
                        await handleRestore()
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .disabled(isPurchasing || storeService.isLoading)
            }
        }
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func transactionStateBadge(_ state: TransactionState) -> some View {
        HStack(spacing: 8) {
            switch state {
            case .purchased, .restored:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(state.displayName)
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text(state.displayName)
                    .foregroundColor(.red)
            case .pending, .deferred:
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text(state.displayName)
                    .foregroundColor(.orange)
            }
        }
        .font(.system(.caption, design: .rounded))
        .padding(.top, 8)
    }
    
    // MARK: - Actions
    
    private func handlePurchase(product: AppProduct) async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await storeService.purchase(product: product)
            
            switch result {
            case .success:
                showSuccessAlert = true
            case .userCancelled:
                break
            case .pending:
                break
            case .failed(let error):
                errorMessage = error?.localizedDescription ?? "Purchase failed"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleRestore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            try await storeService.restorePurchases()
            if storeService.isProUser {
                showRestoreAlert = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Pro Feature Row

struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var isUnlocked: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isUnlocked
                            ? Color.green.opacity(0.2)
                            : Color(red: 0.6, green: 0.3, blue: 0.8).opacity(0.2)
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: isUnlocked ? "checkmark.circle.fill" : icon)
                    .font(.system(.title3))
                    .foregroundColor(
                        isUnlocked
                            ? .green
                            : Color(red: 0.6, green: 0.3, blue: 0.8)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pro Purchase Sheet

/// Sheet wrapper for Pro purchase view
struct ProPurchaseSheet: View {
    @Binding var isProUser: Bool
    @StateObject private var storeService = StoreService.shared
    
    var body: some View {
        ProView()
            .onChange(of: storeService.isProUser) { _, newValue in
                isProUser = newValue
            }
    }
}

// MARK: - Previews

#Preview("Pro View - Not Pro") {
    ProView()
}

#Preview("Pro View - Pro User") {
    ProView()
        .environmentObject(StoreService.previewPro)
}

#Preview("Pro Feature Row") {
    VStack {
        ProFeatureRow(
            icon: "waveform.path",
            title: "Live Activities",
            description: "Real-time race updates on Dynamic Island"
        )
        
        ProFeatureRow(
            icon: "waveform.path",
            title: "Live Activities",
            description: "Real-time race updates on Dynamic Island",
            isUnlocked: true
        )
    }
    .padding()
}
