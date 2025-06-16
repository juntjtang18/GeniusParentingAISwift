//
//  ImagePicker.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/6/15.
//

import Foundation
import SwiftUI

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
