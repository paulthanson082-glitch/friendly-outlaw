import SwiftUI
import PencilKit
import CoreData

// MARK: - Main App Entry
@main
struct ProNotesApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var noteStore: NoteStore

    init() {
        let controller = PersistenceController.shared
        _noteStore = StateObject(wrappedValue: NoteStore(persistenceController: controller))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(noteStore)
        }
    }
}

// MARK: - Core Data Stack
class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        for i in 0..<5 {
            let note = NoteEntity(context: viewContext)
            note.id = UUID()
            note.title = "Sample Note \(i + 1)"
            note.content = "This is sample content for note \(i + 1)"
            note.createdAt = Date()
            note.modifiedAt = Date()
        }

        try? viewContext.save()
        return controller
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ProNotes")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Swift Model
struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var canvasData: Data?
    var createdAt: Date
    var modifiedAt: Date
    var tags: [String]

    init(
        id: UUID = UUID(),
        title: String = "Untitled",
        content: String = "",
        canvasData: Data? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.canvasData = canvasData
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.tags = tags
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Core Data Model Extension
extension NoteEntity {
    func toNote() -> Note {
        Note(
            id: id ?? UUID(),
            title: title ?? "Untitled",
            content: content ?? "",
            canvasData: canvasData,
            createdAt: createdAt ?? Date(),
            modifiedAt: modifiedAt ?? Date(),
            tags: (tags as? [String]) ?? []
        )
    }

    func update(from note: Note) {
        self.id = note.id
        self.title = note.title
        self.content = note.content
        self.canvasData = note.canvasData
        self.createdAt = note.createdAt
        self.modifiedAt = Date()
        self.tags = note.tags as NSArray
    }

    static func create(from note: Note, in context: NSManagedObjectContext) -> NoteEntity {
        let entity = NoteEntity(context: context)
        entity.update(from: note)
        return entity
    }
}

// MARK: - Note Store
class NoteStore: ObservableObject {
    private let persistenceController: PersistenceController
    private var viewContext: NSManagedObjectContext

    @Published var notes: [Note] = []

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.viewContext = persistenceController.container.viewContext
        fetchNotes()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedObjectContextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }

    func fetchNotes() {
        let request = NoteEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NoteEntity.modifiedAt, ascending: false)]

        do {
            let entities = try viewContext.fetch(request)
            notes = entities.map { $0.toNote() }
        } catch {
            print("Error fetching notes: \(error)")
        }
    }

    func addNote(_ note: Note) {
        _ = NoteEntity.create(from: note, in: viewContext)
        persistenceController.save()
        fetchNotes()
    }

    func updateNote(_ note: Note) {
        let request = NoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)

        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                entity.update(from: note)
                persistenceController.save()
                fetchNotes()
            }
        } catch {
            print("Error updating note: \(error)")
        }
    }

    func deleteNote(_ note: Note) {
        let request = NoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)

        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                viewContext.delete(entity)
                persistenceController.save()
                fetchNotes()
            }
        } catch {
            print("Error deleting note: \(error)")
        }
    }

    func searchNotes(query: String) -> [Note] {
        guard !query.isEmpty else { return notes }

        let request = NoteEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@",
            query, query
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NoteEntity.modifiedAt, ascending: false)]

        do {
            let entities = try viewContext.fetch(request)
            return entities.map { $0.toNote() }
        } catch {
            print("Error searching notes: \(error)")
            return []
        }
    }

    @objc private func managedObjectContextDidSave(notification: Notification) {
        DispatchQueue.main.async {
            self.fetchNotes()
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var selectedNote: Note?

    var body: some View {
        NavigationSplitView {
            NoteListView(selectedNote: $selectedNote)
        } detail: {
            if let note = selectedNote {
                NoteEditorView(note: binding(for: note))
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "note.text")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    Text("Select a note or create a new one")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func binding(for note: Note) -> Binding<Note> {
        guard let index = noteStore.notes.firstIndex(where: { $0.id == note.id }) else {
            return .constant(note)
        }
        return Binding(
            get: { noteStore.notes[index] },
            set: { updatedNote in
                noteStore.notes[index] = updatedNote
                noteStore.updateNote(updatedNote)
            }
        )
    }
}

// MARK: - Note List Sidebar
struct NoteListView: View {
    @EnvironmentObject var noteStore: NoteStore
    @Binding var selectedNote: Note?
    @State private var searchText = ""

    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return noteStore.notes
        }
        return noteStore.searchNotes(query: searchText)
    }

    var body: some View {
        List(selection: $selectedNote) {
            ForEach(filteredNotes) { note in
                NoteRowView(note: note)
                    .tag(note)
            }
            .onDelete(perform: deleteNotes)
        }
        .navigationTitle("Notes")
        .searchable(text: $searchText, prompt: "Search notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: createNewNote) {
                    Label("New Note", systemImage: "square.and.pencil")
                }
            }
        }
    }

    private func createNewNote() {
        let newNote = Note(title: "New Note")
        noteStore.addNote(newNote)
        selectedNote = newNote
    }

    private func deleteNotes(at offsets: IndexSet) {
        offsets.forEach { index in
            let note = filteredNotes[index]
            noteStore.deleteNote(note)
            if selectedNote?.id == note.id {
                selectedNote = nil
            }
        }
    }
}

// MARK: - Note Row
struct NoteRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)

            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(note.modifiedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Note Editor
struct NoteEditorView: View {
    @Binding var note: Note
    @State private var showingCanvas = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Title", text: $note.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)

                Spacer()

                Button(action: { showingCanvas.toggle() }) {
                    Label(
                        showingCanvas ? "Text" : "Draw",
                        systemImage: showingCanvas ? "keyboard" : "pencil.tip"
                    )
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            if showingCanvas {
                CanvasView(canvasData: $note.canvasData)
            } else {
                TextEditor(text: $note.content)
                    .font(.body)
                    .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Canvas View (Apple Pencil)
struct CanvasView: View {
    @Binding var canvasData: Data?
    @State private var canvasView = PKCanvasView()

    var body: some View {
        CanvasRepresentable(canvasView: canvasView, canvasData: $canvasData)
    }
}

struct CanvasRepresentable: UIViewRepresentable {
    let canvasView: PKCanvasView
    @Binding var canvasData: Data?

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)

        if let data = canvasData,
           let drawing = try? PKDrawing(data: data) {
            canvasView.drawing = drawing
        }

        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasRepresentable

        init(_ parent: CanvasRepresentable) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.canvasData = canvasView.drawing.dataRepresentation()
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NoteStore(persistenceController: .preview))
}
