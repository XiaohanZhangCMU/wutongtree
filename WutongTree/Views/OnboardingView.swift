import SwiftUI

struct OnboardingView: View {
    @Binding var user: User
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var name = ""
    @State private var age = ""
    @State private var interests: Set<String> = []
    @State private var lookingFor = ""
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage?
    
    private let availableInterests = [
        "Politics", "Philosophy", "Technology", "Art", "Music", "Sports",
        "Science", "Literature", "Travel", "Food", "Movies", "Gaming",
        "Photography", "Dancing", "Writing", "History", "Psychology"
    ]
    
    private let totalSteps = 5
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                progressBar
                
                ScrollView {
                    VStack(spacing: 30) {
                        stepContent
                    }
                    .padding()
                }
                
                navigationButtons
            }
            .navigationTitle("Setup Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $profileImage)
        }
    }
    
    private var progressBar: some View {
        VStack(spacing: 10) {
            ProgressView(value: Double(currentStep), total: Double(totalSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
            
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            profilePhotoStep
        case 1:
            basicInfoStep
        case 2:
            interestsStep
        case 3:
            lookingForStep
        case 4:
            voiceSetupStep
        default:
            EmptyView()
        }
    }
    
    private var profilePhotoStep: some View {
        VStack(spacing: 20) {
            Text("Add Your Photo")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Help others recognize you in conversations")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingImagePicker = true
            }) {
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.green, lineWidth: 3))
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .overlay(
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                        )
                }
            }
        }
    }
    
    private var basicInfoStep: some View {
        VStack(spacing: 20) {
            Text("Tell Us About Yourself")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 15) {
                TextField("Your name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                
                TextField("Your age", text: $age)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .font(.title3)
            }
        }
    }
    
    private var interestsStep: some View {
        VStack(spacing: 20) {
            Text("What Are Your Interests?")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select at least 3 topics you enjoy discussing")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                ForEach(availableInterests, id: \.self) { interest in
                    InterestTag(
                        title: interest,
                        isSelected: interests.contains(interest)
                    ) {
                        if interests.contains(interest) {
                            interests.remove(interest)
                        } else {
                            interests.insert(interest)
                        }
                    }
                }
            }
        }
    }
    
    private var lookingForStep: some View {
        VStack(spacing: 20) {
            Text("What Are You Looking For?")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Help us understand your conversation goals")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 10) {
                ForEach([
                    "Deep philosophical discussions",
                    "Casual friendly chats",
                    "Learning new perspectives",
                    "Sharing life experiences",
                    "Professional networking"
                ], id: \.self) { option in
                    Button(action: {
                        lookingFor = option
                    }) {
                        HStack {
                            Text(option)
                                .font(.body)
                            Spacer()
                            if lookingFor == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(lookingFor == option ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var voiceSetupStep: some View {
        VStack(spacing: 20) {
            Text("Voice Setup Complete! 🎉")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You're all set to start meaningful conversations with WutongTree!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Profile completed")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Voice permissions granted")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Ready for matching")
                }
            }
            .font(.body)
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    currentStep -= 1
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            Button(currentStep == totalSteps - 1 ? "Complete" : "Next") {
                if currentStep == totalSteps - 1 {
                    completeOnboarding()
                } else {
                    currentStep += 1
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canProceed)
        }
        .padding()
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return !name.isEmpty && !age.isEmpty
        case 2:
            return interests.count >= 3
        case 3:
            return !lookingFor.isEmpty
        default:
            return true
        }
    }
    
    private func completeOnboarding() {
        user.name = name
        user.age = Int(age)
        user.interests = Array(interests)
        user.lookingFor = lookingFor
        user.onboardingCompleted = true
        
        dismiss()
    }
}

struct InterestTag: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
    }
}

#Preview {
    OnboardingView(user: .constant(User(
        id: "test",
        email: "test@test.com",
        name: "Test",
        interests: [],
        onboardingCompleted: false,
        subscriptionType: .free
    )))
}