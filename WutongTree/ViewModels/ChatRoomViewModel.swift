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
    @Published var isUserSpeaking = false
    @Published var userTranscription = ""
    
    private var chatRoom: ChatRoom?
    private var audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var volumeTimer: Timer?
    private var aiResponseTimer: Timer?
    private var hostPersonality = HostPersonalityService()
    private var cancellables = Set<AnyCancellable>()
    private var conversationStep = 0
    
    // LLM Services
    private var hostLLMService: LLMService?
    private var participantLLMService: LLMService?
    
    // Text-to-Speech Service
    private var ttsService = ElevenLabsTTSService() // Much more natural voices
    
    // Speech-to-Text Service
    private var sttService = SpeechToTextService()
    
    init() {
        setupAudioSession()
        startVolumeMonitoring()
        setupLLMServices()
        setupSpeechToText()
    }
    
    private func setupLLMServices() {
        guard let anthropicKey = LLMConfig.shared.getAnthropicKey() else {
            print("⚠️ ChatRoom: No Anthropic API key found - using fallback responses")
            return
        }
        
        print("✅ ChatRoom: Setting up LLM services with API key")
        
        // Setup AI host service
        hostLLMService = LLMServiceFactory.createService(type: .anthropic, apiKey: anthropicKey)
        print("✅ ChatRoom: Host LLM service created")
        
        // Setup participant service (for Morgan)
        participantLLMService = LLMServiceFactory.createService(type: .anthropic, apiKey: anthropicKey)
        print("✅ ChatRoom: Participant LLM service created")
    }
    
    private func setupSpeechToText() {
        // Monitor speech-to-text transcription
        sttService.$transcribedText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transcription in
                self?.userTranscription = transcription
            }
            .store(in: &cancellables)
        
        // Monitor speech-to-text listening state
        sttService.$isListening
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isListening in
                self?.isUserSpeaking = isListening
                if isListening {
                    self?.speakingParticipants.insert("current_user")
                } else {
                    self?.speakingParticipants.remove("current_user")
                }
            }
            .store(in: &cancellables)
    }
    
    func startUserSpeech() {
        print("ChatRoom: Starting user speech")
        sttService.startListening()
    }
    
    func stopUserSpeech() {
        print("ChatRoom: Stopping user speech")
        sttService.stopListening()
        
        // When user manually stops, send their message
        if !userTranscription.isEmpty {
            addUserMessage(userTranscription)
            
            // Check if user mentioned MoMo
            let lowerText = userTranscription.lowercased()
            if lowerText.contains("momo") || lowerText.contains("host") {
                print("🤖 ChatRoom: User mentioned MoMo, triggering AI response")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.generateAIResponse()
                }
            }
            
            // Trigger participant response after user speaks
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.generateMorganResponse()
            }
        }
    }
    
    func toggleMicrophone() {
        if isUserSpeaking {
            print("ChatRoom: User toggled microphone OFF")
            stopUserSpeech()
        } else {
            print("ChatRoom: User toggled microphone ON")
            startUserSpeech()
        }
    }
    
    private func addUserMessage(_ text: String) {
        guard let chatRoom = chatRoom else { return }
        
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            senderID: "current_user",
            senderName: "You",
            content: text,
            timestamp: Date(),
            messageType: .text
        )
        
        messages.append(userMessage)
        sttService.resetTranscription()
        
        print("ChatRoom: Added user message: \(text)")
    }
    
    func setup(chatRoom: ChatRoom) {
        self.chatRoom = chatRoom
        addWelcomeMessages()
        // Only start AI conversation flow, not automatic participant responses
        startAIConversationFlow()
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
                    self.ttsService.speak(welcomeContent, for: chatRoom.aiHost.id, personality: SpeechPersonality.aiHost)
                    
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
        You're a chat host. Be natural, brief, and conversational.
        
        Generate a short welcome (1 sentence max, 10 words or less). Just say hi and maybe ask a simple question to get people talking.
        
        IMPORTANT: Don't say your name. Just welcome people naturally.
        
        Examples: "Hey everyone! How's your day going?" or "Welcome! What's everyone up to?"
        """
        
        let llmMessages: [LLMMessage] = [
            LLMMessage(role: "system", content: systemPrompt),
            LLMMessage(role: "user", content: "Generate your welcome message to start the conversation.")
        ]
        
        return try await llmService.generateResponse(
            messages: llmMessages,
            temperature: 0.7,
            maxTokens: 25 // Very short responses
        )
    }
    
    private func startAIConversationFlow() {
        // Natural hosting timing - varies based on conversation flow
        aiResponseTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let timeSinceLastMessage = Date().timeIntervalSince(self.messages.last?.timestamp ?? Date.distantPast)
            
            // Natural response timing: 5-12 seconds based on conversation
            let responseThreshold = self.calculateNaturalResponseTime()
            
            if timeSinceLastMessage > responseThreshold {
                // Add slight delay to feel more natural (like thinking)
                let thinkingDelay = Double.random(in: 0.5...2.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + thinkingDelay) {
                    print("🤖 ChatRoom: Natural conversation timing - MoMo responding")
                    self.generateAIResponse()
                }
            }
        }
    }
    
    private func calculateNaturalResponseTime() -> TimeInterval {
        let recentMessages = Array(messages.suffix(3))
        
        // Shorter wait if conversation is active
        if recentMessages.count >= 2 {
            return Double.random(in: 5...8)
        }
        
        // Longer wait if conversation is just starting
        return Double.random(in: 8...12)
    }
    
    
    private func generateAIResponse() {
        guard let chatRoom = chatRoom else { 
            print("⚠️ ChatRoom: No chat room for AI response")
            return 
        }
        
        guard let llmService = hostLLMService else { 
            print("⚠️ ChatRoom: No LLM service - using fallback AI response")
            addFallbackAIResponse()
            return 
        }
        
        print("🤖 ChatRoom: Generating AI response...")
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
                    self.ttsService.speak(response, for: chatRoom.aiHost.id, personality: SpeechPersonality.aiHost)
                    
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
    
    private func addFallbackAIResponse() {
        guard let chatRoom = chatRoom else { return }
        
        let fallbackResponses = [
            "That's really interesting! Can you tell me more about that?",
            "I love hearing different perspectives. What do you think about this topic?",
            "That's a great point! How did you come to that conclusion?",
            "Thanks for sharing that with us. Anyone else have thoughts on this?"
        ]
        
        let response = fallbackResponses.randomElement() ?? "That's fascinating!"
        
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
            print("🤖 ChatRoom: Speaking fallback AI response: \(response)")
            self.ttsService.speak(response, for: chatRoom.aiHost.id, personality: SpeechPersonality.aiHost)
            
            // Monitor TTS completion to update speaking status
            self.monitorTTSCompletion(for: chatRoom.aiHost.id)
        }
    }
    
    private func generateHostResponse(using llmService: LLMService) async throws -> String {
        guard let chatRoom = chatRoom else { throw LLMError.noContentError }
        
        // Get contextual prompt from personality service
        let recentMessages = Array(messages.suffix(5))
        let (systemPrompt, dynamicTemperature) = hostPersonality.generateContextualPrompt(recentMessages: recentMessages)
        
        var llmMessages: [LLMMessage] = [
            LLMMessage(role: "system", content: systemPrompt)
        ]
        
        // Add recent conversation history
        for message in recentMessages {
            let role = message.messageType == .aiGenerated ? "assistant" : "user"
            llmMessages.append(LLMMessage(role: role, content: "\(message.senderName): \(message.content)"))
        }
        
        // Add instruction for next response
        llmMessages.append(LLMMessage(role: "user", content: "Respond naturally to what was just said."))
        
        return try await llmService.generateResponse(
            messages: llmMessages,
            temperature: dynamicTemperature, // Use dynamic temperature based on mood
            maxTokens: 40 // Allow natural length responses
        )
    }
    
    private func generateMorganResponse() {
        guard let chatRoom = chatRoom else { 
            print("⚠️ ChatRoom: No chat room for participant response")
            return 
        }
        
        // Find a participant that is NOT the current user
        // Current user should never have automatic responses generated
        guard let participant = chatRoom.participants.first(where: { $0.name != "小人物" }) else { 
            print("⚠️ ChatRoom: No other participants found (excluding current user)")
            return 
        }
        
        print("👤 ChatRoom: Generating response for participant: \(participant.name)")
        
        guard let llmService = participantLLMService else { 
            print("⚠️ ChatRoom: No participant LLM service - using fallback response")
            addFallbackParticipantResponse(for: participant)
            return 
        }
        
        Task {
            do {
                let response = try await generateParticipantResponse(for: participant, using: llmService)
                
                let participantMessage = ChatMessage(
                    id: UUID().uuidString,
                    senderID: participant.id,
                    senderName: participant.name,
                    content: response,
                    timestamp: Date(),
                    messageType: .text
                )
                
                DispatchQueue.main.async {
                    self.messages.append(participantMessage)
                    self.speakingParticipants.insert(participant.id)
                    
                    // Speak participant's response
                    self.ttsService.speak(response, for: participant.id, personality: SpeechPersonality.participant)
                    
                    // Monitor TTS completion to update speaking status
                    self.monitorTTSCompletion(for: participant.id)
                }
            } catch {
                print("Participant response error: \(error)")
                self.addFallbackParticipantResponse(for: participant)
            }
        }
    }
    
    private func addFallbackParticipantResponse(for participant: User) {
        let fallbackResponses = [
            "That's really interesting! I'd love to hear more about that.",
            "I never thought about it that way. Great perspective!",
            "Absolutely! I totally agree with what you're saying.",
            "That reminds me of something I experienced too.",
            "Wow, that's fascinating! How did you get into that?",
            "I can relate to that. Thanks for sharing!"
        ]
        
        let response = fallbackResponses.randomElement() ?? "That's fascinating!"
        
        let participantMessage = ChatMessage(
            id: UUID().uuidString,
            senderID: participant.id,
            senderName: participant.name,
            content: response,
            timestamp: Date(),
            messageType: .text
        )
        
        DispatchQueue.main.async {
            self.messages.append(participantMessage)
            self.speakingParticipants.insert(participant.id)
            
            // Speak the participant response
            print("👤 ChatRoom: Speaking fallback participant response: \(response)")
            self.ttsService.speak(response, for: participant.id, personality: SpeechPersonality.participant)
            
            // Monitor TTS completion to update speaking status
            self.monitorTTSCompletion(for: participant.id)
        }
    }
    
    private func generateParticipantResponse(for participant: User, using llmService: LLMService) async throws -> String {
        let systemPrompt = """
        You're \(participant.name) in a casual voice chat. Be natural and brief (5-10 words max) like real conversation.
        
        Just respond naturally - agree, ask questions, or share quick thoughts. No emojis needed.
        
        Examples: "Yeah totally!" or "Same here" or "That's interesting" or "Why do you think that?"
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
            temperature: 0.8,
            maxTokens: 20 // Very short responses for cost control
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
        audioRecorder?.stop()
        ttsService.stopSpeaking()
        sttService.stopListening()
        
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