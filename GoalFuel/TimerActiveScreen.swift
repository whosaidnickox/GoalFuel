import SwiftUI
import Combine

struct TimerActiveScreen: View {
    @Environment(\.dismiss) var dismiss
    let durationSeconds: Int

    @State private var remainingSeconds: Int
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var cancellable: Cancellable? = nil
    @State private var isPaused: Bool = false

    init(durationSeconds: Int) {
        self.durationSeconds = durationSeconds
        _remainingSeconds = State(initialValue: durationSeconds)
    }

    // Форматирование секунд в MM:SS или HH:MM:SS
    var formattedTime: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Используем HeaderView с кнопкой назад
                HeaderView(title: "Timer", backAction: {
                    stopTimer() // Останавливаем таймер при возврате
                    dismiss()
                })
                // .ignoresSafeArea(.container, edges: .top)

                Spacer()

                // Отображение времени
                VStack(spacing: 10) {
                    Text("Total Training Time")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.65))
                    Text(formattedTime)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(40)
                .background(AppColors.tabbarBackground) // Фон как в Figma
                .cornerRadius(16)

                Spacer()

                // Кнопки управления
                HStack(spacing: 20) {
                    // Кнопка Пауза/Продолжить
                    Button {
                        togglePause()
                    } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(AppColors.tabbarBackground)
                            .clipShape(Circle())
                    }

                    // Кнопка Отмена
                    Button("Cancel") {
                        stopTimer()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(height: 70)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#BF6666")) // Красный цвет из Figma
                    .cornerRadius(35)

                }
                .padding(.horizontal, 40)
                .padding(.bottom, 100) // Отступ от нижнего края/таббара
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer) // Останавливаем таймер при уходе с экрана
    }

    // MARK: - Timer Logic

    func startTimer() {
        // Сбрасываем, если таймер уже был запущен
        stopTimer()
        // Сбрасываем на начальное значение, если пользователь вернулся на экран
        if remainingSeconds <= 0 {
             remainingSeconds = durationSeconds
        }
        isPaused = false
        timer = Timer.publish(every: 1, on: .main, in: .common)
        cancellable = timer.autoconnect()
            .sink { _ in
                if !isPaused && remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else if remainingSeconds <= 0 {
                    stopTimer()
                    // Опционально: действие по завершению таймера
                    print("Timer finished!")
                    // dismiss() // Можно закрыть экран автоматически
                }
            }
    }

    func stopTimer() {
        cancellable?.cancel()
        cancellable = nil
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            stopTimer() // Приостанавливаем подписку
        } else {
             // Возобновляем с новым Publisher, чтобы избежать пропуска тиков
             timer = Timer.publish(every: 1, on: .main, in: .common)
             startTimerSubscriptionOnly()
        }
    }
    
    // Вспомогательная функция для возобновления подписки без сброса времени
    func startTimerSubscriptionOnly() {
        cancellable = timer.autoconnect()
             .sink { _ in
                 if !isPaused && remainingSeconds > 0 {
                     remainingSeconds -= 1
                 } else if remainingSeconds <= 0 {
                     stopTimer()
                     print("Timer finished!")
                 }
             }
    }
}

// MARK: - Preview

struct TimerActiveScreen_Previews: PreviewProvider {
    static var previews: some View {
        TimerActiveScreen(durationSeconds: 3665) // Пример: 1 час 1 минута 5 секунд
            .preferredColorScheme(.dark)
    }
} 