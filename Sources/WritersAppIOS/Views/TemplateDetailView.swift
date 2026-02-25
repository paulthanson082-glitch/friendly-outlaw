import SwiftUI
import WritersApp

// MARK: - TemplateDetailView

struct TemplateDetailView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    let template: Template

    @State private var values: [String: String] = [:]
    @State private var createdDocument: Document? = nil
    @State private var navigateToEditor = false

    var body: some View {
        Form {
            // MARK: About section
            if !template.description.isEmpty {
                Section("About") {
                    Text(template.description)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: Placeholder fields
            if !template.placeholders.isEmpty {
                Section {
                    ForEach(template.placeholders) { placeholder in
                        PlaceholderFieldView(placeholder: placeholder, values: $values)
                    }
                } header: {
                    Text("Fill In Details")
                } footer: {
                    Text("Fields marked * are required.")
                }
            }

            // MARK: Create button
            Section {
                Button {
                    create()
                } label: {
                    Text("Create Document")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .bold()
                }
                .disabled(!allRequiredFilled)
            }
        }
        .navigationTitle(template.name)
        .onAppear { prefillDefaults() }
        .navigationDestination(isPresented: $navigateToEditor) {
            if let doc = createdDocument {
                DocumentEditorView(document: doc)
            }
        }
    }

    // MARK: - Helpers

    private var allRequiredFilled: Bool {
        template.placeholders
            .filter { $0.required }
            .allSatisfy { !(values[$0.key] ?? "").isEmpty }
    }

    private func prefillDefaults() {
        for placeholder in template.placeholders {
            if let def = placeholder.defaultValue {
                values[placeholder.key] = def
            }
        }
    }

    private func create() {
        guard let doc = viewModel.createFromTemplate(templateId: template.id, values: values) else { return }
        createdDocument = doc
        navigateToEditor = true
    }
}

// MARK: - PlaceholderFieldView

private struct PlaceholderFieldView: View {
    let placeholder: Placeholder
    @Binding var values: [String: String]

    private var binding: Binding<String> {
        Binding(
            get: { values[placeholder.key] ?? "" },
            set: { values[placeholder.key] = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text(placeholder.label)
                    .font(.subheadline.weight(.medium))
                if placeholder.required {
                    Text("*")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }

            if !placeholder.description.isEmpty {
                Text(placeholder.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField(
                placeholder.defaultValue ?? placeholder.label,
                text: binding
            )
            .textInputAutocapitalization(.sentences)
        }
        .padding(.vertical, 2)
    }
}
