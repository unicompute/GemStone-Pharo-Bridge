Class {
	#name : 'GbsClassicLauncher',
	#superclass : 'SpPresenter',
	#instVars : [
		'sessionList',
		'parametersList',
		'mainMenu',
		'btnCommit',
		'btnLogout',
		'btnAbort',
		'btnCurrent',
		'btnBegin',
		'btnBreak',
		'btnLoginLink',
		'btnLoginRpc',
		'btnAdd',
		'btnCopy',
		'btnEdit',
		'btnDelete',
		'pollingProcess'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'menus' }
GbsClassicLauncher class >> menuCommandGemStoneOn: aBuilder [
    <worldMenu>
    (aBuilder item: #GemStone)
        order: 79.9;
        label: 'GemStone';
        icon: (self iconNamed: #smallConfiguration);
        with: [
            (aBuilder item: #ClassicLauncher)
                label: 'Classic Launcher';
                action: [ GbsClassicLauncher new open ];
                icon: (self iconNamed: #glamorousGo).
                
            (aBuilder item: #SimpleLauncher)
                label: 'Simple Launcher';
                action: [ GbsLauncher new open ];
                icon: (self iconNamed: #glamorousPlay).
        ].
]

{ #category : 'menus' }
GbsClassicLauncher >> buildMenuBar [
    ^ self newMenuBar
        addGroup: [ :group |
            group
                addItem: [ :item | item name: 'Browse'; subMenu: self menuBrowse ];
                addItem: [ :item | item name: 'Parameters'; subMenu: self menuParameters ];
                addItem: [ :item | item name: 'Session'; subMenu: self menuSession ];
                addItem: [ :item | item name: 'Tools'; subMenu: self menuTools ];
                addItem: [ :item | item name: 'Window'; subMenu: self menuWindow ];
                addItem: [ :item | item name: 'About'; action: [ self inform: 'GBS Classic Launcher for Pharo' ] ]
        ].
]

{ #category : 'initialization' }
GbsClassicLauncher >> connectPresenters [
	"Ensure your commit and abort buttons fire the new logic"
	btnCommit action: [ self doCommit ].
	btnAbort action: [ self doAbort ].
	
	"Also keep any other button wirings you already had here for btnLoginLink, btnAdd, etc..."

]

{ #category : 'layout' }
GbsClassicLauncher >> defaultLayout [
    | topButtons bottomButtons topHalf bottomHalf |
    
    "1. Group the upper buttons together"
    topButtons := SpBoxLayout newLeftToRight
        add: btnLoginLink;
        add: btnLoginRpc;
        add: btnAdd;
        add: btnCopy;
        add: btnEdit;
        add: btnDelete;
        spacing: 5;
        yourself.

    "2. Group the bottom buttons"
    bottomButtons := SpBoxLayout newLeftToRight
        add: btnCommit;
        add: btnLogout;
        add: btnAbort;
        add: btnCurrent;
        add: btnBegin;
        add: btnBreak;
        spacing: 5;
        yourself.

    "3. Group the Top Section (keeps label, list, and buttons tight together)"
    topHalf := SpBoxLayout newTopToBottom
        add: 'Session Parameters' expand: false;
        add: parametersList;
        add: topButtons expand: false;
        yourself.

    "4. Group the Bottom Section (keeps label, list, and buttons tight together)"
    bottomHalf := SpBoxLayout newTopToBottom
        add: 'Active Sessions' expand: false;
        add: sessionList;
        add: bottomButtons expand: false;
        yourself.

    "5. Main Layout: Adds a 10px gap ONLY between the main sections"
    ^ SpBoxLayout newTopToBottom
        spacing: 10;
        add: mainMenu expand: false;
        add: topHalf;       "Gap above 'Session Parameters'"
        add: bottomHalf;    "Gap above 'Active Sessions'"
        yourself
]

{ #category : 'actions' }
GbsClassicLauncher >> doAbort [
	self withSelectedSession: [ :session |
		session abort.
		self inform: 'GemStone: Transaction Aborted and Synced.'.
	].
]

{ #category : 'actions' }
GbsClassicLauncher >> doAddParameter [
	| newParam editor window |
	newParam := GbsSessionParameters new.
	editor := GbsSessionParametersEditor new.
	editor setModel: newParam.
	
	"Pass the save action to the editor"
	editor onAccept: [ 
		GbsSessionParameters addParameter: newParam.
		self refreshAll.
	].
	
	"Open as a standard window (No double buttons)"
	window := editor open.
	window centered.
]

{ #category : 'actions' }
GbsClassicLauncher >> doBegin [
    self withSelectedSession: [ :s | 
        s beginTransaction. 
        self inform: 'Manual Transaction Started'. 
    ].
]

{ #category : 'actions' }
GbsClassicLauncher >> doBreak [
    self withSelectedSession: [ :s | 
        s sendInterrupt. 
        self inform: 'Interrupt Signal Sent'. 
    ].
]

{ #category : 'actions' }
GbsClassicLauncher >> doCommit [
	self withSelectedSession: [ :session |
		session commitTransaction
			ifTrue: [ self inform: 'GemStone: Commit Successful!' ]
			ifFalse: [ self inform: 'GemStone: Commit Failed (Conflict)!' ]
	].
]

{ #category : 'actions' }
GbsClassicLauncher >> doCopyParameter [
    parametersList selection selectedItem ifNotNil: [ :param |
        | newParam |
        newParam := param copy.
        newParam name: param name, ' (copy)'.
        GbsSessionParameters addParameter: newParam.
        self refreshAll.
    ].
]

{ #category : 'actions' }
GbsClassicLauncher >> doDeleteParameter [
    parametersList selection selectedItem ifNotNil: [ :param |
        GbsSessionParameters removeParameter: param.
        self refreshAll.
    ].
]

{ #category : 'actions' }
GbsClassicLauncher >> doEditParameter [
	parametersList selection selectedItem ifNotNil: [ :param |
		| editor window |
		editor := GbsSessionParametersEditor new.
		editor setModel: param.
		
		editor onAccept: [ 
			self refreshAll. 
		].
		
		window := editor open.
		window centered.
	].
]

{ #category : 'actions' }
GbsClassicLauncher >> doLoginRpc [
    parametersList selection selectedItem ifNotNil: [ :params |
        
        "Show progress"
        UIManager default showWaitCursorWhile: [ 
            [
                "Use the SELECTED object to login"
                params login.
                
                "Update the UI"
                self refreshAll.
                
                params isConnected 
                    ifTrue: [ 
                        GbsSessionParameters currentSession: params.
                        self inform: 'Login Successful: ', params name 
                    ].
                
            ] on: Error do: [ :ex | 
                self inform: 'Login Error: ', ex messageText.
                ex inspect. 
            ]
        ].
    ] ifNil: [ self inform: 'Please select a configuration first.' ].
]

{ #category : 'actions' }
GbsClassicLauncher >> doLogout [
    sessionList selection selectedItem ifNotNil: [ :session |
        "1. Unselect first to prevent SubscriptOutOfBounds in Spec2"
        sessionList unselectAll.
        
        "2. Perform the logout"
        session logout.
        
        "3. Clear global current session if it matches"
        GbsSessionParameters currentSession == session ifTrue: [
            GbsSessionParameters currentSession: nil.
        ].
        
        "4. Refresh the UI"
        self refreshAll.
    ].
]

{ #category : 'initialization' }
GbsClassicLauncher >> initializePresenters [
    mainMenu := self buildMenuBar.
    
    "Lists"
    parametersList := self newTable.
    parametersList addColumn: (SpStringTableColumn title: 'Name' evaluated: #name).
    parametersList beSingleSelection.

    sessionList := self newTable.
    sessionList
        addColumn: (SpStringTableColumn title: 'Session ID' evaluated: [ :s | s sessionId asString ]);
        addColumn: (SpStringTableColumn title: 'Name' evaluated: [ :s | s name ]);
        addColumn: (SpStringTableColumn title: 'State' evaluated: [ :s | s isConnected ifTrue: ['Connected'] ifFalse: ['Disconnected'] ]).
    sessionList beSingleSelection.

    "Buttons"
    btnLoginLink := self newButton label: 'Login Link'; icon: (self iconNamed: #glamorousGo); action: [ self doLoginRpc ].
    btnLoginRpc  := self newButton label: 'Login RPC'; icon: (self iconNamed: #glamorousGo); action: [ self doLoginRpc ].
    btnAdd       := self newButton label: 'Add...'; icon: (self iconNamed: #add); action: [ self doAddParameter ].
    btnCopy      := self newButton label: 'Copy'; icon: (self iconNamed: #smallCopy); action: [ self doCopyParameter ].
    btnEdit      := self newButton label: 'Edit...'; icon: (self iconNamed: #edit); action: [ self doEditParameter ].
    btnDelete    := self newButton label: 'Delete'; icon: (self iconNamed: #delete); action: [ self doDeleteParameter ].

    btnCommit := self newButton label: 'Commit'; icon: (self iconNamed: #smallSave); action: [ self doCommit ].
    btnLogout := self newButton label: 'Logout'; icon: (self iconNamed: #smallCancel); action: [ self doLogout ].
    btnAbort  := self newButton label: 'Abort'; icon: (self iconNamed: #smallDelete); action: [ self doAbort ].
    btnCurrent:= self newButton label: 'Current'; icon: (self iconNamed: #smallForward); action: [ self makeCurrent ].
    btnBegin  := self newButton label: 'Begin'; icon: (self iconNamed: #smallUpdate); action: [ self doBegin ].
    btnBreak  := self newButton label: 'Break'; icon: (self iconNamed: #smallCancel); action: [ self doBreak ].

    "--> Wire up the click events to update button states <--"
    parametersList whenSelectionChangedDo: [ :selection | self updateButtonStates ].
    sessionList whenSelectionChangedDo: [ :selection | self updateButtonStates ].

    "--> DOUBLE CLICK ACTION <--"
    sessionList whenActivatedDo: [ :selection | self openWorkspaceFor: selection selectedItem ].

    self refreshAll.
]

{ #category : 'initialization' }
GbsClassicLauncher >> initializeWindow: aWindow [
	aWindow 
		title: 'GemStone Launcher';
		initialExtent: 500@400;
		whenClosedDo: [ self stopPolling ].
	self startPolling.

]

{ #category : 'actions' }
GbsClassicLauncher >> makeCurrent [
    self withSelectedSession: [ :s | 
        GbsSessionParameters currentSession: s.
        self inform: 'Session set as Current'.
        self refreshSessionList.
    ].
]

{ #category : 'menus' }
GbsClassicLauncher >> menuBrowse [
    ^ self newMenu
        addItem: [ :item | item name: 'System'; action: [ self inform: 'System Browser TODO' ] ];
        addItem: [ :item | item name: 'Class...'; action: [ GbsBrowser new open ] ];
        addItem: [ :item | item name: 'Symbol Dictionary...'; action: [ self inform: 'Dict Browser TODO' ] ];
        yourself.
]

{ #category : 'menus' }
GbsClassicLauncher >> menuParameters [
    ^ self newMenu
        addItem: [ :item | item name: 'Add...'; action: [ self inform: 'Add Parameter' ] ];
        addItem: [ :item | item name: 'Edit'; action: [ self inform: 'Edit Parameter' ] ];
        addItem: [ :item | item name: 'Delete'; action: [ self inform: 'Delete Parameter' ] ];
        yourself.
]

{ #category : 'menus' }
GbsClassicLauncher >> menuSession [
    ^ self newMenu
        addItem: [ :item | item name: 'Login'; action: [ self inform: 'Use the main Launcher to create sessions' ] ];
        addItem: [ :item | item name: 'Logout'; action: [ self doLogout ] ];
        addItem: [ :item | item name: 'Commit'; action: [ self doCommit ] ];
        addItem: [ :item | item name: 'Abort'; action: [ self doAbort ] ];
        yourself.
]

{ #category : 'menus' }
GbsClassicLauncher >> menuTools [
    ^ self newMenu
        addItem: [ :item | 
            item name: 'Workspace'; 
            action: [ GbsWorkspace new open ] ];

        addItem: [ :item | 
            item name: 'Transcript'; 
            action: [ 
                | transcriptPresenter |
                transcriptPresenter := GbsRemoteTranscript new.
                transcriptPresenter open.
                transcriptPresenter startPolling.
            ] ];
        addItem: [ :item | item name: 'Toggle Polling'; action: [ GbsSessionParameters togglePolling. self refreshAll ] ];
        yourself.
]

{ #category : 'menus' }
GbsClassicLauncher >> menuWindow [
    ^ self newMenu
        addItem: [ :item | item name: 'Refresh'; action: [ self refreshSessionList ] ];
        addItem: [ :item | item name: 'Close'; action: [ self delete ] ];
        yourself.
]

{ #category : 'actions' }
GbsClassicLauncher >> openWorkspaceFor: aSession [
    aSession ifNil: [ ^ self ].
    
    "1. Ensure this session is the active one globally before opening tools"
    GbsSessionParameters currentSession: aSession.
    self refreshAll.
    
    "2. Open the Workspace"
    GbsWorkspace new open.
]

{ #category : 'actions' }
GbsClassicLauncher >> refreshAll [
    "Use asArray so Spec2 sees a NEW collection and forces a visual refresh"
    parametersList items: GbsSessionParameters allParameters asArray.
    sessionList items: GbsSessionParameters allSessions asArray.
    
    "Safely re-select the current session if it still exists"
    GbsSessionParameters currentSession ifNotNil: [ :current |
        (GbsSessionParameters allSessions includes: current) ifTrue: [ 
            sessionList selectItem: current 
        ]
    ].
    
    self updateButtonStates.
]

{ #category : 'actions' }
GbsClassicLauncher >> refreshSessionList [
    sessionList items: GbsSessionParameters allSessions.
    parametersList items: GbsSessionParameters allParameters. "Assuming this collection exists"
    GbsSessionParameters currentSession ifNotNil: [ :s | sessionList selectItem: s ].
]

{ #category : 'polling' }
GbsClassicLauncher >> startPolling [ 
    pollingProcess ifNotNil: [ pollingProcess terminate ].
    pollingProcess := [ 
        [ self window isNotNil and: [ self window isOpen ] ] whileTrue: [ 
            GbsSessionParameters pollingEnabled ifTrue: [ UIManager default defer: [ self refreshAll ] ].
            (Delay forSeconds: 2) wait.
        ] 
    ] fork.


]

{ #category : 'polling' }
GbsClassicLauncher >> stopPolling [ 
    pollingProcess ifNotNil: [ pollingProcess terminate ].
    pollingProcess := nil.


]

{ #category : 'actions' }
GbsClassicLauncher >> updateButtonStates [
    | selectedParam selectedSession |
    
    selectedParam := parametersList selection selectedItem.
    selectedSession := sessionList selection selectedItem.

    "1. Login buttons: Enable only if a parameter is selected AND it is NOT connected"
    (selectedParam notNil and: [ selectedParam isConnected not ])
        ifTrue: [ 
            btnLoginRpc enable. 
            btnLoginLink enable. 
        ]
        ifFalse: [ 
            btnLoginRpc disable. 
            btnLoginLink disable. 
        ].

    "2. Session buttons (Logout, Commit, etc.): Enable only if an active session is selected"
    selectedSession notNil
        ifTrue: [ 
            btnLogout enable. btnCommit enable. btnAbort enable. 
            btnCurrent enable. btnBegin enable. btnBreak enable. 
        ]
        ifFalse: [ 
            btnLogout disable. btnCommit disable. btnAbort disable. 
            btnCurrent disable. btnBegin disable. btnBreak disable. 
        ].
]

{ #category : 'private' }
GbsClassicLauncher >> withSelectedSession: aBlock [
    sessionList selection selectedItem 
        ifNotNil: [ :session | aBlock value: session ]
        ifNil: [ self inform: 'Please select a session from the list.' ].
]
