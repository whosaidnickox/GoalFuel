import SwiftUI
import Combine

// Модель для хранения данных о приеме пищи
struct MealEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var mealType: String
    var time: String
    var calories: String
    var foodName: String
    var protein: String
    var carbs: String
    var fats: String
    
    static func getMockEntries() -> [MealEntry] {
        return [
            MealEntry(mealType: "Breakfast", time: "08:30 AM", calories: "420", foodName: "Oatmeal with Banana", protein: "15g", carbs: "70g", fats: "5g"),
            MealEntry(mealType: "Lunch", time: "01:15 PM", calories: "580", foodName: "Grilled Chicken Salad", protein: "35g", carbs: "40g", fats: "20g"),
            MealEntry(mealType: "Dinner", time: "07:45 PM", calories: "650", foodName: "Salmon with Quinoa", protein: "40g", carbs: "50g", fats: "25g"),
            MealEntry(mealType: "Snacks", time: "04:30 PM", calories: "220", foodName: "Protein Shake", protein: "30g", carbs: "20g", fats: "3g")
        ]
    }
}

struct NutritionScreen: View {
    @State private var searchText: String = ""
    @State private var mealEntries: [MealEntry] = []
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    HeaderView(
                        title: "Nutrition Diary"
                    )
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            DailyProgressView()
                            
                            if mealEntries.isEmpty {
                                EmptyNutritionView()
                            } else {
                                // Группируем приемы пищи по типу
                                ForEach(groupedMealEntries.keys.sorted(), id: \.self) { mealType in
                                    if let entries = groupedMealEntries[mealType] {
                                        ForEach(entries) { entry in
                                            MealSectionView(
                                                mealType: entry.mealType,
                                                time: entry.time,
                                                calories: entry.calories,
                                                foodName: entry.foodName
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        NavigationLink(destination: AddMealScreen(onSave: addMealEntry)) {
                            AddMealButton()
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 85)
                    }
                    .padding(.top, 24)
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: loadMealEntries)
            .onAppear {
                // Добавляем наблюдатель для сброса данных
                NotificationCenter.default.addObserver(forName: .resetAppData, object: nil, queue: .main) { _ in
                    self.mealEntries = []
                    self.saveMealEntries()
                }
            }
            .onDisappear {
                // Удаляем наблюдатель при закрытии экрана
                NotificationCenter.default.removeObserver(self, name: .resetAppData, object: nil)
            }
        }
    }
    
    // Группировка приемов пищи по типу
    var groupedMealEntries: [String: [MealEntry]] {
        Dictionary(grouping: mealEntries, by: { $0.mealType })
    }
    
    // Загрузка данных из UserDefaults
    func loadMealEntries() {
        if let data = UserDefaults.standard.data(forKey: "mealEntries"),
           let decoded = try? JSONDecoder().decode([MealEntry].self, from: data) {
            self.mealEntries = decoded
        }
    }
    
    // Сохранение данных в UserDefaults
    func saveMealEntries() {
        if let encoded = try? JSONEncoder().encode(mealEntries) {
            UserDefaults.standard.set(encoded, forKey: "mealEntries")
        }
    }
    
    // Добавление нового приема пищи
    func addMealEntry(entry: MealEntry) {
        mealEntries.append(entry)
        saveMealEntries()
    }
}

// Экран для пустого состояния
struct EmptyNutritionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(AppColors.accent.opacity(0.8))
                .padding(.bottom, 10)
            
            Text("Your Nutrition Diary is Empty")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Add your meals to start tracking your nutrition goals and progress")
                .font(.system(size: 16))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(AppColors.tabbarBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

struct DailyProgressView: View {
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Daily Goal")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
                Spacer()
                Text("2800 kcal")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.accent)
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.accent)
                    .frame(width: 250, height: 8)
            }
            
            HStack(spacing: 0) {
                NutrientProgressView(title: "Protein", amount: "120g")
                Spacer()
                NutrientProgressView(title: "Carbs", amount: "280g")
                Spacer()
                NutrientProgressView(title: "Fats", amount: "65g")
            }
        }
        .padding()
        .background(AppColors.tabbarBackground)
        .cornerRadius(12)
    }
}

struct NutrientProgressView: View {
    let title: String
    let amount: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
            Text(amount)
                .font(.system(size: 16))
                .foregroundColor(AppColors.accent)
        }
    }
}

struct MealSectionView: View {
    let mealType: String
    let time: String
    let calories: String
    let foodName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(mealType)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(foodName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text(time)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.secondaryText)
                }
                Spacer()
                Text("\(calories) kcal")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.accent)
            }
            .padding()
            .background(AppColors.tabbarBackground)
            .cornerRadius(12)
        }
    }
}

struct AddMealButton: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
            Text("Add Meal")
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 25)
        .padding(.vertical, 15)
        .background(AppColors.accent)
        .cornerRadius(12)
    }
}

