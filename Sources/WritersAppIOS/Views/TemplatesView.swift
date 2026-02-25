import SwiftUI
import WritersApp

// MARK: - TemplatesView

struct TemplatesView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var selectedCategory: TemplateCategory? = nil

    private var filtered: [Template] {
        var result = viewModel.templates
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryFilter

                if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filtered) { template in
                        NavigationLink {
                            TemplateDetailView(template: template)
                        } label: {
                            TemplateRowView(template: template)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search templates")
            .navigationTitle("Templates")
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(label: "All", category: nil)
                ForEach(TemplateCategory.allCases, id: \.self) { category in
                    categoryChip(label: category.rawValue, category: category)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func categoryChip(label: String, category: TemplateCategory?) -> some View {
        let isSelected = selectedCategory == category
        return Button(label) {
            selectedCategory = category
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
        .controlSize(.small)
    }
}

// MARK: - TemplateRowView

struct TemplateRowView: View {
    let template: Template

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.headline)
            HStack {
                Text(template.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(template.placeholders.count) fields")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !template.description.isEmpty {
                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}
