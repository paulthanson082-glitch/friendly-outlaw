import Foundation

// MARK: - ImageStore

/// Thread-safe actor for image metadata persistence
public actor ImageStore {
    private var images: [String: ImageInfo] = [:]
    private var loaded = false

    public init() {}

    public func load() throws {
        guard !loaded else { return }
        try MockerConfig.ensureDirectories()
        let all = try MockerPersistence.loadAll(ImageInfo.self, fromDirectory: MockerConfig.imagesDir)
        for img in all {
            images[img.id] = img
        }
        loaded = true
    }

    private func save(_ image: ImageInfo) throws {
        try MockerPersistence.save(image, to: MockerConfig.imagePath(id: image.id))
    }

    public func add(_ image: ImageInfo) throws {
        images[image.id] = image
        try save(image)
    }

    public func update(_ image: ImageInfo) throws {
        images[image.id] = image
        try save(image)
    }

    public func remove(id: String) throws {
        images.removeValue(forKey: id)
        try MockerPersistence.delete(at: MockerConfig.imagePath(id: id))
    }

    public func get(id: String) -> ImageInfo? {
        images[id]
    }

    public func getAll() -> [ImageInfo] {
        Array(images.values).sorted { $0.createdAt > $1.createdAt }
    }

    /// Find image by ID, short ID, or reference (repo:tag)
    public func find(_ identifier: String) -> ImageInfo? {
        if let img = images[identifier] { return img }
        if let img = images.values.first(where: { $0.id.hasPrefix(identifier) }) { return img }
        if let img = images.values.first(where: { $0.reference == identifier }) { return img }
        // Try with implicit :latest tag
        if !identifier.contains(":"),
           let img = images.values.first(where: { $0.reference == "\(identifier):latest" }) {
            return img
        }
        return nil
    }

    /// Find images by repository name (all tags)
    public func findByRepository(_ repo: String) -> [ImageInfo] {
        images.values.filter { $0.repository == repo }
    }

    /// Check if image reference already exists
    public func referenceExists(repository: String, tag: String) -> Bool {
        images.values.contains { $0.repository == repository && $0.tag == tag }
    }
}
