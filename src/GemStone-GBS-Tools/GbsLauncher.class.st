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
	btnWorkspace action: [ self openWorkspace ].
	btnBrowser action: [ UIManager default defer: [ self openSystemBrowser ] ].
	btnTranscript action: [ self openTranscript ].
	btnUsers action: [ UIManager default defer: [ self openUsers ] ].
	btnPolling action: [ self togglePollingPreference ].
]

{ #category : 'actions' }
GbsLauncher >> openSystemBrowser [
	| session |
	session := GbsAdminSessionSupport currentUsableSessionOrInform.
	session ifNil: [ ^ self ].
	GbsAdminSessionSupport publishCurrentSession: session.
	[
		GbsBrowser openOn: session
	] on: Error do: [ :ex |
		self inform: 'Could not open browser: ', ex messageText
	].
]

{ #category : 'actions' }
GbsLauncher >> openUsers [
	| session |
	session := GbsAdminSessionSupport currentUsableSessionOrInform.
	session ifNil: [ ^ self ].
	GbsAdminSessionSupport publishCurrentSession: session.
	[
		GbsUserListPresenter openOn: session
	] on: Error do: [ :ex |
		self inform: 'Could not open users list: ', ex messageText
	].
]

{ #category : 'actions' }
GbsLauncher >> openWorkspace [
	| session workspaceClass |
	session := GbsAdminSessionSupport currentUsableSessionOrInform.
	session ifNil: [ ^ self ].
	workspaceClass := Smalltalk at: #GbsWorkspace ifAbsent: [ nil ].
	workspaceClass ifNil: [ ^ self inform: 'Workspace presenter unavailable.' ].
	GbsAdminSessionSupport publishCurrentSession: session.
	[
		workspaceClass new open
	] on: Error do: [ :ex |
		self inform: 'Could not open workspace: ', ex messageText
	].
]

{ #category : 'actions' }
GbsLauncher >> openTranscript [
	| session transcriptClass presenter |
	session := GbsAdminSessionSupport currentUsableSessionOrInform.
	session ifNil: [ ^ self ].
	transcriptClass := Smalltalk at: #GbsRemoteTranscript ifAbsent: [ nil ].
	transcriptClass ifNil: [ ^ self inform: 'Remote transcript unavailable.' ].
	GbsAdminSessionSupport publishCurrentSession: session.
	[
		presenter := transcriptClass new.
		presenter open.
		(presenter respondsTo: #startPolling) ifTrue: [ presenter startPolling ]
	] on: Error do: [ :ex |
		self inform: 'Could not open remote transcript: ', ex messageText
	].
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
	activeSession := self activeSessionParameters.
	activeSession ifNil: [ ^ self ].
	activeSession abortTransaction.
	self inform: 'GemStone: Global Transaction Aborted.'.
]

{ #category : 'actions' }
GbsLauncher >> doCommit [
	| activeSession |
	activeSession := self activeSessionParameters.
	activeSession ifNil: [ ^ self ].
	activeSession commitTransaction
		ifTrue: [ self inform: 'GemStone: Global Commit Successful!' ]
		ifFalse: [ self inform: 'GemStone: Global Commit Failed (Conflict)!' ].
]

{ #category : 'actions' }
GbsLauncher >> doLogin [
	| libPath stone user password |
	libPath := inputLibPath text.
	stone := inputStone text.
	user := inputUser text.
	password := inputPass text.

	statusLabel label: 'Status: Connecting...'.
	btnLogin disable.
	inputStone disable.
	inputUser disable.
	inputPass disable.
	inputLibPath disable.

	self
		runBackgroundProcessNamed: 'GBS Launcher Login for ', user, '@', stone
		do: [
			| session errorText params refreshErrorText |
			session := nil.
			errorText := nil.
			refreshErrorText := nil.
			[
				GbsServerInterface uniqueInstance libraryPath: libPath.
				params := GbsSessionParameters new
					name: ('{1}@{2}' format: { user. stone });
					gemStoneName: stone;
					username: user;
					password: password;
					yourself.
				session := params login
			] on: Error do: [ :ex |
				errorText := ex messageText ].

			self deferUI: [
				errorText ifNotNil: [
					self inform: 'Connection Failed: ', errorText.
					self updateUIState.
					^ self ].

				session ifNil: [
					self inform: 'Connection Failed: login returned no session.'.
					self updateUIState.
					^ self ].

				GbsAdminSessionSupport publishCurrentSession: session.
				[ self ensureCurrentSessionVisibleInAllSessionsForUser: user stone: stone ] on: Error do: [ ].
				[ self refreshAllLaunchers ] on: Error do: [ :ex |
					refreshErrorText := ex messageText ].
				self updateUIState.
				refreshErrorText ifNotNil: [
					self inform: 'Connected, but some windows did not refresh: ', refreshErrorText ]
					ifNil: [ self inform: 'Connected Successfully!' ] ] ]
]

{ #category : 'actions' }
GbsLauncher >> doLogout [
    [
        | sessionParam currentSession logoutSessionId |
        sessionParam := self activeSessionParameters.
        currentSession := GbsSessionParameters currentSession.
        logoutSessionId := self sessionIdFrom: sessionParam.
        logoutSessionId ifNil: [ logoutSessionId := self sessionIdFrom: currentSession ].

        sessionParam
            ifNotNil: [ sessionParam logout ]
            ifNil: [
                (currentSession notNil and: [ currentSession respondsTo: #logout ])
                    ifTrue: [ currentSession logout ] ].

        logoutSessionId ifNotNil: [
            GbsSessionParameters allSessions
                removeAllSuchThat: [ :each |
                    (each respondsTo: #sessionId)
                        and: [ ([ each sessionId ] on: Error do: [ nil ]) = logoutSessionId ] ] ].

        GbsSessionParameters allSessions
            removeAllSuchThat: [ :each |
                (each respondsTo: #isConnected)
                    and: [ ([ each isConnected ] on: Error do: [ false ]) = false ] ].

        ((GbsSessionParameters currentSession notNil)
            and: [ (GbsSessionParameters currentSession respondsTo: #isLoggedIn)
            and: [ ([ GbsSessionParameters currentSession isLoggedIn ] on: Error do: [ false ]) = false ] ])
            ifTrue: [ GbsSessionParameters currentSession: nil ].

        self refreshAllLaunchers.
        
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
    super initializeWindow: aWindowPresenter.
    aWindowPresenter 
        title: 'GemStone GBS Launcher';
        initialExtent: 350@420.
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
	activeSession := self activeSessionParameters.
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

{ #category : 'private' }
GbsLauncher >> activeSessionParameters [
	| current currentSessionId |
	current := GbsSessionParameters currentSession.
	currentSessionId := (current notNil and: [ current respondsTo: #sessionId ])
		ifTrue: [ [ current sessionId ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].

	(currentSessionId notNil) ifTrue: [
		^ GbsSessionParameters allSessions
			detect: [ :each |
				(each respondsTo: #isConnected)
					and: [ ([ each isConnected ] on: Error do: [ false ])
					and: [ (each respondsTo: #sessionId)
					and: [ ([ each sessionId ] on: Error do: [ nil ]) = currentSessionId ] ] ] ]
			ifNone: [ self firstConnectedSessionParameters ] ].

	^ self firstConnectedSessionParameters
]

{ #category : 'private' }
GbsLauncher >> ensureCurrentSessionVisibleInAllSessions [
	^ self
		ensureCurrentSessionVisibleInAllSessionsForUser: inputUser text
		stone: inputStone text
]

{ #category : 'private' }
GbsLauncher >> ensureCurrentSessionVisibleInAllSessionsForUser: userName stone: stoneName [
	| current currentSessionId existing |
	current := GbsSessionParameters currentSession.
	currentSessionId := self sessionIdFrom: current.
	currentSessionId ifNil: [ ^ self ].

	existing := GbsSessionParameters allSessions
		detect: [ :each |
			(each respondsTo: #sessionId)
				and: [ ([ each sessionId ] on: Error do: [ nil ]) = currentSessionId ] ]
		ifNone: [ nil ].
	existing ifNotNil: [ ^ self ].

	existing := GbsSessionParameters new
		name: ('{1}@{2}' format: { userName. stoneName });
		gemStoneName: stoneName;
		username: userName;
		yourself.
	existing instVarNamed: 'sessionId' put: currentSessionId.
	GbsSessionParameters registerSession: existing
]

{ #category : 'private' }
GbsLauncher >> firstConnectedSessionParameters [
	^ GbsSessionParameters allSessions
		detect: [ :each |
			(each respondsTo: #isConnected)
				and: [ [ each isConnected ] on: Error do: [ false ] ] ]
		ifNone: [ nil ]
]

{ #category : 'private' }
GbsLauncher >> refreshAllLaunchers [
	UIManager default defer: [
		GbsLauncher allInstancesDo: [ :each |
			[ each updateUIState ] on: Error do: [ ] ].
		GbsSessionBrowserPresenter allInstancesDo: [ :presenter |
			(presenter respondsTo: #refreshAll) ifTrue: [
				[ presenter refreshAll ] on: Error do: [ ] ] ].
		GbsClassicLauncher allInstancesDo: [ :each |
			[ each refreshAll ] on: Error do: [ ] ] ]
]

{ #category : 'private' }
GbsLauncher >> deferUI: aBlock [
	[
		UIManager default defer: aBlock
	] on: Error do: [
		aBlock value ]
]

{ #category : 'private' }
GbsLauncher >> runBackgroundProcessNamed: aString do: aBlock [
	| process |
	process := aBlock gbxNewProcessNamed: aString.
	process priority: Processor userBackgroundPriority.
	process resume.
	^ process
]

{ #category : 'private' }
GbsLauncher >> sessionIdFrom: anObject [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #sessionId)
		ifTrue: [ ^ [ anObject sessionId ] on: Error do: [ nil ] ].
	^ nil
]

{ #category : 'private' }
GbsLauncher >> isSessionUsableForBrowsing: aSession [
	aSession ifNil: [ ^ false ].
	((aSession respondsTo: #execute:) or: [ aSession respondsTo: #executeAndFetch: ])
		ifFalse: [ ^ false ].
	(aSession respondsTo: #isLoggedIn)
		ifTrue: [ ^ [ aSession isLoggedIn == true ] on: Error do: [ false ] ].
	^ true
]
