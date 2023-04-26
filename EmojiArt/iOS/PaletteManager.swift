//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by Joshua Galvan on 4/8/23.
//

#if os(iOS)
import SwiftUI

struct PaletteManager: View {
    @EnvironmentObject var store: PaletteStore
    @State private var editMode: EditMode = .inactive

    @Environment(\.isPresented) var isPresented
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.palettes) { palette in
                    NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])) {
                        VStack(alignment: .leading) {
                            Text(palette.name)
                            Text(palette.emojis)
                        }
                    }
                }
                .onDelete { indexSet in
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove { indexSet, newOffset in
                    store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
                }
            }
            .navigationTitle("Manage Palettes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem { EditButton() }
                ToolbarItem(placement: .navigationBarLeading) {
                    // iOS has a default back button chevron, but a "Close" button looks better on
                    // iPad.
                    if isPresented, UIDevice.current.userInterfaceIdiom == .pad {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
            .hideBackButtonIfOnIPad()
            .environment(\.editMode, $editMode)
        }
    }

}

struct PaletteManager_Previews: PreviewProvider {
    static var previews: some View {
        PaletteManager()
            .environmentObject(PaletteStore(named: "Preview"))
    }
}
#endif
