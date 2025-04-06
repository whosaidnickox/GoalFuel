import SwiftUI

enum AppColors {
    static let accent = Color(hex: "#BFA166")
    static let background = Color(hex: "#0C193E")
    static let tabbarBackground = Color.white.opacity(0.1) // Пример, нужно уточнить из Figma
    static let tabIconInactive = Color.white.opacity(0.4)
    static let tabIconActive = Color.white // Или accent?
    static let headerGradientStart = Color(hex: "#EBCB88")
    static let headerGradientEnd = Color(hex: "#8B6F3D")
    static let secondaryText = Color(UIColor.systemGray2)
    static let tertiaryText = Color(hex: "#ADAEBC") // Например, цвет плейсхолдера поиска
    // Добавь сюда другие цвета по мере необходимости
}

// Расширение Color для HEX остается здесь, так как оно используется в AppColors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0) // Возвращаем прозрачный цвет в случае ошибки
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 