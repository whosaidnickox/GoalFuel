import SwiftUI
import Combine

// Расширение для скрытия клавиатуры
extension UIApplication {
    @objc func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Модификатор для добавления кнопки Done над клавиатурой
struct NumberPadDoneButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                addDoneButtonToKeyboard()
            }
    }
    
    private func addDoneButtonToKeyboard() {
        // Создаем ToolBar с кнопкой Done
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        
        // Создаем кнопку Done
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: UIApplication.shared,
            action: #selector(UIApplication.endEditing)
        )
        
        // Добавляем гибкий разделитель, чтобы кнопка была справа
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        keyboardToolbar.items = [flexSpace, doneButton]
        
        // Применяем тулбар ко всем текстовым полям
        UITextField.appearance().inputAccessoryView = keyboardToolbar
        UITextView.appearance().inputAccessoryView = keyboardToolbar
    }
}

// Расширение для скрытия клавиатуры по тапу по бэкграунду
extension View {
    func dismissKeyboardOnTap() -> some View {
        ZStack {
            self
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
                .allowsHitTesting(true)
        }
    }
} 
