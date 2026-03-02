Class {
	#name : 'GbsLauncher',
	#superclass : 'SpPresenter',
	#instVars : [
		'inputStone',
		'inputUser',
		'inputPass',
		'inputLibPath',
		'btnLogin',
		'btnLogout',
		'btnCommit',
		'btnAbort',
		'btnWorkspace',
		'btnBrowser',
		'btnTranscript',
		'btnPolling',
		'btnUsers',
		'statusLabel',
		'pollingProcess'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'initialization' }
GbsLauncher >> connectPresenters [
	btnLogin action: [ self doLogin ].
	btnLogout action: [ self doLogout ].
	btnCommit action: [ self doCommit ].
	btnAbort action: [ self doAbort ].
	btnWorkspace action: [ GbsWorkspace new open ].
	btnBrowser action: [ GbsBrowser new open ].
	
	"Wire the Transcript button to open our custom VW-ported window!"
	btnTranscript action: [ GbsRemoteTranscript new open ].
	
	btnUsers action: [ GbsUserListPresenter new open ].
	btnPolling action: [ self togglePollingPreference ].
]

{ #category : 'layout' }
GbsLauncher >> defaultLayout [
	^ SpBoxLayout newVertical spacing: 5;
		add: (SpGridLayout new
			add: 'Stone:' atPoint: 1@1; add: inputStone atPoint: 2@1;
			add: 'User:' atPoint: 1@2; add: inputUser atPoint: 2@2;
			add: 'Pass:' atPoint: 1@3; add: inputPass atPoint: 2@3;
			add: 'Lib:' atPoint: 1@4; add: inputLibPath atPoint: 2@4 span: 3@1;
			yourself) height: 130;
		add: (SpBoxLayout newHorizontal add: btnLogin; add: btnLogout; yourself) height: 30;
		add: (SpBoxLayout newHorizontal add: btnCommit; add: btnAbort; yourself) height: 30;
		add: (SpBoxLayout newVertical
			add: 'Tools' asPresenter;
			add: btnWorkspace; add: btnBrowser; add: btnTranscript; add: btnUsers; add: btnPolling;
			yourself);
		add: statusLabel;
		yourself
]

{ #category : 'actions' }
GbsLauncher >> doAbort [
	| activeSession |
	activeSession := GbsSessionParameters allSessions detect: [ :each | each name = 'Simple Launcher Session' ] ifNone: [ ^ self ].
	activeSession abort.
	self inform: 'GemStone: Global Transaction Aborted.'.
]

{ #category : 'actions' }
GbsLauncher >> doCommit [
	| activeSession |
	activeSession := GbsSessionParameters allSessions detect: [ :each | each name = 'Simple Launcher Session' ] ifNone: [ ^ self ].
	activeSession commitTransaction
		ifTrue: [ self inform: 'GemStone: Global Commit Successful!' ]
		ifFalse: [ self inform: 'GemStone: Global Commit Failed (Conflict)!' ].
]

{ #category : 'actions' }
GbsLauncher >> doLogin [
    | session |
    statusLabel label: 'Status: Connecting...'.
    [
        GbsServerInterface uniqueInstance libraryPath: inputLibPath text.
        
        "THE FIX: Remove any stale Simple Launcher Sessions first to prevent duplicates"
        GbsSessionParameters allSessions 
            removeAllSuchThat: [ :each | each name = 'Simple Launcher Session' ].
        
        session := GbsSessionParameters new
            name: 'Simple Launcher Session';
            gemStoneName: inputStone text;
            username: inputUser text;
            password: inputPass text;
            login.
                    
        GbsSessionParameters currentSession: session.
        
        UIManager default defer: [
            GbsLauncher allInstancesDo: [ :each | each updateUIState ].
            GbsClassicLauncher allInstancesDo: [ :each | each refreshAll ].
        ].
        
        self inform: 'Connected Successfully!'.
            
    ] on: Error do: [ :ex | 
        self inform: 'Connection Failed: ', ex messageText.
        self updateUIState.
    ].
]

{ #category : 'actions' }
GbsLauncher >> doLogout [
    [
        | sessionToLogout |
        
        sessionToLogout := GbsSessionParameters allSessions 
            detect: [ :each | each name = 'Simple Launcher Session' ] 
            ifNone: [ GbsSessionParameters currentSession ].
            
        sessionToLogout ifNotNil: [ :s | s logout ].
        
        GbsSessionParameters currentSession: nil.
        
        "Sync ALL open Simple Launchers and Classic Launchers safely"
        UIManager default defer: [
            GbsLauncher allInstancesDo: [ :launcher | launcher updateUIState ].
            GbsClassicLauncher allInstancesDo: [ :launcher | launcher refreshAll ].
        ].
        
    ] on: Error do: [ :ex | self inform: 'Error logging out: ', ex messageText ].
]

{ #category : 'initialization' }
GbsLauncher >> initializePresenters [
	"1. Login Parameters (with your Mac path preserved)"
	inputStone := self newTextInput text: 'gs64stone'.
	inputUser := self newTextInput text: 'DataCurator'.
	inputPass := self newTextInput text: 'swordfish'; bePassword.
	inputLibPath := self newTextInput 
		text: '/Users/tariq/GemStone64Bit3.7.4.3-arm64.Darwin/lib/libgcirpc-3.7.4.3-64.dylib';
		placeholder: 'Path to libgcirpc.dylib'.

	"2. Login Buttons"
	btnLogin := self newButton label: 'Login'; icon: (self iconNamed: #smallOk).
	btnLogout := self newButton label: 'Logout'; icon: (self iconNamed: #smallCancel).
	
	"3. Transaction Buttons"
	btnCommit := self newButton label: 'Commit'; icon: (self iconNamed: #smallSave).
	btnAbort := self newButton label: 'Abort'; icon: (self iconNamed: #smallCancel).

	"4. Tools"
	btnWorkspace := self newButton label: 'Workspace'; icon: (self iconNamed: #smallWindow).
	btnBrowser := self newButton label: 'Browser'; icon: (self iconNamed: #smallSystemBrowser).
	btnTranscript := self newButton label: 'Transcript'; icon: (self iconNamed: #transcript).
	btnUsers := self newButton label: 'Users'; icon: (self iconNamed: #user).
	btnPolling := self newButton label: 'Toggle Polling'.
	statusLabel := self newLabel label: 'Status: Disconnected'.

	self updateUIState.
]

{ #category : 'initialization' }
GbsLauncher >> initializeWindow: aWindowPresenter [
    aWindowPresenter 
        title: 'GemStone GBS Launcher';
        initialExtent: 350@400.
]

{ #category : 'polling' }
GbsLauncher >> startPolling [ 
    pollingProcess ifNotNil: [ pollingProcess terminate ].
    pollingProcess := [ 
        [ self window isNotNil and: [ self window isOpen ] ] whileTrue: [ 
            GbsSessionParameters pollingEnabled ifTrue: [ UIManager default defer: [ self updateUIState ] ].
            (Delay forSeconds: 2) wait.
        ] 
    ] fork.

]

{ #category : 'polling' }
GbsLauncher >> stopPolling [ 
    pollingProcess ifNotNil: [ pollingProcess terminate ].
    pollingProcess := nil.

]

{ #category : 'polling' }
GbsLauncher >> togglePollingPreference [
    GbsSessionParameters togglePolling.
    self updatePollingLabel.


]

{ #category : 'polling' }
GbsLauncher >> updatePollingLabel [ 
    btnPolling label: (GbsSessionParameters pollingEnabled ifTrue: [ 'Polling: On' ] ifFalse: [ 'Polling: Off' ]).

]

{ #category : 'updating' }
GbsLauncher >> updateUIState [
	| activeSession |
	activeSession := GbsSessionParameters allSessions detect: [ :each | each name = 'Simple Launcher Session' ] ifNone: [ nil ].
	self updatePollingLabel.

	activeSession ifNotNil: [
		statusLabel label: 'Status: Connected to ', activeSession gemStoneName.
		btnLogin disable.
		inputStone disable. inputUser disable. inputPass disable. inputLibPath disable.
		btnLogout enable. 
		
		"Defensive checks: Only enable if the button actually exists!"
		btnCommit ifNotNil: [ btnCommit enable ]. 
		btnAbort ifNotNil: [ btnAbort enable ].
		
		btnWorkspace enable. btnBrowser enable. btnTranscript enable.
		btnUsers ifNotNil: [ btnUsers enable ].
	] ifNil: [
		statusLabel label: 'Status: Disconnected'.
		btnLogin enable.
		inputStone enable. inputUser enable. inputPass enable. inputLibPath enable.
		btnLogout disable. 
		
		"Defensive checks: Only disable if the button actually exists!"
		btnCommit ifNotNil: [ btnCommit disable ]. 
		btnAbort ifNotNil: [ btnAbort disable ].
		
		btnWorkspace disable. btnBrowser disable. btnTranscript disable.
		btnUsers ifNotNil: [ btnUsers disable ].
	].
]
