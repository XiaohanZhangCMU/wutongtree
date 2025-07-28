import SwiftUI

struct ConversationHistoryView: View {
    @State private var conversations: [ConversationRecord] = []
    @State private var selectedConversation: ConversationRecord?
    
    var body: some View {
        NavigationView {
            List {
                if conversations.isEmpty {
                    emptyState
                } else {
                    ForEach(conversations) { conversation in
                        ConversationRow(conversation: conversation)
                            .onTapGesture {
                                selectedConversation = conversation
                            }
                    }
                }
            }
            .navigationTitle("Conversation History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadConversations()
            }
            .sheet(item: $selectedConversation) { conversation in
                ConversationDetailView(conversation: conversation)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Conversations Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start your first conversation to see it here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .listRowSeparator(.hidden)
    }
    
    private func loadConversations() {
        // Load from local storage (Step 15 from spec)
        if let data = UserDefaults.standard.data(forKey: "savedConversations"),
           let savedConversations = try? JSONDecoder().decode([ConversationRecord].self, from: data) {
            conversations = savedConversations.sorted { $0.date > $1.date }
        } else {
            // Mock data for demo if no saved conversations
            conversations = [
                ConversationRecord(
                    id: "1",
                    partnerName: "Alex",
                    topic: "Technology and Future",
                    duration: 1680, // 28 minutes
                    date: Date().addingTimeInterval(-86400), // Yesterday
                    rating: 5,
                    hasRecording: true
                ),
                ConversationRecord(
                    id: "2",
                    partnerName: "Jordan",
                    topic: "Philosophy of Mind",
                    duration: 2340, // 39 minutes
                    date: Date().addingTimeInterval(-172800), // 2 days ago
                    rating: 4,
                    hasRecording: false
                ),
                ConversationRecord(
                    id: "3",
                    partnerName: "Taylor",
                    topic: "Climate Change",
                    duration: 1200, // 20 minutes
                    date: Date().addingTimeInterval(-259200), // 3 days ago
                    rating: 5,
                    hasRecording: true
                )
            ]
        }
    }
}

struct ConversationRow: View {
    let conversation: ConversationRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.partnerName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(conversation.topic)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(conversation.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= conversation.rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            
            HStack {
                Label(formatDuration(conversation.duration), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if conversation.hasRecording {
                    Label("Recorded", systemImage: "mic.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct ConversationRecord: Identifiable, Codable {
    let id: String
    let partnerName: String
    let topic: String
    let duration: Int // in seconds
    let date: Date
    var rating: Int
    let hasRecording: Bool
}

struct ConversationDetailView: View {
    let conversation: ConversationRecord
    @Environment(\.dismiss) private var dismiss
    @State private var isPlayingRecording = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    conversationHeader
                    
                    if conversation.hasRecording {
                        recordingSection
                    }
                    
                    conversationStats
                    
                    feedbackSection
                    
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Conversation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var conversationHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(conversation.partnerName.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                    )
                
                VStack(alignment: .leading) {
                    Text(conversation.partnerName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(conversation.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(conversation.topic)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var recordingSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recording")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack {
                Button(action: {
                    isPlayingRecording.toggle()
                }) {
                    Image(systemName: isPlayingRecording ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading) {
                    Text("Conversation Recording")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(formatDuration(conversation.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Share") {
                    // Handle sharing
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var conversationStats: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack {
                StatItem(title: "Duration", value: formatDuration(conversation.duration))
                Spacer()
                StatItem(title: "Rating", value: "\(conversation.rating)/5")
                Spacer()
                StatItem(title: "Host", value: "MoMo")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Feedback")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= conversation.rating ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                Text("Great conversation!")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button("Match Again") {
                // Handle matching with same criteria
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            
            Button("Report Issue") {
                // Handle reporting
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ConversationHistoryView()
}