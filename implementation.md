# A. User Journey of a WutongTree User 

Step-1: app user: Tommy. 20 years old. male. wants to talk about politics and how it affects hummanity. 
Step-2: Tommy discovers WutongTree app in IOS app store, which contains a description of what WutongTree is.
Step-3: Tommy sign up a free 7 day account with his gmail/facebook or apple account.
Step-4: Tommy logs in WutongTree after it's installed. 
Step-5: The app has a big microphone button in the middle. WutongTree will be prompted to answer a few questions which takes 20 min or so.
Step-6.1: Tommy can enter his information in the profile tab. He can upload his photo, enter age, interest activities, what he looks for etc.
Step-6.2: Tommy MUST finish answering all the questions before WutongTree can match him another user. Only Tommy finishes all the qeustions, he can start to match. This is an elevated threshold for uesrs.
Step-7: Tommy clicks on the microphone button, starts to talk to WutongTree. 
Step-8: WutongTree asks: what topic are you interested in chatting today? and based on his response, WutongTree will try to solicit his thoughts and backgrounds and education levels.
Step-9: WutongTree does personality and topic analysis to find him a match after Tommy answers all the questions. 
Step-10: Tommy is matched with another user. A chat room icon is shown to replace the microphone.  He has 5 min to enter the chat room.
Step-11: Tommy clicked on the chat room and enter a voice chatting room with Tommy's photo, and Jane's photo, and Momo's photo, all three can chat freely.
Step-12: Momo, is an AI host, she will guide the conversation and make sure the conversations go well. 
Step-13: Tommy or Jane can both initiate a recording of their conversation at any time, the other one can agree or reject.  
Step-14: Tommy and Jane can end the conversation any time. If any one ends the conversation, the other one quits immediately. 
Step-15: Their conversation is recorded and saved to users' phone storage, which they can share in their social media or podcast.
Step-16: Tommy found WutongTree very interesting. He can subscribe to the monthly plan at $10/month.
Step-17: After each session of conversation, Tommy is prompted to rate the experience, provide feedback on their match and suggest improvements.



# B. Establish foundational infrastructure

B.1. Choose languages and frameworks:

    Use Python and Pytorchfor machine‑learning/AI services together with the extensive ecosystem (Hugging Face, speech‑processing libraries). Always use open source models if possible. During testing, remember to create python virtual environment for each python micro services. 
    
    TypeScript with Node.js (Express or NestJS) or Golang (Gin) are suitable for API‑focused services due to strong support for REST/gRPC and good performance.
    
    Rust or Go can be used for performance‑critical components like the Real‑Time Communication Service.
    
    For the mobile client, use Swift for iOS.

    Scalability: Design services to scale horizontally. Use Kubernetes auto‑scaling and consider using message queues (Kafka, RabbitMQ) for decoupled processing.

B.2 CI/CD
    Set up a continuous‑integration pipeline (GitHub Actions, GitLab CI, or CircleCI). Configure the pipeline to run unit tests, static analysis (ESLint for TypeScript, flake8/black for Python), and security scans on each push. Must have unit tests for every functions.

    Create a dedicated test environment with deployed containers of all microservices for end to end tsting.
    
    Use a test automation framework Detox for mobile apps to script end‑to‑end scenarios: user sign‑up, onboarding voice session, match generation, MoMo‑hosted conversation and feedback submission.
    
    Simulate network conditions (latency, packet loss) during calls to ensure resilience.
    
    Include chaos testing (e.g., with Gremlin) to verify system stability when individual services fail.

B.3 microservice protocols

    Define communication protocols:
    
    Use REST or GraphQL for external APIs exposed to the mobile clients.
    
    Use gRPC with Protocol Buffers for internal microservice communication to ensure type safety and low latency.
    
    Adopt JSON Web Tokens (JWT) for authentication tokens.

B.4 Deployment 
    Containerization and orchestration:

    Package each microservice in its own Docker image. Use docker‑compose for local development and Kubernetes for staging/production deployments.

    Use an API gateway (e.g., Kong, Istio) to route requests and handle authentication and rate‑limiting.



