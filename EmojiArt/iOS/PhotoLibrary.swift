//
//  PhotoLibrary.swift
//  EmojiArt
//
//  Created by Joshua Galvan on 4/23/23.
//

#if os(iOS)
import SwiftUI
import PhotosUI

struct PhotoLibrary: UIViewControllerRepresentable {
    var handlePickedImage: (UIImage?) -> Void
    
    static var isAvailable: Bool {
        return true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(handlePickedImage: handlePickedImage)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Nothing to do.
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var handlePickedImage: (UIImage?) -> Void

        init(handlePickedImage: @escaping (UIImage?) -> Void) {
            self.handlePickedImage = handlePickedImage
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let found = results.map { $0.itemProvider }.loadObjects(ofType: UIImage.self) { [weak self] image in
                self?.handlePickedImage(image)
            }
            if !found {
                handlePickedImage(nil)
            }
        }
    }
}
#endif
