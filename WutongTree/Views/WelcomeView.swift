import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "tree.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("WutongTree")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("AI hosting chat room for humans to share ideas, thoughts and life")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 15) {
                SignInButton(
                    title: "Continue with Apple (Demo)",
                    icon: "applelogo",
                    backgroundColor: .black,
                    foregroundColor: .white
                ) {
                    authViewModel.signInWithApple()
                }
                
                SignInButton(
                    title: "Continue with Google (Demo)",
                    icon: "globe",
                    backgroundColor: .blue,
                    foregroundColor: .white
                ) {
                    authViewModel.signInWithGoogle()
                }
                
                SignInButton(
                    title: "Continue with Facebook (Demo)",
                    icon: "person.2.fill",
                    backgroundColor: Color(red: 0.25, green: 0.4, blue: 0.75),
                    foregroundColor: .white
                ) {
                    authViewModel.signInWithFacebook()
                }
            }
            .padding(.horizontal, 30)
            
            VStack(spacing: 4) {
                Text("Demo Mode: Mock Authentication")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
                
                Text("Free 7-day trial • No commitment")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .alert("Authentication Error", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.errorMessage = nil
            }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
        .overlay {
            if authViewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
}

struct SignInButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthenticationViewModel())
}