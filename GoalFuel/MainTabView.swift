import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    init() {
        // Скрываем стандартный TabBar
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Контент выбранной вкладки
            TabView(selection: $selectedTab) {
                TrainingProgramScreen()
                    .tag(0)
                TimerSetupScreen()
                    .tag(1)
                NutritionScreen()
                    .tag(2)
                PerformanceScreen()
                    .tag(3)
                ProfileScreen()
                    .tag(4)
            }
            
            // Кастомный TabBar
            CustomTabBar(selectedTab: $selectedTab)
                .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea(.keyboard)
        .edgesIgnoringSafeArea(.bottom) // Растягиваем контент под таббар
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    private let tabIcons = ["tab1", "tab2", "tab3", "tab4", "tab5"]
    
    var body: some View {
        HStack {
            Spacer()
            ForEach(0..<tabIcons.count, id: \.self) { index in
                Button {
                    selectedTab = index
                } label: {
                    Image(tabIcons[index])
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(selectedTab == index ? AppColors.accent : AppColors.tabIconInactive)
                }
                Spacer()
            }
        }
        .frame(height: 80) // Высота таббара
        .background(
            // Используем tabbarBackground из Assets, если он там есть
            // Если нет, можно использовать цвет или градиент
            Image("tabbarBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
            // Добавляем размытие, если нужно (как в Figma)
            // .blur(radius: 10)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Скругление как в Figma
        .shadow(radius: 5)
        .ignoresSafeArea(.keyboard)
// Небольшая тень для выделения
        
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .preferredColorScheme(.dark) // Чтобы лучше видеть белый текст/иконки
    }
}
struct Swiper: ViewModifier {
    var onDismiss: () -> Void
    @State private var offset: CGSize = .zero

    func body(content: Content) -> some View {
        content
//            .offset(x: offset.width)
            .animation(.interactiveSpring(), value: offset)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                                      self.offset = value.translation
                                  }
                                  .onEnded { value in
                                      if value.translation.width > 70 {
                                          onDismiss()
                                  
                                      }
                                      self.offset = .zero
                                  }
            )
    }
}
