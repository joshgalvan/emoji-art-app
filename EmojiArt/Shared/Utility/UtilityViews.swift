//
//  UtilityViews.swift
//  EmojiArt
//
//  Created by Joshua Galvan on 3/29/23.
//

import SwiftUI

struct ConditionallyShowingButton<T>: View where T: View{
    var condition: Bool
    var content: () -> T
    
    init(isShowing: Bool, @ViewBuilder content: @escaping () -> T) {
        self.condition = isShowing
        self.content = content
    }
    
    var body: some View {
        if condition {
            content()
        } else {
            Color.clear
        }
    }
}

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        if let uiImage {
            Image(uiImage: uiImage)
        }
    }
}

struct AnimatedActionButton: View {
    var title: String? = nil
    var systemImage: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            if title != nil && systemImage != nil {
                // Labels have a title and some image.
                Label(title!, systemImage: systemImage!)
            } else if title != nil {
                Text(title!)
            } else if systemImage != nil {
                Image(systemName: systemImage!)
            }
        }
    }
}

struct IdentifiableAlert: Identifiable {
    var id: String
    var alert: () -> Alert
    
    init(id: String, alert: @escaping () -> Alert) {
        self.id = id
        self.alert = alert
    }
    
    init(id: String, title: String, message: String) {
        self.id = id
        alert = { Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK"))) }
    }
    
    init(title: String, message: String) {
        self.id = title + message
        alert = { Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK"))) }
    }
}

struct UndoButton: View {
    let undo: String?
    let redo: String?
    
    @Environment(\.undoManager) var undoManager
    
    var body: some View {
        let canUndo = undoManager?.canUndo ?? false
        let canRedo = undoManager?.canRedo ?? false
        if canUndo || canRedo {
            Button {
                if canUndo {
                    undoManager?.undo()
                } else {
                    undoManager?.redo()
                }
            } label: {
                if canUndo {
                    Image(systemName: "arrow.uturn.backward.circle")
                } else {
                    Image(systemName: "arrow.uturn.forward.circle")
                }
            }
            .contextMenu {
                if canUndo {
                    Button {
                        undoManager?.undo()
                    } label: {
                        Label(undo ?? "Undo", systemImage: "arrow.uturn.backward")
                    }
                }
                if canRedo {
                    Button {
                        undoManager?.redo()
                    } label: {
                        Label(redo ?? "Redo", systemImage: "arrow.uturn.forward")
                    }
                }
            }
        }
    }
}

extension UndoManager {
    var optionalUndoMenuItemTitle: String? {
        canUndo ? undoMenuItemTitle : nil
    }
    
    var optionalRedoMenuItemTitle: String? {
        canRedo ? redoMenuItemTitle : nil
    }
}

extension View {
    func compactableToolbar<Content>(@ViewBuilder content: () -> Content) -> some View where Content: View {
        self.toolbar {
            content().modifier(CompactableIntoContextMenu())
        }
    }
}

struct CompactableIntoContextMenu: ViewModifier {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var compact: Bool { horizontalSizeClass == .compact }
    #else
    let compact = false
    #endif
    
    func body(content: Content) -> some View {
        if compact {
            Button { } label: {
                Image(systemName: "ellipsis.circle")
            }
            .contextMenu {
                content
            }
        } else {
            content
        }
    }
}
