import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool

    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image("onbBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .edgesIgnoringSafeArea(.all)
            }

            VStack(spacing: 20) {
                Spacer()

                Text("ProFootball Trainer")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Your personal football training companion")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)

                FeatureRow(imageName: "on1", title: "Hydration Tracking")
                FeatureRow(imageName: "on2", title: "Smart Performance Tracking")
                FeatureRow(imageName: "on3", title: "Nutrition Monitor")

                Spacer()


                Button(action: {
                    // Действие по нажатию кнопки "Get Started"
                    isOnboardingCompleted = true
                    
                    // Дополнительно сохраняем значение в UserDefaults для надёжности
                    UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
                    UserDefaults.standard.synchronize()
                }) {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accent)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)

            }
            .padding(.horizontal, 20)
        }
        .trishteskri()
        .background(AppColors.background.edgesIgnoringSafeArea(.all))
    }
}

struct FeatureRow: View {
    let imageName: String
    let title: String

    var body: some View {
        HStack(spacing: 15) {
            Image(imageName)
                .resizable()
                .renderingMode(.template) // Позволяет изменять цвет иконки
                .scaledToFit()
                .frame(width: 24, height: 24) // Фиксированный размер для иконок
                .foregroundColor(AppColors.accent) // Используем AppColors

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer() // Чтобы прижать контент влево
        }
        .padding()
        .background(AppColors.tabbarBackground) // Используем AppColors
        .cornerRadius(12)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingCompleted: .constant(false))
    }
} 
