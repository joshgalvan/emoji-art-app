//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Joshua Galvan on 3/29/23.
//

import Foundation

struct EmojiArtModel: Codable {
    var background = Background.blank
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable, Hashable, Codable {
        let text: String
        var x: Int // offset from the center
        var y: Int // offset from the center
        var size: Int
        var id: Int
        
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    init() { }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArtModel.self, from: json)
    }
    
    init(url: URL) throws {
        // Blocking on the main queue for a file URL is okay.
        let data = try Data(contentsOf: url)
        self = try EmojiArtModel(json: data)
    }
    
    private var uniqueEmojiID = 0
    
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiID += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiID))
    }
    
    mutating func removeEmojiWithID(id: Int) {
        if let index = emojis.firstIndex(where: { $0.id == id }) {
            emojis.remove(at: index)
        }
    }
}
