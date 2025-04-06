import SwiftUI

// Определяем имя уведомления для сброса данных
extension Notification.Name {
    static let resetAppData = Notification.Name("resetAppData")
}

struct ProfileScreen: View {
    @State private var showResetConfirmation = false
    @State private var showResetSuccessMessage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    HeaderView(title: "Profile")
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Секция с данными трекера воды и питания
                            HStack(spacing: 16) {
                                StatsCard(
                                    icon: "drop.fill",
                                    title: "Water balance",
                                    value: "8 days"
                                )
                                
                                StatsCard(
                                    icon: "fork.knife",
                                    title: "Daily meal",
                                    value: "2800 kcal"
                                )
                            }
                            .padding(.horizontal)
                            
                            // Секция с метриками производительности
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Performance Metrics (weekly)")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    MetricRow(icon: "bolt.fill", title: "Energy", value: "+15%")
                                    MetricRow(icon: "hand.tap.fill", title: "Dexterity", value: "+34%")
                                    MetricRow(icon: "heart.fill", title: "Health Level", value: "72%")
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .padding(.horizontal)
                            
                            // Кнопка сброса данных
                            Button(action: {
                                showResetConfirmation = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 16))
                                    
                                    Text("Reset data")
                                        .font(.system(size: 16))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showResetConfirmation) {
                Alert(
                    title: Text("Reset All Data?"),
                    message: Text("This will delete all your hydration and nutrition records. This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        resetAllData()
                        showResetSuccessMessage = true
                        
                        // Автоматически скрываем сообщение через 2 секунды
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showResetSuccessMessage = false
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .overlay(
                // Сообщение об успешном сбросе данных
                ZStack {
                    if showResetSuccessMessage {
                        VStack {
                            Spacer()
                            Text("All data has been reset successfully")
                                .foregroundColor(.white)
                                .padding()
                                .background(AppColors.accent)
                                .cornerRadius(8)
                                .padding(.bottom, 100)
                                .transition(.move(edge: .bottom))
                        }
                        .animation(.easeInOut, value: showResetSuccessMessage)
                        .zIndex(100)
                    }
                }
            )
        }
    }
    
    private func resetAllData() {
        // Удаляем данные о гидратации
        UserDefaults.standard.removeObject(forKey: "hydrationEntries")
        UserDefaults.standard.removeObject(forKey: "hydrationSettings")
        
        // Удаляем данные о питании
        UserDefaults.standard.removeObject(forKey: "mealEntries")
        
        // Удаляем пользовательские тренировочные программы
        UserDefaults.standard.removeObject(forKey: "savedTrainings")
        
        // Синхронизируем UserDefaults
        UserDefaults.standard.synchronize()
        
        // Отправляем уведомление о сбросе данных
        NotificationCenter.default.post(name: .resetAppData, object: nil)
        
        // Отображаем уведомление об успешном сбросе
        print("All data has been reset successfully")
    }
}

struct StatsCard: View {
    var icon: String
    var title: String
    var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MetricRow: View {
    var icon: String
    var title: String
    var value: String
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
    }
}

struct ProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProfileScreen()
            .preferredColorScheme(.dark)
    }
} 