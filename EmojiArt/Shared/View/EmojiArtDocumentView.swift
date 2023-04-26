//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Joshua Galvan on 3/29/23.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    
    @Environment(\.undoManager) var undoManager
    
    @ObservedObject var document: EmojiArtDocument
    
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
    
    @State private var selectedEmojisID = Set<Int>()
    
    // MARK: Views
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                documentBody
                deleteButton
            }
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
        }
    }

    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                OptionalImage(uiImage: document.backgroundImage)
                    .scaleEffect(zoomScale)
                    .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                    .gesture(doubleTapToZoom(in: geometry.size))
                
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                    
                } else {
                    ForEach(document.emojis) { emoji in
                        if selectedEmojisID.contains(emoji.id) {
                            let circleScale = 1.5
                            Circle()
                                .strokeBorder(lineWidth: 2 / gestureEmojiScale)
                                .frame(width: CGFloat(emoji.size) * circleScale, height: CGFloat(emoji.size) * circleScale)
                                .foregroundColor(.black)
                                .opacity(0.50)
                                .scaleEffect(zoomScale * gestureEmojiScale)
                                .position(position(for: emoji, in: geometry))
                        }
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale * (selectedEmojisID.contains(emoji.id) ? gestureEmojiScale : 1))
                            .position(position(for: emoji, in: geometry))
                            .onTapGesture {
                                if selectedEmojisID.contains(emoji.id) {
                                    selectedEmojisID.remove(emoji.id)
                                } else {
                                    selectedEmojisID.insert(emoji.id)
                                }
                            }
                    }
                }
                
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            .gesture(selectedEmojisID.isEmpty ? panGesture().simultaneously(with: zoomGesture()) : nil)
            .gesture(selectedEmojisID.isEmpty ? nil : moveEmojis().simultaneously(with: scaleEmojis()))
            .gesture(deselectAllEmojiOnTap())
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) { status in
                switch status {
                case .failed(let url):
                    showBackgroundImageFetchFailedAlert(url)
                default:
                    break
                }
            }
            .onReceive(document.$backgroundImage) { image in
                if autozoom {
                    zoomToFit(image, in: geometry.size)
                }
            }
            .compactableToolbar {
                toolbar
            }
            .sheet(item: $backgroundPicker) { pickerType in
                switch pickerType {
                case .camera: Camera(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                case .library: PhotoLibrary(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                }
            }
        }
    }
    
    var deleteButton: some View {
        ConditionallyShowingButton(isShowing: !selectedEmojisID.isEmpty) {
            Button {
                for id in selectedEmojisID {
                    document.removeEmojiWithID(id: id, undoManager: undoManager)
                    selectedEmojisID.remove(id)
                }
            } label: {
                Text("Delete")
            }
            #if os(iOS)
            .buttonBorderShape(.capsule)
            #endif
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding()
            .controlSize(.small)
        }
    }
    
    @ViewBuilder
    var toolbar: some View {
        AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
            pasteBackground()
        }
        if Camera.isAvailable {
            AnimatedActionButton(title: "Take Photo", systemImage: "camera") {
                backgroundPicker = .camera
            }
        }
        if PhotoLibrary.isAvailable {
            AnimatedActionButton(title: "Search Photos", systemImage: "photo") {
                backgroundPicker = .library
            }
        }
        #if os(iOS)
        if let undoManager {
            if undoManager.canUndo {
                AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
                    undoManager.undo()
                }
            }
            if undoManager.canRedo {
                AnimatedActionButton(title: undoManager.redoActionName, systemImage: "arrow.uturn.forward") {
                    undoManager.redo()
                }
            }
        }
        #endif
    }
    
    // MARK: Utility Functions
    
    enum BackgroundPickerType: Identifiable {
        case camera
        case library
        var id: BackgroundPickerType { self }
    }
    
    @State private var backgroundPicker: BackgroundPickerType?
    @State private var autozoom = false
    
    private func handlePickedBackgroundImage(_ image: UIImage?) {
        autozoom = true
        if let imageData = image?.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        }
        // Make sheet dismiss automatically when a user taps the desired photo.
        backgroundPicker = nil
    }
    
    private func pasteBackground() {
        autozoom = true
        if let imageData = Pasteboard.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        } else if let url = Pasteboard.imageURL {
            document.setBackground(.url(url), undoManager: undoManager)
        } else {
            alertToShow = IdentifiableAlert(
                title: "Paste Background",
                message: "There is no image currently on the pasteboard."
            )
        }
    }
    
    @State private var alertToShow: IdentifiableAlert?
    
    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed: " + url.absoluteString) {
            Alert(
                title: Text("Background Image Fetch"),
                message: Text("Couldn't load image from \(url)."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            autozoom = true
            document.setBackground(EmojiArtModel.Background.url(url.imageURL), undoManager: undoManager)
        }
        #if os(iOS)
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    autozoom = true
                    document.setBackground(.imageData(data), undoManager: undoManager)
                }
            }
        }
        #endif
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first,  emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale,
                        undoManager: undoManager
                    )
                }
            }
        }
        return found
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        if selectedEmojisID.contains(emoji.id) {
            return convertFromEmojiCoordinates((emoji.x + gestureSelectedEmojiOffset.x, emoji.y + gestureSelectedEmojiOffset.y), in: geometry)
        } else {
            return convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
        }
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    // MARK: Gestures
    
    // Pan Gestures
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
    private var steadyStatePanOffset: CGSize = CGSize.zero
    
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalGestureDragValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalGestureDragValue.translation / zoomScale)
            }
    }
    
    // Emoji Gestures
    
    @GestureState private var gestureSelectedEmojiOffset: (x: Int, y: Int) = (0, 0)
    private func moveEmojis() -> some Gesture {
        DragGesture()
            .updating($gestureSelectedEmojiOffset) { latestEmojiOffset, gestureEmojiOffset, _ in
                let translation = latestEmojiOffset.translation
                gestureEmojiOffset.x = Int(translation.width / zoomScale)
                gestureEmojiOffset.y = Int(translation.height / zoomScale)
            }
            .onEnded { finalOffset in
                for emojiID in selectedEmojisID {
                    document.moveEmojiWithID(emojiID, by: finalOffset.translation / zoomScale, undoManager: undoManager)
                }
            }
    }
    
    @GestureState private var gestureEmojiScale: CGFloat = 1
    private func scaleEmojis() -> some Gesture {
        MagnificationGesture()
            .updating($gestureEmojiScale) { latestEmojiScale, gestureEmojiScale, _ in
                gestureEmojiScale = latestEmojiScale
            }
            .onEnded { gestureEmojiScaleAtEnd in
                for emojiID in selectedEmojisID {
                    document.scaleEmojiWithID(emojiID, by: gestureEmojiScaleAtEnd, undoManager: undoManager)
                }
            }
    }

    private func deselectAllEmojiOnTap() -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                selectedEmojisID = []
            }
    }
    
    // Zoom Gestures
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStateZoomScale: CGFloat = 1
    
    @GestureState private var gestureZoomScale: CGFloat = 1
    private func zoomGesture() -> some Gesture {
        // We need this to be non-discrete so the size of the background can update in real time.
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
            }
            // gestureScaleAtEnd tells you how far user's fingers are apart compared to where they began.
            .onEnded { gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            // Return back to middle
            steadyStatePanOffset = .zero
            // Fit the smallest dimension
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        // All this does is RECOGNIZE the gesture, but doesn't do anything until you add a modifier
        // to it.
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
}

// MARK: Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
