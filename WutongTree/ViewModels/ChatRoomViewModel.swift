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
    
    // LLM Services
    private var hostLLMService: LLMService?
    private var participantLLMService: LLMService?
    
    // Text-to-Speech Service
    private var ttsService = TextToSpeechService()
    
    init() {
        setupAudioSession()
        startVolumeMonitoring()
        setupLLMServices()
    }
    
    private func setupLLMServices() {
        guard let anthropicKey = LLMConfig.shared.getAnthropicKey() else {
            print("Warning: No Anthropic API key found")
            return
        }
        
        // Setup AI host service
        hostLLMService = LLMServiceFactory.createService(type: .anthropic, apiKey: anthropicKey)
        
        // Setup participant service (for Morgan)
        participantLLMService = LLMServiceFactory.createService(type: .anthropic, apiKey: anthropicKey)
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
        guard let chatRoom = chatRoom,
              let llmService = hostLLMService else { 
            // Fallback welcome message if no LLM service
            let welcomeMessage = ChatMessage(
                id: UUID().uuidString,
                senderID: chatRoom?.aiHost.id ?? "momo",
                senderName: chatRoom?.aiHost.name ?? "MoMo",
                content: "🎙️ Welcome to WutongTree! I'm your AI host. Let's have a great conversation!",
                timestamp: Date(),
                messageType: .aiGenerated
            )
            messages.append(welcomeMessage)
            return
        }
        
        Task {
            do {
                let welcomeContent = try await generateWelcomeMessage(using: llmService)
                
                let welcomeMessage = ChatMessage(
                    id: UUID().uuidString,
                    senderID: chatRoom.aiHost.id,
                    senderName: chatRoom.aiHost.name,
                    content: welcomeContent,
                    timestamp: Date(),
                    messageType: .aiGenerated
                )
                
                DispatchQueue.main.async {
                    self.messages.append(welcomeMessage)
                    self.speakingParticipants.insert(chatRoom.aiHost.id)
                    
                    // Speak the welcome message
                    self.ttsService.speak(welcomeContent, for: chatRoom.aiHost.id, personality: .aiHost)
                    
                    // Monitor TTS completion to update speaking status
                    self.monitorTTSCompletion(for: chatRoom.aiHost.id)
                }
            } catch {
                print("Welcome message generation error: \(error)")
                // Fallback welcome message
                let fallbackMessage = ChatMessage(
                    id: UUID().uuidString,
                    senderID: chatRoom.aiHost.id,
                    senderName: chatRoom.aiHost.name,
                    content: "🎙️ Welcome to WutongTree! I'm \(chatRoom.aiHost.name), your AI host. Let's have a great conversation!",
                    timestamp: Date(),
                    messageType: .aiGenerated
                )
                
                DispatchQueue.main.async {
                    self.messages.append(fallbackMessage)
                }
            }
        }
    }
    
    private func generateWelcomeMessage(using llmService: LLMService) async throws -> String {
        guard let chatRoom = chatRoom else { throw LLMError.noContentError }
        
        let systemPrompt = """
        You are MoMo, an AI conversation host for WutongTree, a voice chat app. Your personality is \(chatRoom.aiHost.personality.rawValue). Generate a warm, engaging welcome message to start a conversation between strangers.
        
        Your welcome should:
        - Introduce yourself as MoMo, the AI host
        - Welcome everyone to WutongTree
        - Set a positive, encouraging tone
        - Include an emoji or two
        - Be brief (1-2 sentences)
        - Maybe include a light ice-breaker or joke
        
        This is the very first message of the conversation.
        """
        
        let llmMessages: [LLMMessage] = [
            LLMMessage(role: "system", content: systemPrompt),
            LLMMessage(role: "user", content: "Generate your welcome message to start the conversation.")
        ]
        
        return try await llmService.generateResponse(
            messages: llmMessages,
            temperature: 0.8,
            maxTokens: 100
        )
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
        guard let chatRoom = chatRoom,
              let llmService = hostLLMService else { return }
        
        Task {
            do {
                let response = try await generateHostResponse(using: llmService)
                
                let aiMessage = ChatMessage(
                    id: UUID().uuidString,
                    senderID: chatRoom.aiHost.id,
                    senderName: chatRoom.aiHost.name,
                    content: response,
                    timestamp: Date(),
                    messageType: .aiGenerated
                )
                
                DispatchQueue.main.async {
                    self.messages.append(aiMessage)
                    self.speakingParticipants.insert(chatRoom.aiHost.id)
                    
                    // Speak the AI response
                    self.ttsService.speak(response, for: chatRoom.aiHost.id, personality: .aiHost)
                    
                    // Monitor TTS completion to update speaking status
                    self.monitorTTSCompletion(for: chatRoom.aiHost.id)
                }
            } catch {
                print("AI Host response error: \(error)")
                // Fallback to a simple message if LLM fails
                let fallbackMessage = ChatMessage(
                    id: UUID().uuidString,
                    senderID: chatRoom.aiHost.id,
                    senderName: chatRoom.aiHost.name,
                    content: "That's interesting! What do you all think about that?",
                    timestamp: Date(),
                    messageType: .aiGenerated
                )
                
                DispatchQueue.main.async {
                    self.messages.append(fallbackMessage)
                }
            }
        }
    }
    
    private func generateHostResponse(using llmService: LLMService) async throws -> String {
        guard let chatRoom = chatRoom else { throw LLMError.noContentError }
        
        let systemPrompt = """
        You are MoMo, an AI conversation host for WutongTree, a voice chat app that brings strangers together for meaningful conversations. Your personality is \(chatRoom.aiHost.personality.rawValue).
        
        Your role:
        - Facilitate engaging conversations between participants
        - Ask thought-provoking questions and ice-breakers
        - Keep the conversation flowing smoothly
        - Be encouraging and supportive
        - Include emojis to make messages more engaging
        - Keep responses concise (1-2 sentences max)
        
        Conversation context: You're hosting a conversation between strangers. Generate an appropriate host message based on the conversation flow.
        """
        
        // Get recent conversation context
        let recentMessages = Array(messages.suffix(5))
        var llmMessages: [LLMMessage] = [
            LLMMessage(role: "system", content: systemPrompt)
        ]
        
        // Add recent conversation history
        for message in recentMessages {
            let role = message.messageType == .aiGenerated ? "assistant" : "user"
            llmMessages.append(LLMMessage(role: role, content: "\(message.senderName): \(message.content)"))
        }
        
        // Add instruction for next response
        llmMessages.append(LLMMessage(role: "user", content: "Generate your next host message to keep the conversation engaging."))
        
        return try await llmService.generateResponse(
            messages: llmMessages,
            temperature: 0.8,
            maxTokens: 150
        )
    }
    
    private func generateMorganResponse() {
        guard let chatRoom = chatRoom,
              let llmService = participantLLMService else { return }
        
        // Find Morgan in participants
        guard let morgan = chatRoom.participants.first(where: { $0.name == "Morgan" }) else { return }
        
        Task {
            do {
                let response = try await generateParticipantResponse(for: morgan, using: llmService)
                
                let morganMessage = ChatMessage(
                    id: UUID().uuidString,
                    senderID: morgan.id,
                    senderName: morgan.name,
                    content: response,
                    timestamp: Date(),
                    messageType: .text
                )
                
                DispatchQueue.main.async {
                    self.messages.append(morganMessage)
                    self.speakingParticipants.insert(morgan.id)
                    
                    // Speak Morgan's response
                    self.ttsService.speak(response, for: morgan.id, personality: .participant)
                    
                    // Monitor TTS completion to update speaking status
                    self.monitorTTSCompletion(for: morgan.id)
                }
            } catch {
                print("Morgan response error: \(error)")
                // Fallback to a simple message if LLM fails
                let fallbackMessage = ChatMessage(
                    id: UUID().uuidString,
                    senderID: morgan.id,
                    senderName: morgan.name,
                    content: "That's really interesting! I'd love to hear more about that.",
                    timestamp: Date(),
                    messageType: .text
                )
                
                DispatchQueue.main.async {
                    self.messages.append(fallbackMessage)
                }
            }
        }
    }
    
    private func generateParticipantResponse(for participant: User, using llmService: LLMService) async throws -> String {
        let systemPrompt = """
        You are \(participant.name), a friendly and engaging participant in a voice chat conversation on WutongTree. You're genuinely interested in connecting with other people and having meaningful conversations.
        
        Your personality:
        - Enthusiastic and positive
        - Curious about others
        - Shares personal thoughts and experiences
        - Uses emojis naturally
        - Asks follow-up questions
        - Keeps responses conversational and authentic (1-2 sentences)
        
        You're having a conversation with strangers, facilitated by an AI host named MoMo. Respond naturally to the conversation flow.
        """
        
        // Get recent conversation context
        let recentMessages = Array(messages.suffix(6))
        var llmMessages: [LLMMessage] = [
            LLMMessage(role: "system", content: systemPrompt)
        ]
        
        // Add recent conversation history
        for message in recentMessages {
            if message.senderID == participant.id {
                llmMessages.append(LLMMessage(role: "assistant", content: message.content))
            } else {
                llmMessages.append(LLMMessage(role: "user", content: "\(message.senderName): \(message.content)"))
            }
        }
        
        // Add instruction for next response
        llmMessages.append(LLMMessage(role: "user", content: "Generate your natural response to continue the conversation."))
        
        return try await llmService.generateResponse(
            messages: llmMessages,
            temperature: 0.9,
            maxTokens: 120
        )
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
    
    private func monitorTTSCompletion(for speakerID: String) {
        // Monitor TTS service to update speaking indicators
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if !self.ttsService.isCurrentlySpeaking || self.ttsService.currentSpeaker != speakerID {
                timer.invalidate()
                DispatchQueue.main.async {
                    self.speakingParticipants.remove(speakerID)
                }
            }
        }
    }
    
    func endConversation() {
        recordingTimer?.invalidate()
        volumeTimer?.invalidate()
        aiResponseTimer?.invalidate()
        morganResponseTimer?.invalidate()
        audioRecorder?.stop()
        ttsService.stopSpeaking()
        
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