B.5 Logging
    Error handling and observability: Implement centralized logging (ELK stack), distributed tracing (Jaeger/OpenTelemetry), and metrics collection (Prometheus/Grafana). Write meaningful error messages and ensure graceful failure.

B.6 Secuity 

    Use HTTPS/TLS for all external communication. Sanitize all user inputs, follow OWASP guidelines, and implement role‑based access control.

    Data privacy: Employ encryption at rest and in transit, anonymize personal data where possible, and comply with privacy regulations (GDPR, CCPA). Define data retention policies.



C. Specific instructions for each service

C.1. Implement the Auth & Identity Service
    Language and stack: Use Node.js/NestJS with TypeScript for its built‑in support for dependency injection and modularity.
    
    Features: Implement sign‑up/log‑in via email, apple ID, and third‑party OAuth. Integrate voice‑biometric verification as an optional step (can call an external vendor’s API).
    
    Data storage: Use PostgreSQL to store user accounts, with password hashing (bcrypt).
    
    Testing:
    
    Write unit tests for registration, login, token generation, and voice‑verification functions using Jest.
    
    Include integration tests to ensure correct interaction with PostgreSQL and token middleware. Use a test database container in CI.
    
    Use test doubles (mocks) for external voice‑verification APIs.

C.2. Build the User Profile Service
    Stack: Use Python with FastAPI for rapid development.
    
    Responsibilities: Store and retrieve basic demographics, preferences (orientation, relationship goals), onboarding responses, and match history.
    
    Data storage: Use PostgreSQL or MongoDB; ensure encryption at rest.
    
    Testing:
    
    Use pytest with pytest‑asyncio to test each endpoint (create, update, get, delete).
    
    Mock authentication tokens during tests.
    
    Ensure schema validation with pydantic models and test invalid input cases.

C.3. Voice Capture & Speech‑to‑Text Service
    Stack: Implement the streaming server in Go (for performance) or Node.js. Use WebRTC/WebSocket to receive audio streams from the mobile client.
    
    Speech‑to‑text:
    
    Integrate with cloud STT services (Google Cloud Speech‑to‑Text, Amazon Transcribe) or host an open‑source model (Coqui STT).
    
    Provide a fallback service in Python (e.g., using Vosk library) for offline or privacy‑focused scenarios.
    
    Testing:
    
    Write unit tests in Go or Node.js for audio buffering and streaming logic, mocking the STT provider.
    
    Use integration tests to stream sample audio files and verify transcript accuracy.
    
    Automate load tests (e.g., using Locust) to ensure the service handles concurrent streams.

C.4. Personality & Preference Analysis Service
    Stack: Python; leverage PyTorch for model inference.
    
    Models: Fine‑tuned models that extract sentiment, tone and personality traits from voice, transcripts and prosodic features (pitch, energy). Use pre‑trained emotion recognition models as a starting point.
    
    API: Expose a gRPC endpoint that accepts text and audio feature vectors and returns a structured personality profile.
    
    Testing:
    
    Write unit tests for feature‑extraction functions and model inference pipelines.
    
    Use pytest with fixtures containing sample transcripts and audio features.
    
    Validate model outputs against ground‑truth data when available.
    
    Include integration tests that call the gRPC API via a test client.

C.5. Matchmaking Service
    Stack: Python for machine‑learning models; Go if needed concurrency advantages.
    
    Logic:
    
    Begin with rule‑based filtering (location proximity, age range, orientation).
    
    Implement a basic Matchmaking service that takes user preferences and personality vectors to generate compatibility scores. Start with rule‑based filters (age, location, orientation) and gradually incorporate machine‑learning models.
    
    The model Implements a compatibility scoring system using a machine‑learning model (e.g., gradient boosting or neural networks) trained on historical dataset and online learning with personality traits.
    
    Respect daily/weekly match limits to combat fatigue.
    
    API: Provide gRPC endpoints to request matches for a user and to update feedback scores.
    
    Testing:
    
    Unit‑test individual scoring functions and rule filters.
    
    Use pytest or Go’s testing library to create synthetic user profiles and verify that the top matches satisfy basic criteria.
    
    Write integration tests that simulate a full match request and ensure that the returned candidates do not violate constraints (e.g., age, distance).

