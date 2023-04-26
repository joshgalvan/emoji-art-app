//
//  PaletteStore.swift
//  EmojiArt
//
//  Created by Joshua Galvan on 4/7/23.
//

import SwiftUI

struct Palette: Identifiable, Codable, Hashable {
    var name: String
    var emojis: String
    var id: Int
        
    fileprivate init(name: String, emojis: String, id: Int) {
        self.name = name
        self.emojis = emojis
        self.id = id
    }
}

class PaletteStore: ObservableObject {
    let name: String
    
    @Published var palettes = [Palette]() {
        didSet {
            storeInUserDefaults()
        }
    }
    
    private var userDefaultsKey: String {
        "PaletteStore:" + name
    }
    
    private func storeInUserDefaults() {
        UserDefaults.standard.set(try? JSONEncoder().encode(palettes), forKey: userDefaultsKey)
    }
    
    private func restoreFromUserDefaults() {
        if let jsonData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedPalettes = try? JSONDecoder().decode([Palette].self, from: jsonData) {
               palettes = decodedPalettes
           }
    }
    
    init(named name: String) {
        self.name = name
        restoreFromUserDefaults()
        // Ensure some default config
        if palettes.isEmpty {
            insertPalette(named: "Vehicles", emojis: "🚗🚕🚙🚎🏎️🚓🚑🚒🚐🛻🚚🚛🚜🛵🏍️🛺🚝🚄🚅🚈🚂🛫🛬🚀🛸🚁🚤🛥️🛳️⛴️🚢")
            insertPalette(named: "Sports", emojis: "⚽️🏀🏈⚾️🥎🎾🏐🏉🥏🎱🪀🏓⛳️🏂🎳")
            insertPalette(named: "Music", emojis: "🎶🎼🎵🎤🎧🎸🥁🎹🎺🎻🪕")
            insertPalette(named: "Animals", emojis: "🐈🐈‍⬛🐕‍🦺🦮🐕🐩🐇🐀🐁🦔🐿️🦝🦡🐖🐄🐂🐃🐎🐐🐍🐝🐒🦍🦅🐥🐣🐟🦆🐢🐞🦖🐠🐓🐅🦃🐑🐬🐘🦎🦌🐜")
            insertPalette(named: "Animal Faces", emojis: "🐶🐱🐭🐹🐰🦊🐻🐼🐻‍❄️🐨🐯🦁🐮🐷🐸🐵🙈🙉🙊")
            insertPalette(named: "Flora", emojis: "🌹🌸🎄💐🌺🌷🌻🍀🌲🥀🌴🌼☘️🌿🌱🌵🌳")
            insertPalette(named: "Weather", emojis: "☁️☀️🌤️🌥️⛅️🌦️🌧️🌨️⛈️🌩️⚡️☔️☂️❄️🌪️💨🌈")
            insertPalette(named: "COVID", emojis: "🤒🤧😷💉🦠")
            insertPalette(named: "Faces", emojis: "😀😃😄😁😆🥹😅😂🤣🥲☺️😊😇🙂🙃😘🥰😍😌😉😛😋😚😙😗🧐🤨🤪😜😝🥳🤩🥸😎🤓😟😔😞😒😏😖😣☹️🙁😕😭😢🥺😩😫🤯😡😠😤😳🥵🥶😶‍🌫️😱😰😨😓🤗🤢🤕😵‍💫😴🥱😵")
        } else {
            print("loaded from UserDefaults")
        }
    }
    
    // - MARK: Intent
    
    // Always returns some inbounds palette.
    func palette(at index: Int) -> Palette {
        let safeIndex = min(max(index, 0), palettes.count - 1)
        return palettes[safeIndex]
    }
    
    // Does not allow removal of last element. Always at least one palette in existence.
    @discardableResult
    func removePalette(at index: Int) -> Int {
        if palettes.count > 1, palettes.indices.contains(index) {
            palettes.remove(at: index)
        }
        return index % palettes.count
    }
    
    // Ensures unique ID.
    func insertPalette(named name: String, emojis: String? = nil, at index: Int = 0) {
        let unique = (palettes.max(by: { $0.id < $1.id })?.id ?? 0) + 1
        let palette = Palette(name: name, emojis: emojis ?? "", id: unique)
        let safeIndex = min(max(index, 0), palettes.count)
        palettes.insert(palette, at: safeIndex)
    }
    
}
