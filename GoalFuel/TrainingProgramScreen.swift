import SwiftUI

// MARK: - Training Model
struct TrainingProgram: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let level: String
    let duration: String
    let iconName: String? // Иконка для цели тренировки (опционально)
    var isDefault: Bool = false // Новое свойство для отметки дефолтных тренировок
    
    init(id: UUID = UUID(), name: String, description: String, level: String, duration: String, iconName: String? = nil, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.level = level
        self.duration = duration
        self.iconName = iconName
        self.isDefault = isDefault
    }
}

struct TrainingProgramScreen: View {
    @State private var searchText: String = ""
    @State private var selectedLevel: String = "All Levels"
    @State private var showingAddTrainingSheet = false
    @State private var programs: [TrainingProgram] = []

    let levels = ["All Levels", "Beginner", "Intermediate", "Advanced"]

    var filteredPrograms: [TrainingProgram] {
        if selectedLevel == "All Levels" {
            return programs.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
        } else {
            return programs.filter { $0.level == selectedLevel && (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)) }
        }
    }
    
    // Получить дефолтные тренировки
    private func getDefaultTrainings() -> [TrainingProgram] {
        return [
            TrainingProgram(
                name: "Speed",
                description: "Enhance your quick movements and reactions",
                level: "Intermediate",
                duration: "45 min",
                iconName: "speedIcon",
                isDefault: true
            ),
            TrainingProgram(
                name: "Strength",
                description: "Become strong and success will be with you.",
                level: "Advanced",
                duration: "60 min",
                iconName: "strengthIcon",
                isDefault: true
            ),
            TrainingProgram(
                name: "Ball Control",
                description: "Master fundamental ball control techniques",
                level: "Beginner",
                duration: "30 min",
                iconName: "ballIcon",
                isDefault: true
            )
        ]
    }
    
    // Загрузка тренировок из UserDefaults
    private func loadTrainings() {
        // Сначала получаем дефолтные тренировки
        var allTrainings = getDefaultTrainings()
        
        // Теперь загружаем пользовательские тренировки
        if let savedData = UserDefaults.standard.data(forKey: "savedTrainings") {
            if let decodedTrainings = try? JSONDecoder().decode([TrainingProgram].self, from: savedData) {
                // Добавляем пользовательские тренировки к дефолтным
                allTrainings.append(contentsOf: decodedTrainings)
            }
        }
        
        // Устанавливаем все тренировки
        programs = allTrainings
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                AppColors.background.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Кастомный Header с градиентом
                    HeaderView(title: "Training Programs")

                    // Поиск
                    SearchBar(
                        text: $searchText,
                        placeholder: "Search programs"
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)

                    // Список тренировок
                    ScrollView {
                        // Фильтры по уровню
                        LevelFilterView(
                            levels: levels,
                            selectedLevel: $selectedLevel
                        )
                            .padding(.bottom)

                        LazyVStack(spacing: 15) {
                            ForEach(filteredPrograms) { program in
                                TrainingProgramRow(program: program)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
                
                ZStack(alignment: .bottom) {
                    // Кнопка "Add training" теперь NavigationLink
                    NavigationLink(destination: AddTrainingScreen()) {
                         // Оборачиваем кнопку, чтобы сохранить стиль
                         AddTrainingButton()
                     }
                     .buttonStyle(.plain)
                }
                 .padding(.bottom, 85)
                 .ignoresSafeArea(.keyboard)

            }
            .ignoresSafeArea(.keyboard)
            .navigationBarHidden(true) // Скрываем стандартный Navigation Bar
            .onAppear {
                loadTrainings()
                // Добавляем наблюдатель для сброса данных
                NotificationCenter.default.addObserver(forName: .resetAppData, object: nil, queue: .main) { _ in
                    loadTrainings()
                }
            }
            .onDisappear {
                // Удаляем наблюдатель при закрытии экрана
                NotificationCenter.default.removeObserver(self, name: .resetAppData, object: nil)
            }
        }
    }
}

// MARK: - Subviews

