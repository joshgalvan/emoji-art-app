//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Joshua Galvan on 3/29/23.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

extension UTType {
    static let emojiart = UTType(exportedAs: "galvan.joshua.app.emojiart")
}

class EmojiArtDocument: ReferenceFileDocument {
    static var readableContentTypes = [UTType.emojiart]
    static var writeableContentTypes = [UTType.emojiart]
    
    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            emojiArt = try EmojiArtModel(json: data)
            fetchBackgroundImageDataIfNecessary()
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func snapshot(contentType: UTType) throws -> Data {
        try emojiArt.json()
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
    
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    init() {
        emojiArt = EmojiArtModel()
    }
    
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    
    var background: EmojiArtModel.Background { emojiArt.background }
    
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }
    
    private var backgroundImageFetchCancellable: AnyCancellable?
    
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch background {
        case .url(let url):
            // Publisher & URLSession solution to URL fetching.
            backgroundImageFetchStatus = .fetching
            // Cancel the last fetch to start a new one.
            backgroundImageFetchCancellable?.cancel()
            let session = URLSession.shared
            // Once the publisher has no more subscribers it will go away. Its only subscriber is
            // the `backgroundImageFetchCancellable` var declared in the scope of the class.
            let publisher = session.dataTaskPublisher(for: url)
                .map { (data, response) in UIImage(data: data) }
                .replaceError(with: nil)
                // Always publish to subscribers on the main queue. This means the `sink`
                // code below will happen on the main queue.
                .receive(on: DispatchQueue.main)
            
            // The lifetime of this var is attached to the lifetime of our EmojiArtDocument.
            // If a user were to ever close this document in the app, this subscriber would
            // also cease, which is exactly what we want. That's why this var is created
            // outside the scope of this function.
            backgroundImageFetchCancellable = publisher
                .sink { [weak self] image in
                    self?.backgroundImage = image
                    self?.backgroundImageFetchStatus = (image != nil) ? .idle : .failed(url)
                }
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    //  MARK: Intents
    
    func setBackground(_ background: EmojiArtModel.Background, undoManager: UndoManager?) {
        undoablyPerform(operation: "Set Background", with: undoManager) {
            emojiArt.background = background
        }
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat, undoManager: UndoManager?) {
        undoablyPerform(operation: "Add \(emoji)", with: undoManager) {
            emojiArt.addEmoji(emoji, at: location, size: Int(size))
        }
    }
    
    func removeEmojiWithID(id: Int, undoManager: UndoManager?) {
        let emoji = emojiArt.emojis.first(where: { $0.id == id })!.text
        undoablyPerform(operation: "Remove \(emoji)", with: undoManager) {
            emojiArt.removeEmojiWithID(id: id)
        }
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablyPerform(operation: "Move", with: undoManager) {
                emojiArt.emojis[index].x += Int(offset.width)
                emojiArt.emojis[index].y += Int(offset.height)
            }
        }
    }
    
    func moveEmojiWithID(_ id: Int, by offset: CGSize, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.firstIndex(where: {$0.id == id}) {
            undoablyPerform(operation: "Move", with: undoManager) {
                emojiArt.emojis[index].x = emojiArt.emojis[index].x + Int(offset.width)
                emojiArt.emojis[index].y = emojiArt.emojis[index].y + Int(offset.height)
            }
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablyPerform(operation: "Scale", with: undoManager) {
                emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale)
                    .rounded(.toNearestOrAwayFromZero))
            }
        }
    }
    
    func scaleEmojiWithID(_ id: Int, by scale: CGFloat, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.firstIndex(where: {$0.id == id}) {
            undoablyPerform(operation: "Scale", with: undoManager) {
                emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale)
                    .rounded(.toNearestOrAwayFromZero))
            }
        }
    }
    
    // MARK: Undo
    
    private func undoablyPerform(operation: String, with undoManager: UndoManager? = nil, doit: () -> Void) {
        let oldEmojiArt = emojiArt
        doit()
        undoManager?.registerUndo(withTarget: self) { myself in
            myself.undoablyPerform(operation: operation, with: undoManager) {
                myself.emojiArt = oldEmojiArt
            }
        }
        undoManager?.setActionName(operation)
    }
    
}
