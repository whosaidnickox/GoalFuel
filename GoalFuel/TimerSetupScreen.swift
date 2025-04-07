import SwiftUI

struct TimerSetupScreen: View {
    @State private var selectedLevel: TimerLevel = .intermediate
    @State private var selectedFocus: TimerFocus = .speed
    @State private var selectedDurationMinutes: Int = 60
    @State private var intensity: Double = 0.5 // 0.0 (Low) to 1.0 (High)
    @State private var navigateToActiveTimer = false
    @State private var description: String = "" // Добавляем для ввода описания

    enum TimerLevel: String, CaseIterable, Identifiable, Hashable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        var id: String { self.rawValue }
        // Иконки из AddTrainingScreen
        var iconName: String {
             switch self {
             case .beginner: return "starBeginner"
             case .intermediate: return "starIntermediate"
             case .advanced: return "starAdvanced"
             }
         }
    }

    enum TimerFocus: String, CaseIterable, Identifiable, Hashable {
        case speed = "Speed"
        case agility = "Agility"
        case strength = "Strength"
        case endurance = "Endurance"
        case ballControl = "Ball Control"
        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView { // Нужен для NavigationLink
            ZStack {
                AppColors.background.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Используем существующий HeaderView
                    HeaderView(title: "Timer")

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Выбор уровня
                            SelectionGroupView(
                                title: "Select Training Level",
                                items: TimerLevel.allCases,
                                selectedItem: $selectedLevel,
                                columnsCount: 3
                            ) { item in
                                VStack(spacing: 8) {
                                    Image(item.iconName)
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .frame(height: 18)
                                        .foregroundColor(
                                            selectedLevel == item ? AppColors.background : .white
                                        )
                                    Text(item.rawValue)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                        .foregroundColor(
                                            selectedLevel == item ? AppColors.background : .white
                                        )
                                }
                            }

                            // Выбор фокуса (используем Grid с 2 колонками)
                            SelectionGroupView(
                                title: "Exercise Focus",
                                items: TimerFocus.allCases,
                                selectedItem: $selectedFocus,
                                columnsCount: 3
                            ) { item in
                                HStack(spacing: 10) {
                                     Text(item.rawValue)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                 }
                             }

                            // Выбор длительности (пока используем Stepper, можно заменить на кастомный слайдер или выбор)
                            DurationSelector(title: "Training Duration", minutes: $selectedDurationMinutes)

                            // Выбор интенсивности (Slider)
                            IntensitySelector(title: "Training Intensity", intensity: $intensity)
                            
                            // Добавляем поле для ввода описания
                            DescriptionField(title: "Description", text: $description)
                        }
                        .padding()
                        
                        // Кнопка Start
                        NavigationLink(
                            destination: TimerActiveScreen(durationSeconds: selectedDurationMinutes * 60),
                            isActive: $navigateToActiveTimer
                        ) {
                            EmptyView() // Ссылка активируется программно
                        }
                        Button("Start!") {
                            navigateToActiveTimer = true // Активируем NavigationLink
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accent)
                        .cornerRadius(12)
                        .padding()
                        .padding(.bottom, 85)

                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack) // Важно для правильной работы NavigationLink
    }
}

// MARK: - Timer Setup Subviews

// Используем существующий SelectionGroupView

struct DurationSelector: View {
    let title: String
    @Binding var minutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)

            HStack {
                Text("\(minutes) minutes")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                Stepper("", value: $minutes, in: 5...120, step: 5) // Шаг 5 минут
                    .labelsHidden()
            }
            .padding()
            .background(AppColors.tabbarBackground)
            .cornerRadius(12)
        }
    }
}

struct IntensitySelector: View {
    let title: String
    @Binding var intensity: Double // 0.0 to 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)

            VStack(spacing: 8) {
                Slider(value: $intensity, in: 0...1)
                    .accentColor(AppColors.accent)
                
                HStack {
                    Text("Low")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Spacer()
                    Text("High")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(AppColors.tabbarBackground)
            .cornerRadius(12)
        }
    }
}

// Новый компонент для поля ввода описания
struct DescriptionField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
            
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .frame(height: 100)
                .foregroundColor(.white)
                .padding(12)
                .background(AppColors.tabbarBackground)
                .cornerRadius(12)
                .overlay(
                    text.isEmpty ? Text("Enter description")
                        .foregroundColor(AppColors.secondaryText.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false) : nil,
                    alignment: .topLeading
                )
        }
    }
}

// MARK: - Preview

struct TimerSetupScreen_Previews: PreviewProvider {
    static var previews: some View {
        TimerSetupScreen()
            .preferredColorScheme(.dark)
    }
} 
