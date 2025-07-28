import SwiftUI

struct MainTabView: View {
    @StateObject private var voiceViewModel = VoiceRecordingViewModel()
    @StateObject private var matchingViewModel = MatchingViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(voiceViewModel)
                .environmentObject(matchingViewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(1)
            
            ConversationHistoryView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("History")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.green)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}