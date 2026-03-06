Class {
	#name : 'GbsRemoteTranscript',
	#superclass : 'SpPresenter',
	#instVars : [
		'textPresenter',
		'btnClear'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'setup' }
GbsRemoteTranscript class >> installForwarder [
  "Connect Pharo's system Transcript to our custom window"

  "GbsRemoteTranscript installForwarder."

  Transcript announcer
    when: StringSignal
    do: [ :signal | self allInstancesDo: [ :win | win appendLog: signal message ] ]
    for: self
]

{ #category : 'updating' }
GbsRemoteTranscript class >> drainCurrentSessionLogsToWindowsAndLocal [
	| session |
	session := GbsSessionParameters currentSession.
	session ifNil: [ ^ '' ].
	^ self drainSessionLogsToWindowsAndLocal: session
]

{ #category : 'updating' }
GbsRemoteTranscript class >> drainSessionLogsToWindowsAndLocal: aSession [
	| newLogs safeLogs |
	aSession ifNil: [ ^ '' ].
	newLogs := [ aSession fetchTranscriptLogs ] on: Error do: [ '' ].
	(newLogs isNil or: [ newLogs isEmpty ]) ifTrue: [ ^ '' ].
	safeLogs := newLogs asString.
	(safeLogs beginsWith: 'Error:') ifTrue: [ ^ '' ].
	self allInstancesDo: [ :win | win appendLog: safeLogs ].
	Transcript show: safeLogs.
	^ safeLogs
]

{ #category : 'gemstone integration' }
GbsRemoteTranscript class >> installGemStoneProxy [

  | session script aGbsRemoteTranscript |
  aGbsRemoteTranscript := self new.
  session := GbsSessionParameters currentSession.
  session ifNil: [ ^ aGbsRemoteTranscript inform: 'Please log in to GemStone first!' ].

  "1. Write the script using backticks (`) and double quotes ("") to avoid escaping nightmares"
  script := '
	| proxyClass |
	proxyClass := Object subclass: `PharoTranscriptProxy`
		instVarNames: #()
		classVars: #()
		classInstVars: #(`currentLine`)
		poolDictionaries: #()
		inDictionary: UserGlobals.

	proxyClass class compileMethod: `show: aString
		currentLine := (currentLine ifNil: [ """" ]), aString asString.`
	category: `logging`.

	proxyClass class compileMethod: `cr
		| log |
		log := SessionTemps current at: #PharoTranscriptLog ifAbsentPut: [ OrderedCollection new ].
		log add: (currentLine ifNil: [ """" ]).
		currentLine := """".`
	category: `logging`.

	UserGlobals at: #Transcript put: proxyClass.
	System commitTransaction.
	true.'.

  "2. Safely swap them back to actual Smalltalk single quotes before sending!"
  script := script copyReplaceAll: '`' with: ''''.
  script := script copyReplaceAll: '"' with: ''''.

  "3. Send the pristine script to GemStone safely"
  [
    session evaluate: script.
    aGbsRemoteTranscript inform: 'GemStone Transcript Proxy Successfully Installed!'
    ]
    on: Error
    do: [ :ex | aGbsRemoteTranscript inform: 'Installation failed: ' , ex description ]
]

{ #category : 'gemstone integration' }
GbsRemoteTranscript class >> installTransientProxy [
	| session script |
	session := GbsSessionParameters currentSession.
	session ifNil: [ ^ self inform: 'Log in to GemStone first!' ].

	"Use <quote> substitution to completely avoid FFI string-escaping crashes!"
	script := '
	| tempDict proxyClass |
	tempDict := SymbolDictionary new name: #PharoSessionGlobals.
	
	proxyClass := Object subclass: <quote>PharoTranscriptProxy<quote>
		instVarNames: #() classVars: #() classInstVars: #(<quote>currentLine<quote>)
		poolDictionaries: #() inDictionary: tempDict options: #().
		
	proxyClass class compileMethod: <quote>show: aString
		currentLine := (currentLine ifNil: [ <quote><quote> ]), aString asString.<quote> category: <quote>logging<quote>.
		
	proxyClass class compileMethod: <quote>cr
		| log |
		log := SessionTemps current at: #PharoTranscriptLog ifAbsentPut: [ OrderedCollection new ].
		log add: (currentLine ifNil: [ <quote><quote> ]).
		currentLine := <quote><quote>.<quote> category: <quote>logging<quote>.
		
	tempDict at: #Transcript put: proxyClass.
	
	"Inject dictionary at the front of the search path to shadow the real Transcript"
	System myUserProfile insertDictionary: tempDict at: 1.
	true
	' copyReplaceAll: '<quote>' with: ''''.

	session evaluate: script.
	self inform: 'Remote Transcript Proxy Installed safely!'.
]

{ #category : 'logic' }
GbsRemoteTranscript >> appendLog: aString [
	UIManager default defer: [
		| current |
		current := textPresenter text ifNil: [ '' ].
		textPresenter text: current asString, aString.
	].
]

{ #category : 'logging' }
GbsRemoteTranscript >> cr [
	"Safely ignore! Our appendLog: method already adds a carriage return automatically."
]

{ #category : 'layout' }
GbsRemoteTranscript >> defaultLayout [
	^ SpBoxLayout newVertical
		add: btnClear expand: false fill: false padding: 2;
		add: textPresenter;
		yourself
]

{ #category : 'updating' }
GbsRemoteTranscript >> fetchNewEntries [
	| session newLogs currentText |
	
	"1. Get the session safely"
	session := GbsSessionParameters currentSession.
	session ifNil: [ ^ self ].
	
	"2. Fetch using our mathematically proven backend method"
	newLogs := session fetchTranscriptLogs.
	
	"3. If it's empty or an error, do absolutely nothing"
	(newLogs isNil or: [ newLogs isEmpty ]) ifTrue: [ ^ self ].
	(newLogs beginsWith: 'Error:') ifTrue: [ ^ self ].
	
	"4. Safely append the new logs to the Spec2 Text Presenter"
	currentText := textPresenter text ifNil: [ '' ].
	textPresenter text: currentText asString, newLogs.
	
	"5. Optional: If your Spec2 text presenter supports it, scroll to the bottom"
	"textEditor cursorPosition: textEditor text size."
]

{ #category : 'logging' }
GbsRemoteTranscript >> flush [
	"Sometimes called by outcalls. Safely ignore."
]

{ #category : 'initialization' }
GbsRemoteTranscript >> initializePresenters [
	textPresenter := self newText.
	textPresenter beNotEditable.
	
	btnClear := self newButton.
	btnClear label: 'Clear'; icon: (self iconNamed: #smallDelete).
	btnClear action: [ textPresenter text: '' ].
]

{ #category : 'initialization' }
GbsRemoteTranscript >> initializeWindow: aWindowPresenter [
	aWindowPresenter 
		title: 'GemStone Remote Transcript (VW Port)';
		initialExtent: 600@400.
]

{ #category : 'initialization' }
GbsRemoteTranscript >> installGemStoneProxy [
	^ self class installGemStoneProxy
]

{ #category : 'logging' }
GbsRemoteTranscript >> show: aString [
	"Catch the GemStone outcall and push it to the UI thread"
	UIManager default defer: [
		self class allInstancesDo: [ :win | 
			win appendLog: aString asString 
		]
	].
]

{ #category : 'initialization' }
GbsRemoteTranscript >> startPolling [
	"Deprecated: The VW port uses push-updates instead of polling. Safely ignore."
	^ self.
]

{ #category : 'initialization' }
GbsRemoteTranscript >> stopPolling [
	"Deprecated: Safely ignore."
	^ self.
]
