import Foundation
import SwiftUI

@MainActor
class AnimationHelper {
    
    // Helper for sequencing animations
    static func performAfterAnimation(duration: TimeInterval, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            action()
        }
    }
    
    // Animation durations based on settings
    static func slideDuration(fastMode: Bool) -> Double {
        return fastMode ? 0.005 : 0.05
    }
    
    static func showHideDuration(fastMode: Bool) -> Double {
        return fastMode ? 0.005 : 0.05
    }
}
