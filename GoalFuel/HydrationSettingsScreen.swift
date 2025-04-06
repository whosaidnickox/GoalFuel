import SwiftUI

struct HydrationSettingsScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedReminderTime = "5 min"
    @State private var soundNotifications = true
    @State private var vibrationEnabled = false
    
    let reminderTimes = ["5 min", "15 min", "in time"]
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                HeaderView(title: "Reminders", backAction: {
                    presentationMode.wrappedValue.dismiss()
                })
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("To remind for")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.horizontal)
                            
                            HStack(spacing: 10) {
                                ForEach(reminderTimes, id: \.self) { time in
                                    Button(action: {
                                        selectedReminderTime = time
                                    }) {
                                        Text(time)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .background(selectedReminderTime == time ? AppColors.accent : Color.white.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        VStack(spacing: 12) {
                            ToggleSettingRow(
                                title: "Sound Notifications",
                                icon: "speaker.wave.2.fill",
                                isOn: $soundNotifications
                            )
                            
                            ToggleSettingRow(
                                title: "Vibration",
                                icon: "iphone.radiowaves.left.and.right",
                                isOn: $vibrationEnabled
                            )
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Text("Save")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.accent)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct ToggleSettingRow: View {
    var title: String
    var icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accent)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(isOn ? AppColors.accent : Color.white.opacity(0.3))
                    .frame(width: 50, height: 30)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .offset(x: isOn ? 10 : -10)
                    .animation(.spring(), value: isOn)
            }
            .onTapGesture {
                isOn.toggle()
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HydrationSettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        HydrationSettingsScreen()
            .preferredColorScheme(.dark)
    }
} 
