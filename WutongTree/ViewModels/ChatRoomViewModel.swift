import Foundation
import AVFoundation
import Combine

class ChatRoomViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var speakingParticipants: Set<String> = []
    @Published var audioLevels: [String: Float] = [:]
    @Published var isMuted = false
    @Published var speakerOn = true
    @Published var currentVolumeLevel: Float = 0.5
    @Published var recordingDuration = 0
    @Published var isRecording = false
    
    private var chatRoom: ChatRoom?
    private var audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var volumeTimer: Timer?
    private var aiResponseTimer: Timer?
    private var morganResponseTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var conversationStep = 0
    
    init() {
        setupAudioSession()
        startVolumeMonitoring()
    }
    
    func setup(chatRoom: ChatRoom) {
        self.chatRoom = chatRoom
        addWelcomeMessages()
        startAIConversationFlow()
        startMorganResponseFlow()
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func addWelcomeMessages() {
        guard let chatRoom = chatRoom else { return }
        
        let welcomeMessage = ChatMessage(
            id: UUID().uuidString,
            senderID: chatRoom.aiHost.id,
            senderName: chatRoom.aiHost.name,
            content: "🎙️ Welcome to WutongTree! I'm \(chatRoom.aiHost.name), your AI host! Here's my opening joke: Why don't scientists trust atoms? Because they make up everything! 😄 Now let's get this conversation rolling - introductions time!",
            timestamp: Date(),
            messageType: .aiGenerated
        )
        
        messages.append(welcomeMessage)
        
        // Simulate AI speaking
        speakingParticipants.insert(chatRoom.aiHost.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.speakingParticipants.remove(chatRoom.aiHost.id)
        }
    }
    
    private func startAIConversationFlow() {
        // Simulate periodic AI interventions with ice-breaking
        aiResponseTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            self?.generateAIResponse()
        }
    }
    
    private func startMorganResponseFlow() {
        // Morgan starts responding after 10 seconds, then regularly
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.generateMorganResponse()
            
            // Continue Morgan responses every 20-35 seconds
            self.morganResponseTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 20...35), repeats: true) { [weak self] _ in
                self?.generateMorganResponse()
            }
        }
    }
    
    private func generateAIResponse() {
        guard let chatRoom = chatRoom else { return }
        conversationStep += 1
        
        let aiResponses = [
            "🎭 Here's a fun ice-breaker: If you could have dinner with any historical figure, who would it be and why?",
            "😄 Quick joke time! Why did the scarecrow win an award? Because he was outstanding in his field! Now, what's everyone's dream job?",
            "🌟 That's fascinating! Morgan, what's your take on this? I love hearing different perspectives!",
            "🎯 Let's play 'Would You Rather' - Would you rather be able to fly or be invisible? And why?",
            "💭 Deep question time: What's one thing you've learned recently that completely changed your perspective?",
            "😂 Fun fact: Did you know honey never spoils? Speaking of sweet things, what's your favorite memory from this year?",
            "🎪 Time for a conversation twist! If you could live in any movie universe, which one would you choose?",
            "🌈 You two are creating such great energy! What's something you're both passionate about?",
            "🎵 Music break question: What song always makes you happy? I bet you both have great taste!",
            "🤔 Philosophical moment: If you could give your younger self one piece of advice, what would it be?"
        ]
        
        let randomResponse = aiResponses.randomElement() ?? aiResponses[0]
        
        let aiMessage = ChatMessage(
            id: UUID().uuidString,
            senderID: chatRoom.aiHost.id,
            senderName: chatRoom.aiHost.name,
            content: randomResponse,
            timestamp: Date(),
            messageType: .aiGenerated
        )
        
        DispatchQueue.main.async {
            self.messages.append(aiMessage)
            self.speakingParticipants.insert(chatRoom.aiHost.id)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.speakingParticipants.remove(chatRoom.aiHost.id)
            }
        }
    }
    
    private func generateMorganResponse() {
        guard let chatRoom = chatRoom else { return }
        
        // Find Morgan in participants
        guard let morgan = chatRoom.participants.first(where: { $0.name == "Morgan" }) else { return }
        
        let morganResponses = [
            "Hi everyone! 👋 I'm so excited to be here! I love meeting new people and having deep conversations.",
            "That's such an interesting question! 🤔 I've been thinking a lot about personal growth lately.",
            "Oh wow, I totally agree with that perspective! It reminds me of something I experienced recently...",
            "This is such a fun ice-breaker! 😄 I'd probably choose to have dinner with Maya Angelou - her wisdom was incredible.",
            "Great question! I think I'd rather be able to fly - imagine the freedom and perspective you'd gain! ✈️",
            "You know what? I recently learned about mindfulness meditation and it completely changed how I handle stress.",
            "Haha, I love that joke! 😂 My dream job would probably be something that combines creativity with helping others.",
            "That's so true! I'm really passionate about environmental sustainability - small changes can make such a big impact! 🌱",
            "Music is life! 🎵 'Good as Hell' by Lizzo always gets me pumped up and confident. What about you?",
            "If I could tell my younger self anything, it would be 'Stop worrying so much about what others think - you're enough as you are!' 💪",
            "I love how thoughtful everyone is being! This is exactly why I wanted to try WutongTree.",
            "You both have such interesting perspectives! I feel like I'm learning so much already. 📚",
            "This conversation is giving me so much energy! Anyone else feeling super inspired right now? ✨"
        ]
        
        let randomResponse = morganResponses.randomElement() ?? morganResponses[0]
        
        let morganMessage = ChatMessage(
            id: UUID().uuidString,
            senderID: morgan.id,
            senderName: morgan.name,
            content: randomResponse,
            timestamp: Date(),
            messageType: .text
        )
        
        DispatchQueue.main.async {
            self.messages.append(morganMessage)
            self.speakingParticipants.insert(morgan.id)
            
            // Morgan speaks for 2-4 seconds
            let speakingDuration = Double.random(in: 2...4)
            DispatchQueue.main.asyncAfter(deadline: .now() + speakingDuration) {
                self.speakingParticipants.remove(morgan.id)
            }
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        
        do {
            if isMuted {
                try audioSession.setActive(false)
            } else {
                try audioSession.setActive(true)
            }
        } catch {
            print("Failed to toggle mute: \(error)")
        }
        
        let muteMessage = ChatMessage(
            id: UUID().uuidString,
            senderID: "system",
            senderName: "System",
            content: isMuted ? "You are now muted" : "You are now unmuted",
            timestamp: Date(),
            messageType: .system
        )
        
        messages.append(muteMessage)
    }
    
    func toggleSpeaker() {
        speakerOn.toggle()
        
        do {
            if speakerOn {
                try audioSession.overrideOutputAudioPort(.speaker)
            } else {
                try audioSession.overrideOutputAudioPort(.none)
            }
        } catch {
            print("Failed to toggle speaker: \(error)")
        }
    }
    
    func toggleRecording() {
        guard let chatRoom = chatRoom else { return }
        
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("conversation_\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            recordingDuration = 0
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.recordingDuration += 1
            }
            
            let recordingMessage = ChatMessage(
                id: UUID().uuidString,
                senderID: "system",
                senderName: "System",
                content: "🔴 Recording started",
                timestamp: Date(),
                messageType: .system
            )
            
            messages.append(recordingMessage)
            
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        
        // Save recording to user's local storage (Step 15 from spec)
        saveRecordingToPhoneStorage()
        
        let recordingMessage = ChatMessage(
            id: UUID().uuidString,
            senderID: "system",
            senderName: "System",
            content: "⏹️ Recording stopped and saved to your phone",
            timestamp: Date(),
            messageType: .system
        )
        
        messages.append(recordingMessage)
    }
    
    private func saveRecordingToPhoneStorage() {
        let filename = "conversation_\(Date().timeIntervalSince1970).m4a"
        let audioFilename = getDocumentsDirectory().appendingPathComponent(filename)
        
        // Save conversation metadata
        if let chatRoom = chatRoom {
            let conversationRecord = ConversationRecord(
                id: chatRoom.id,
                partnerName: chatRoom.participants.first?.name ?? "Unknown",
                topic: chatRoom.conversationTopic ?? "General conversation",
                duration: recordingDuration,
                date: Date(),
                rating: 0, // Will be set during feedback
                hasRecording: true
            )
            
            // Save to UserDefaults for demo purposes
            // In production, this would be saved to Core Data or similar
            var savedConversations = getSavedConversations()
            savedConversations.append(conversationRecord)
            
            if let data = try? JSONEncoder().encode(savedConversations) {
                UserDefaults.standard.set(data, forKey: "savedConversations")
            }
            
            print("Recording saved to: \(audioFilename.path)")
            print("Conversation record saved: \(conversationRecord.id)")
        }
    }
    
    private func getSavedConversations() -> [ConversationRecord] {
        guard let data = UserDefaults.standard.data(forKey: "savedConversations"),
              let conversations = try? JSONDecoder().decode([ConversationRecord].self, from: data) else {
            return []
        }
        return conversations
    }
    
    private func startVolumeMonitoring() {
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateVolumeLevel()
        }
    }
    
    private func updateVolumeLevel() {
        // Simulate volume level changes
        currentVolumeLevel = Float.random(in: 0.3...0.8)
        
        // Simulate participants speaking with more realistic audio levels
        if let chatRoom = chatRoom {
            for participant in chatRoom.participants {
                if speakingParticipants.contains(participant.id) {
                    // When speaking, show active audio levels
                    audioLevels[participant.id] = Float.random(in: 0.4...0.9)
                } else {
                    // When not speaking, minimal background noise
                    audioLevels[participant.id] = Float.random(in: 0...0.1)
                }
            }
            
            // AI host audio level - more dramatic when speaking
            if speakingParticipants.contains(chatRoom.aiHost.id) {
                audioLevels[chatRoom.aiHost.id] = Float.random(in: 0.6...1.0)
            } else {
                audioLevels[chatRoom.aiHost.id] = 0
            }
        }
    }
    
    func endConversation() {
        recordingTimer?.invalidate()
        volumeTimer?.invalidate()
        aiResponseTimer?.invalidate()
        morganResponseTimer?.invalidate()
        audioRecorder?.stop()
        
        try? audioSession.setActive(false)
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    deinit {
        endConversation()
    }
}