struct AddMealScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMealType = "Breakfast"
    @State private var amount = "100"
    @State private var calories = "0"
    @State private var protein = "0g"
    @State private var carbs = "0g"
    @State private var fats = "0g"
    @State private var foodItems = "Food name"
    
    var onSave: (MealEntry) -> Void
    
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snacks"]
    
    init(onSave: @escaping (MealEntry) -> Void) {
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
                .dismissKeyboardOnTap()
            
            VStack(spacing: 0) {
                HeaderView(
                    title: "Add Meal",
                    backAction: {
                    presentationMode.wrappedValue.dismiss()
                })
                
                ScrollView {
                    VStack(spacing: 20) {
                        MealTypeSelector(mealTypes: mealTypes, selectedMealType: $selectedMealType)
                        
                        VStack(spacing: 15) {
                            
                            TitledTextField(
                                title: "",
                                placeholder: "Enter Food name",
                                text: $foodItems
                            )

                            HStack(spacing: 10) {
                                ClearableNutritionInputRow(title: "Amount (g)", value: $amount)
                                ClearableNutritionInputRow(title: "Calories", value: $calories)
                            }
                            
                            HStack(spacing: 10) {
                                ClearableNutritionInputRow(title: "Protein", value: $protein)
                                ClearableNutritionInputRow(title: "Carbs", value: $carbs)
                                ClearableNutritionInputRow(title: "Fats", value: $fats)
                            }
                        }
                        .padding(.horizontal)
                        
                        Button(action: saveMeal) {
                            HStack {
                                Text("Save")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppColors.accent)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.vertical)
                    .padding(.bottom, 45)
                }
                .padding(.bottom, 45)
                .modifier(NumberPadDoneButton())
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarHidden(true)
    }
    
    func saveMeal() {
        // Текущее время в формате строки
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        let timeString = formatter.string(from: Date())
        
        // Создаем новую запись о приеме пищи
        let newMeal = MealEntry(
            mealType: selectedMealType,
            time: timeString,
            calories: calories,
            foodName: foodItems == "Food name" || foodItems.isEmpty ? "Unnamed meal" : foodItems,
            protein: protein,
            carbs: carbs,
            fats: fats
        )
        
        // Вызываем callback для сохранения
        onSave(newMeal)
        
        // Закрываем экран
        presentationMode.wrappedValue.dismiss()
    }
}

struct MealTypeSelector: View {
    let mealTypes: [String]
    @Binding var selectedMealType: String
    
    var body: some View {
        let columns: [GridItem] = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Meal Type")
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(mealTypes, id: \.self) { mealType in
                    Button {
                        selectedMealType = mealType
                    } label: {
                        VStack(spacing: 8) {
                            Image(iconName(for: mealType))
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(height: 24)
                                .foregroundColor(selectedMealType == mealType ? AppColors.background : .white)
                            
                            Text(mealType)
                                .font(.system(size: 14))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .foregroundColor(selectedMealType == mealType ? AppColors.background : .white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedMealType == mealType ? AppColors.accent : AppColors.tabbarBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    func iconName(for mealType: String) -> String {
        switch mealType {
        case "Breakfast": return "breakfastIcon"
        case "Lunch": return "lunchIcon"
        case "Dinner": return "dinnerIcon"
        case "Snacks": return "snaksIcon"
        default: return "breakfastIcon"
        }
    }
}

struct ClearableNutritionInputRow: View {
    let title: String
    @Binding var value: String
    @State private var isFocused: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
            
            TextField("", text: $value, onEditingChanged: { editing in
                if editing && !isFocused {
                    // Очищаем поле только при первом получении фокуса
                    isFocused = true
                    value = ""
                }
            })
            .keyboardType(.decimalPad)
            .padding()
            .foregroundColor(.white)
            .background(AppColors.tabbarBackground)
            .cornerRadius(12)
        }
    }
}

struct ClearableFoodField: View {
    let title: String
    @Binding var value: String
    @State private var isFocused: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
            
            TextField("", text: $value, onEditingChanged: { editing in
                if editing && !isFocused {
                    // Очищаем поле только при первом получении фокуса
                    isFocused = true
                    value = ""
                }
            })
            .padding()
            .foregroundColor(.white)
            .background(AppColors.tabbarBackground)
            .cornerRadius(12)
        }
    }
}

// Восстанавливаем оригинальный компонент для использования в других местах
struct NutritionInputRow: View {
    let title: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
            
            TextField(title, text: $value)
                .keyboardType(.decimalPad)
                .padding()
                .foregroundColor(.white)
                .background(AppColors.tabbarBackground)
                .cornerRadius(12)
        }
    }
}

struct NutritionScreen_Previews: PreviewProvider {
    static var previews: some View {
        NutritionScreen()
            .preferredColorScheme(.dark)
    }
} 