C.6. Room Management
    Stack: Node.js (NestJS) or Go; choose one language consistently across low‑latency services to ease maintenance.
    
    Responsibilities: Manage the lifecycle of “rooms” (voice‑only, NO video). Connect matched users when both confirm. Keep state in an in‑memory store like Redis.
    
    Testing:
    
    Unit tests for room creation, user joining, and session termination.
    
    Integration tests that simulate two clients connecting over WebSocket and verify handshake and teardown.
    
    Use end‑to‑end tests with the mobile client stub to ensure room provisioning works across the network.

C.7. MoMo Conversation Host Service
    Stack: Python with FastAPI; integrate a large language model (via OpenAI API or locally hosted LLaMA/GPT‑like model).
    
    Features:
    
    Manage the flow of onboarding questions.
    Manage the AI host service. 
    
    Fine‑tune a conversational LLM to act as a matchmaker and moderator. Train on sample scripts, ice‑breakers and dating etiquette.
    
    Allow MoMo to adapt its prompts based on personality profiles (e.g., humorous for extroverts, gentler for introverts). Feedback, iteration & continuous learning, Generate contextual prompts, jokes and conversation topics.
    
    Interact via voice, text input using TTS (use Amazon Polly or an open‑source TTS engine).
    
    Query moderation service when it detects negative sentiment or safety issues.
    
    Integrate with the Content Moderation service to monitor live conversations. If harmful speech is detected, instruct MoMo to intervene or terminate the call.
    
    Testing:
    
    Unit tests for conversation‑state management and prompt generation.
    
    Mock the LLM in tests to avoid external calls and ensure deterministic responses.
    
    Integration tests with the Real‑Time Communication service to verify that TTS messages are delivered correctly.
    
    Include conversational QA tests (using frameworks like pytest‑httpx) to ensure MoMo’s responses follow guidelines and avoid harmful content.

C.8. Real‑Time Communication Service
    Stack: Use Go or Rust for performance. Integrate Pion (Go WebRTC) or mediasoup for Node.js.
    
    Responsibilities: Handle WebRTC signalling, NAT traversal (STUN/TURN), and media relays. Provide APIs for clients to exchange session descriptions and ICE candidates.
    
    Testing:
    
    Unit tests for signalling message handling.
    
    End‑to‑end tests using headless browsers or WebRTC test clients to initiate calls and verify media flows. Use tools like Playwright or Puppeteer to automate call flows.
    
    Include load tests to validate scaling under multiple concurrent sessions.

C.9. Content Moderation & Safety Service
    Stack: Python; integrate models for hate‑speech detection, explicit content classification and sentiment analysis.
    
    Features: Provide streaming analysis of transcripts or audio; raise alerts or call MoMo to intervene. Maintain user report logs.
    
    Testing:
    
    Unit tests for text classification functions using sample abusive and safe content.
    
    Integration tests with MoMo to ensure that flagged content triggers appropriate interventions.
    
    Red‑team tests to evaluate detection accuracy and false positives.

C.10. Feedback & Learning Service
    Stack: Python; implement endpoints to collect ratings and qualitative feedback from users.
    
    Storage: Use a separate datastore (e.g., time‑series database or Elasticsearch) to track feedback over time.
    
    Training pipeline: Periodically retrain personality and matchmaking models using new data; run experiments in a controlled environment before deploying.
    
    Testing:
    
    Unit tests for feedback parsing and data storage functions.
    
    Integration tests with the Matchmaking and Personality services to ensure updated models are consumed correctly.
    
    Validate that feedback does not leak personally identifiable information.

C.11. Notification & Payment Services
    Notification Service:
    
    Use Node.js or Go; integrate with Firebase Cloud Messaging and Twilio.
    
    Provide endpoints to schedule and send notifications (match found, reminder to join the session, feedback prompts).
    
    Unit test message formatting and scheduling logic; integration test with sandbox notification providers.
    
    Payment Service:
    
    Use a well‑supported payment library (e.g., Stripe SDK) in Node.js.
    
    Implement subscription management and one‑time charges for premium services.
    
    Unit test billing logic with mocked payment gateways; integration test in a sandbox environment.















