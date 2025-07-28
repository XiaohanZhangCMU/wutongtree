import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    let conversationRecord: ConversationRecord
    @State private var rating: Int = 0
    @State private var feedback: String = ""
    @State private var submitted = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                headerView
                
                ratingSection
                
                feedbackSection
                
                Spacer()
                
                submitButton
            }
            .padding()
            .navigationTitle("Rate Your Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 15) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)
            
            Text("How was your conversation?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Your feedback helps us improve future matches")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var ratingSection: some View {
        VStack(spacing: 15) {
            Text("Rate your experience")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        rating = star
                    }) {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title)
                            .foregroundColor(star <= rating ? .yellow : .gray)
                    }
                }
            }
            
            if rating > 0 {
                Text(ratingDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Tell us more (optional)")
                .font(.headline)
                .fontWeight(.medium)
            
            TextField("What did you enjoy? Any suggestions?", text: $feedback, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var submitButton: some View {
        VStack(spacing: 15) {
            Button("Submit Feedback") {
                submitFeedback()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(rating == 0)
            
            if submitted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Thank you for your feedback!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private var ratingDescription: String {
        switch rating {
        case 1:
            return "Poor experience"
        case 2:
            return "Below expectations"
        case 3:
            return "Good conversation"
        case 4:
            return "Great experience"
        case 5:
            return "Excellent conversation!"
        default:
            return ""
        }
    }
    
    private func submitFeedback() {
        // Update the conversation record with rating and feedback
        var updatedRecord = conversationRecord
        updatedRecord.rating = rating
        
        // Save updated conversation to local storage
        saveUpdatedConversation(updatedRecord)
        
        submitted = true
        
        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    private func saveUpdatedConversation(_ record: ConversationRecord) {
        // Load existing conversations
        var conversations: [ConversationRecord] = []
        
        if let data = UserDefaults.standard.data(forKey: "savedConversations"),
           let existingConversations = try? JSONDecoder().decode([ConversationRecord].self, from: data) {
            conversations = existingConversations
        }
        
        // Update or add the conversation
        if let index = conversations.firstIndex(where: { $0.id == record.id }) {
            conversations[index] = record
        } else {
            conversations.append(record)
        }
        
        // Save back to storage
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: "savedConversations")
        }
    }
}

#Preview {
    FeedbackView(conversationRecord: ConversationRecord(
        id: "preview",
        partnerName: "Preview Partner",
        topic: "Preview Topic",
        duration: 1800,
        date: Date(),
        rating: 0,
        hasRecording: true
    ))
}