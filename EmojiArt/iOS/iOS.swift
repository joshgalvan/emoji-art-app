//
//  iOS.swift
//  EmojiArt
//
//  Created by Joshua Galvan on 4/25/23.
//

#if os(iOS)
import SwiftUI

extension UIImage {
    var imageData: Data? {
        jpegData(compressionQuality: 1.0)
    }
}

struct Pasteboard {
    static var imageData: Data? {
        UIPasteboard.general.image?.imageData
    }
    static var imageURL: URL? {
        UIPasteboard.general.url?.imageURL
    }
}

extension View {
    func paletteControlButtonStyle() -> some View {
        self
    }
    
    func popoverPadding() -> some View {
        self
    }
    
    @ViewBuilder
    func wrappedInNavigationStackToMakeDismissable() -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad {
            NavigationStack {
                self
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            self
        }
    }
    
    // Not needed, just part of the lecture. NavigationStack takes care of dismissing for us.
    // Keeping just in case.
    @ViewBuilder
    func dismissable(_ dismiss: (() -> Void)? = nil) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss {
            self.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        } else {
            self
        }
    }
    
    @ViewBuilder
    func hideBackButtonIfOnIPad() -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.navigationBarBackButtonHidden()
        } else {
            self
        }
    }
}
#endif
