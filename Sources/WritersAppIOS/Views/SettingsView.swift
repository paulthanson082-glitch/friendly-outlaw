import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var apiKeyInput = ""
    @State private var showConfirmation = false
    @State private var showDisableConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: AI Status
                Section {
                    HStack {
                        Label(
                            viewModel.isAIEnabled ? "Enabled" : "Disabled",
                            systemImage: viewModel.isAIEnabled ? "checkmark.circle.fill" : "xmark.circle"
                        )
                        .foregroundStyle(viewModel.isAIEnabled ? .green : .secondary)
                    }
                } header: {
                    Text("AI Features")
                }

                // MARK: API Key Entry
                Section {
                    SecureField("Anthropic API Key (sk-ant-…)", text: $apiKeyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.password)

                    Button("Enable AI") {
                        viewModel.enableAI(apiKey: apiKeyInput)
                        apiKeyInput = ""
                        if viewModel.isAIEnabled { showConfirmation = true }
                    }
                    .disabled(apiKeyInput.isEmpty)

                    if viewModel.isAIEnabled {
                        Button("Disable AI", role: .destructive) {
                            showDisableConfirm = true
                        }
                    }
                } header: {
                    Text("API Key")
                } footer: {
                    Text("Your key is stored in UserDefaults and never sent anywhere except Anthropic's API.")
                }

                // MARK: App Info
                Section("About") {
                    LabeledContent("App", value: "Writers App")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Platforms", value: "iOS 16+, macOS 13+")
                }
            }
            .navigationTitle("Settings")
            .alert("AI Enabled", isPresented: $showConfirmation) {
                Button("OK") {}
            } message: {
                Text("AI writing features are now active.")
            }
            .confirmationDialog("Disable AI?", isPresented: $showDisableConfirm, titleVisibility: .visible) {
                Button("Disable AI", role: .destructive) {
                    viewModel.disableAI()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove your stored API key.")
            }
        }
    }
}
