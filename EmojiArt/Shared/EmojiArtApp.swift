//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Joshua Galvan on 4/25/23.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    @StateObject var paletteStore = PaletteStore(named: "Default")
    
    var body: some Scene {
        DocumentGroup(newDocument: { EmojiArtDocument() }) { config in
            EmojiArtDocumentView(document: config.document)
                .environmentObject(paletteStore)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
