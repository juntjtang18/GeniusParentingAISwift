//
//  ImagePicker.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/6/15.
//

import Foundation
import SwiftUI

// --- NEW: UIImage Extension to Fix Orientation ---
extension UIImage {
    /// Normalizes the image orientation to be "up".
    /// This is a robust way to correct images that might otherwise appear rotated or upside down.
    func normalized() -> UIImage {
        // If the orientation is already correct, we don't need to do anything.
        if self.imageOrientation == .up {
            return self
        }

        // Create a new graphics context to draw the image into.
        // This process respects the original orientation and creates a new image
        // with the orientation baked into the pixel data.
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Return the new, normalized image.
        return normalizedImage ?? self
    }
}


// This file can be used for custom image picker logic or helpers if needed in the future.
// For now, we are using the modern PhotosPicker which simplifies the process greatly.
struct ImageHelper {
    // Example function: Convert data to a specific size if needed
    static func resizeImage(data: Data, to size: CGSize) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