#Preview(body: {
    VStack {
        HeaderView(title: "new title") { }
        Spacer()
    }
})

struct HeaderView: View {
    let title: String
    var backAction: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Фон
            Image("headerBackground")
                .resizable()
                .edgesIgnoringSafeArea(.top)

            // Заголовок (центрирован горизонтально)
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Кнопка назад (если есть)
            if let action = backAction {
                HStack {
                    Button(action: action) {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.gray.opacity(0.5))
                            .overlay {
                                Image(systemName: "arrow.left")
                                    .foregroundColor(.white)
                                    .font(.caption).bold()
                            }
                    }
                    Spacer() // Прижимает кнопку влево
                }
                .padding(.leading, 14) // Отступ сверху для кнопки (можно подстроить)
            }
        }
        .frame(height: 55)
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass") // Стандартная иконка поиска
                .foregroundColor(AppColors.tertiaryText)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .placeholder(when: text.isEmpty) {
                     Text(placeholder).foregroundColor(AppColors.tertiaryText)
                 }
        }
        .padding(12)
        .background(AppColors.tabbarBackground) // Тот же фон, что у таббара и карточек
        .cornerRadius(12)
    }
}

// Helper для плейсхолдера TextField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct LevelFilterView: View {
    let levels: [String]
    @Binding var selectedLevel: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(levels, id: \.self) { level in
                    Button {
                        selectedLevel = level
                    } label: {
                        Text(level)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(selectedLevel == level ? AppColors.accent : AppColors.tabbarBackground)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct TrainingProgramRow: View {
    let program: TrainingProgram
    
    // Функция для конвертации строки длительности в секунды
    private func getDurationInSeconds() -> Int {
        let components = program.duration.components(separatedBy: " ")
        if let minutes = Int(components[0]) {
            return minutes * 60
        }
        return 30 * 60 // 30 минут по умолчанию если не удалось распарсить
    }

    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    LevelBadge(level: program.level)
                    DurationBadge(duration: program.duration)
                    Spacer()
                }
                Text(program.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(program.description)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            
            // NavigationLink с кнопкой Play
            NavigationLink(destination: TimerActiveScreen(durationSeconds: getDurationInSeconds())) {
                Image("playButton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
        }
        .padding()
        .background(AppColors.tabbarBackground)
        .cornerRadius(12)
    }
}

// MARK: - Badge Views

struct LevelBadge: View {
    let level: String
    
    var backgroundColor: Color {
        switch level {
        case "Beginner": return Color(hex: "#10B981").opacity(0.2) // Зеленый фон
        case "Intermediate": return Color(hex: "#F59E0B").opacity(0.2) // Желтый фон
        case "Advanced": return Color(hex: "#EF4444").opacity(0.2) // Красный фон
        default: return Color.gray.opacity(0.2)
        }
    }
    
    var foregroundColor: Color {
         switch level {
         case "Beginner": return Color(hex: "#34D399") // Зеленый текст
         case "Intermediate": return Color(hex: "#FBBF24") // Желтый текст
         case "Advanced": return Color(hex: "#FB2424") // Красный текст
         default: return Color.white
         }
     }

    var body: some View {
        Text(level)
            .font(.system(size: 12))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

struct DurationBadge: View {
    let duration: String
    
    var body: some View {
        Text(duration)
            .font(.system(size: 12))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
    }
}

struct AddTrainingButton: View {
    // Убираем action, так как NavigationLink сам обрабатывает переход
    // var action: () -> Void

    var body: some View {
        // Button(action: action) { ... } - Заменяем на HStack
        HStack(spacing: 8) {
            Image(systemName: "plus")
            Text("Add training")
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 25)
        .padding(.vertical, 15)
        .background(AppColors.accent)
        .cornerRadius(12)
    }
}

// Helper для скругления определенных углов
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Preview

struct TrainingProgramScreen_Previews: PreviewProvider {
    static var previews: some View {
        TrainingProgramScreen()
            .preferredColorScheme(.dark)
    }
} 
