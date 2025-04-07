import SwiftUI
import Combine

// Переносим PreferenceKey наружу
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { }
}

// Выносим ViewModifier наружу
struct ReadSizeModifier: ViewModifier {
    var onChange: (CGSize) -> Void

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
                    .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
            }
        )
    }
}

struct AddTrainingScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var showAlert = false
    @State private var alertMessage = ""

    @State private var trainingName: String = ""
    @State private var description: String = ""
    @State private var selectedLevel: DifficultyLevel = .intermediate
    @State private var selectedGoal: TrainingGoal = .agility
    @State private var selectedDuration: TrainingDuration = .min45

    // Enums должны быть Hashable для FlexibleView
    enum DifficultyLevel: String, CaseIterable, Identifiable, Hashable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        var id: String { self.rawValue }

        var iconName: String {
            switch self {
            case .beginner: return "starBeginner"
            case .intermediate: return "starIntermediate"
            case .advanced: return "starAdvanced"
            }
        }
    }

    enum TrainingGoal: String, CaseIterable, Identifiable, Hashable {
        case speed = "Speed"
        case strength = "Strength"
        case agility = "Agility"
        case ballControl = "Ball Control"
        var id: String { self.rawValue }

        var iconName: String {
            switch self {
            case .speed: return "speedIcon"
            case .strength: return "strenghtIcon"
            case .agility: return "agilityIcon"
            case .ballControl: return "ballIcon"
            }
        }
    }

    enum TrainingDuration: String, CaseIterable, Identifiable, Hashable {
        case min30 = "30 min"
        case min45 = "45 min"
        case min60 = "60 min"
        var id: String { self.rawValue }
    }

    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
                .ignoresSafeArea(.keyboard)
            
            VStack(spacing: 0) {
                HeaderView(title: "Create Training", backAction: {
                    dismiss()
                })
                // .ignoresSafeArea(.container, edges: .top) // Убираем, чтобы фон под хедером был системным

                ScrollView {
                    // Увеличиваем spacing для VStack, чтобы соответствовать Figma
                    VStack(alignment: .leading, spacing: 24) {
                        TitledTextField(
                            title: "Training Name",
                            placeholder: "Enter training name",
                            text: $trainingName
                        )
                        // Используем SelectionGroupView с указанием колонок
                        SelectionGroupView(
                            title: "Difficulty Level",
                            items: DifficultyLevel.allCases,
                            selectedItem: $selectedLevel,
                            columnsCount: 3
                        ) { item in
                            VStack(spacing: 8) {
                                Image(item.iconName)
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit().frame(height: 18)
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

                        SelectionGroupView(title: "Training Goal", items: TrainingGoal.allCases, selectedItem: $selectedGoal, columnsCount: 2) { item in
                             VStack(spacing: 8) {
                                 Image(item.iconName)
                                     .resizable()
                                     .renderingMode(.template)
                                     .scaledToFit()
                                     .frame(height: 20)
                                     .foregroundColor(
                                        selectedGoal == item ? AppColors.background : .white
                                     )
                                 Text(item.rawValue)
                                     .foregroundColor(
                                        selectedGoal == item ? AppColors.background : .white
                                     )
                             }
                         }

                        SelectionGroupView(title: "Estimated Duration", items: TrainingDuration.allCases, selectedItem: $selectedDuration, columnsCount: 3) { item in
                             Text(item.rawValue)
                         }
                        
                        TitledTextField(title: "Description", placeholder: "Description", text: $description, isTextView: true)

                        // Кнопка Save
                        Button(action: saveTraining) {
                            Text("Save Training")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.accent)
                                .cornerRadius(12)
                        }
                        .padding(.top, 16)
                        .ignoresSafeArea(.keyboard)
                    }
                    .padding(.horizontal) // Отступы для всего контента ScrollView
                    .padding(.bottom, 85)
                }
                .modifier(NumberPadDoneButton())
                .ignoresSafeArea(.keyboard)
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Training Saved"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    dismiss() // Возвращаемся к списку тренировок
                }
            )
        }
    }
    
    // Функция для сохранения новой тренировки
    private func saveTraining() {
        // Проверка, что имя тренировки не пустое
        guard !trainingName.isEmpty else {
            alertMessage = "Please enter a training name"
            showAlert = true
            return
        }
        
        // Создаем новую тренировку
        let newTraining = TrainingProgram(
            name: trainingName,
            description: description.isEmpty ? "No description" : description,
            level: selectedLevel.rawValue,
            duration: selectedDuration.rawValue,
            iconName: selectedGoal.iconName
        )
        
        // Загружаем существующие пользовательские тренировки (не дефолтные)
        var savedTrainings: [TrainingProgram] = []
        if let savedData = UserDefaults.standard.data(forKey: "savedTrainings") {
            if let decodedTrainings = try? JSONDecoder().decode([TrainingProgram].self, from: savedData) {
                savedTrainings = decodedTrainings
            }
        }
        
        // Добавляем новую тренировку
        savedTrainings.append(newTraining)
        
        // Сохраняем обновленный список
        if let encodedData = try? JSONEncoder().encode(savedTrainings) {
            UserDefaults.standard.set(encodedData, forKey: "savedTrainings")
            alertMessage = "Your training has been successfully saved"
            showAlert = true
        } else {
            alertMessage = "Failed to save training"
            showAlert = true
        }
    }
}

// MARK: - Reusable Subviews

struct TitledTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isTextView: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)

            if isTextView {
                TextEditor(text: $text)
                     .scrollContentBackground(.hidden) // Делаем фон TextEditor прозрачным
                     .frame(height: 100)
                     .foregroundColor(.white)
                     .padding(12)
                     .background(AppColors.tabbarBackground)
                     .cornerRadius(12)
                     .overlay( // Показываем плейсхолдер, если текст пуст
                         text.isEmpty ? Text(placeholder).foregroundColor(AppColors.tertiaryText).padding(18).allowsHitTesting(false) : nil,
                         alignment: .topLeading
                     )
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder).foregroundColor(AppColors.tertiaryText)
                    }
                    .padding(12)
                    .background(AppColors.tabbarBackground)
                    .cornerRadius(12)
            }
        }
    }
}

// Переделываем SelectionGroupView с LazyVGrid
struct SelectionGroupView<Item: Identifiable & Equatable & RawRepresentable & Hashable>: View where Item.RawValue == String {
    let title: String
    let items: [Item]
    @Binding var selectedItem: Item
    let columnsCount: Int // Добавляем параметр для количества колонок
    @ViewBuilder let labelContent: (Item) -> any View

    // Создаем колонки для Grid
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columnsCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)

            // Используем LazyVGrid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        AnyView(labelContent(item))
                            .frame(maxWidth: .infinity) // Растягиваем кнопку на всю ширину колонки
                            .font(.system(size: 14))
                            .foregroundColor(selectedItem == item ? AppColors.background : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(selectedItem == item ? AppColors.accent : AppColors.tabbarBackground)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain) // Убираем стандартный стиль кнопки, если нужно
                }
            }
        }
    }
}

// MARK: - Preview

struct AddTrainingScreen_Previews: PreviewProvider {
    static var previews: some View {
        AddTrainingScreen()
             .preferredColorScheme(.dark)
    }
} 
