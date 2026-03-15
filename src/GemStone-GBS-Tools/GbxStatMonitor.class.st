Class {
	#name : 'GbxStatMonitor',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'monitor',
		'statsList',
		'chartPanel',
		'refreshButton',
		'autoRefreshCheckbox',
		'autoRefreshTimer',
		'summaryLabel',
		'cacheStatsGroup',
		'sessionStatsGroup',
		'gcStatsGroup',
		'memoryStatsGroup'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxStatMonitor class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbxStatMonitor class >> openOn: aSession [
	| monitor |
	
	monitor := self on: aSession.
	monitor open.
	monitor startMonitoring.
	^ monitor
]

{ #category : 'layout' }
GbxStatMonitor >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: (self buildToolbar) height: 35;
		add: summaryLabel height: 30;
		add: (self buildStatsGroups);
		add: (self buildRefreshControls) height: 35;
		yourself
]

{ #category : 'building' }
GbxStatMonitor >> buildToolbar [
	^ SpBoxLayout newHorizontal
		spacing: 3;
		add: refreshButton width: 100;
		add: SpSpacer new;
		yourself
]

{ #category : 'building' }
GbxStatMonitor >> buildStatsGroups [
	| groupsLayout |
	
	groupsLayout := SpBoxLayout newHorizontal
		spacing: 10;
		padding: (SpPadding left: 5 top: 5 right: 5 bottom: 5).
	
	"Cache Stats"
	cacheStatsGroup := self buildStatGroup: 'Cache Statistics' specs: {
		{ 'Hit Count'. #hitCount }.
		{ 'Miss Count'. #missCount }.
		{ 'Hit Ratio'. #hitRatio }.
		{ 'Proxy Count'. #proxyCount }.
		{ 'Cache Size'. #cacheSize }.
	}.
	groupsLayout add: cacheStatsGroup.
	
	"Session Stats"
	sessionStatsGroup := self buildStatGroup: 'Session Statistics' specs: {
		{ 'RPC Count'. #rpcCount }.
		{ 'Commit Count'. #commitCount }.
		{ 'Abort Count'. #abortCount }.
		{ 'Session ID'. #sessionId }.
	}.
	groupsLayout add: sessionStatsGroup.
	
	"GC Stats"
	gcStatsGroup := self buildStatGroup: 'Garbage Collection' specs: {
		{ 'GC Count'. #gcCount }.
		{ 'GC Time (ms)'. #gcTime }.
		{ 'Objects Scavenged'. #objectsScavenged }.
		{ 'Objects Tenured'. #objectsTenured }.
	}.
	groupsLayout add: gcStatsGroup.
	
	"Memory Stats"
	memoryStatsGroup := self buildStatGroup: 'Memory Statistics' specs: {
		{ 'Object Count'. #objectCount }.
		{ 'Byte Count'. #byteCount }.
		{ 'OOP Count'. #oopCount }.
		{ '% Full'. #percentFull }.
	}.
	groupsLayout add: memoryStatsGroup.
	
	^ groupsLayout
]

{ #category : 'building' }
GbxStatMonitor >> buildStatGroup: title specs: statSpecs [
	"Build a stat group with title and stat items"
	| groupLayout statLabels |
	
	groupLayout := SpBoxLayout newVertical
		spacing: 3;
		padding: (SpPadding left: 10 top: 10 right: 10 bottom: 10).
	
	"Title"
	groupLayout add: (self newLabel label: title; emphasis: #bold; yourself) height: 25.
	
	"Stat items"
	statSpecs do: [ :spec |
		| label |
		label := self newLabel
			label: spec first, ': --';
			yourself.
		
		groupLayout add: label height: 20.
	].
	
	^ groupLayout
]

{ #category : 'building' }
GbxStatMonitor >> buildRefreshControls [
	^ SpBoxLayout newHorizontal
		spacing: 10;
		add: SpSpacer new;
		add: autoRefreshCheckbox;
		add: refreshButton;
		yourself
]

{ #category : 'initialization' }
GbxStatMonitor >> initializePresenters [
	summaryLabel := self newLabel.
	summaryLabel label: 'Monitoring: Not started'.
	
	refreshButton := self newButton
		label: '⟳ Refresh Now';
		action: [ self refreshStats ].
	
	autoRefreshCheckbox := self newCheckBox
		label: 'Auto-refresh (5s)';
		state: false;
		whenChangedDo: [ :state |
			state ifTrue: [ self startMonitoring ] ifFalse: [ self stopMonitoring ].
		].
	
	"Initialize monitor"
	monitor := GbxStatMonitor on: session.
	monitor interval: 5000.
	
	"Add stats to monitor"
	monitor addStatNamed: 'hitCount' description: 'Cache hits' category: 'Cache'.
	monitor addStatNamed: 'missCount' description: 'Cache misses' category: 'Cache'.
	monitor addStatNamed: 'hitRatio' description: 'Cache hit ratio' category: 'Cache'.
	monitor addStatNamed: 'rpcCount' description: 'RPC calls' category: 'Session'.
	monitor addStatNamed: 'commitCount' description: 'Commits' category: 'Session'.
	monitor addStatNamed: 'abortCount' description: 'Aborts' category: 'Session'.
	monitor addStatNamed: 'gcCount' description: 'GC collections' category: 'GC'.
	monitor addStatNamed: 'gcTime' description: 'GC time (ms)' category: 'GC'.
	monitor addStatNamed: 'objectCount' description: 'Objects' category: 'Memory'.
	monitor addStatNamed: 'byteCount' description: 'Bytes' category: 'Memory'.
]

{ #category : 'initialization' }
GbxStatMonitor >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GBS Statistics Monitor';
		initialExtent: 1000 @ 600.
]

{ #category : 'monitoring' }
GbxStatMonitor >> startMonitoring [
	"Start auto-refresh monitoring"
	
	autoRefreshTimer ifNotNil: [ autoRefreshTimer terminate ].
	
	autoRefreshTimer := [
		[ autoRefreshCheckbox state ] whileTrue: [
			self refreshStats.
			(Delay forSeconds: 5) wait.
		]
	] forkAt: Processor backgroundPriority.
	
	summaryLabel label: 'Monitoring: Active (5s interval)'.
	summaryLabel foreground: (Color green).
]

{ #category : 'monitoring' }
GbxStatMonitor >> stopMonitoring [
	"Stop auto-refresh monitoring"
	
	autoRefreshTimer ifNotNil: [
		autoRefreshTimer terminate.
		autoRefreshTimer := nil.
	].
	
	summaryLabel label: 'Monitoring: Stopped'.
	summaryLabel foreground: (Color red).
]

{ #category : 'monitoring' }
GbxStatMonitor >> refreshStats [
	"Refresh all statistics"
	
	session ifNil: [ ^ self ].
	
	[
		"Fetch stats from server"
		self fetchAllStats.
		
		"Update display"
		self updateDisplay.
		
		summaryLabel label: 'Last updated: ', DateAndTime now asString.
		summaryLabel foreground: (Color black).
		
	] on: Error do: [ :ex |
		summaryLabel label: 'Error: ', ex messageText.
		summaryLabel foreground: (Color red).
	].
]

{ #category : 'fetching' }
GbxStatMonitor >> fetchAllStats [
	"Fetch all statistics from server"
	| script result parts |
	
	"Fetch cache stats"
	monitor statAt: 'hitCount' ifPresent: [ :stat |
		stat value: cache hitCount.
	].
	monitor statAt: 'missCount' ifPresent: [ :stat |
		stat value: cache missCount.
	].
	monitor statAt: 'hitRatio' ifPresent: [ :stat |
		stat value: (cache hitRatio * 100).
	].
	
	"Fetch session stats"
	script := '[
		| sess stream |
		sess := GsCurrentSession current.
		stream := WriteStream on: String new.
		stream
			nextPutAll: sess sessionId asString; nextPutAll: ''|'';
			nextPutAll: sess rpcCount asString; nextPutAll: ''|'';
			nextPutAll: sess commitCount asString; nextPutAll: ''|'';
			nextPutAll: sess abortCount asString.
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	result ifNotNil: [
		parts := result splitOn: $|.
		parts size >= 4 ifTrue: [
			monitor statAt: 'sessionId' ifPresent: [ :stat | stat value: parts first ].
			monitor statAt: 'rpcCount' ifPresent: [ :stat | stat value: parts second asInteger ].
			monitor statAt: 'commitCount' ifPresent: [ :stat | stat value: parts third asInteger ].
			monitor statAt: 'abortCount' ifPresent: [ :stat | stat value: parts fourth asInteger ].
		].
	].
	
	"Fetch GC stats"
	script := '[
		| stream |
		stream := WriteStream on: String new.
		stream
			nextPutAll: System vmGcCount asString; nextPutAll: ''|'';
			nextPutAll: System vmGcTime asString; nextPutAll: ''|'';
			nextPutAll: System objectsScavenged asString; nextPutAll: ''|'';
			nextPutAll: System objectsTenured asString.
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	result ifNotNil: [
		parts := result splitOn: $|.
		parts size >= 4 ifTrue: [
			monitor statAt: 'gcCount' ifPresent: [ :stat | stat value: parts first asInteger ].
			monitor statAt: 'gcTime' ifPresent: [ :stat | stat value: parts second asInteger ].
			monitor statAt: 'objectsScavenged' ifPresent: [ :stat | stat value: parts third asInteger ].
			monitor statAt: 'objectsTenured' ifPresent: [ :stat | stat value: parts fourth asInteger ].
		].
	].
	
	"Fetch memory stats"
	script := '[
		| stream |
		stream := WriteStream on: String new.
		stream
			nextPutAll: System objectCount asString; nextPutAll: ''|'';
			nextPutAll: System byteCount asString; nextPutAll: ''|'';
			nextPutAll: System oopCount asString; nextPutAll: ''|'';
			nextPutAll: System percentFull asString.
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	result ifNotNil: [
		parts := result splitOn: $|.
		parts size >= 4 ifTrue: [
			monitor statAt: 'objectCount' ifPresent: [ :stat | stat value: parts first asInteger ].
			monitor statAt: 'byteCount' ifPresent: [ :stat | stat value: parts second asInteger ].
			monitor statAt: 'oopCount' ifPresent: [ :stat | stat value: parts third asInteger ].
			monitor statAt: 'percentFull' ifPresent: [ :stat | stat value: parts fourth asInteger ].
		].
	].
]

{ #category : 'updating' }
GbxStatMonitor >> updateDisplay [
	"Update the display with current stats"
	
	"Update cache stats"
	self updateStatGroup: cacheStatsGroup with: {
		{ 'Hit Count'. (monitor statAt: 'hitCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Miss Count'. (monitor statAt: 'missCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Hit Ratio'. (monitor statAt: 'hitRatio' ifPresent: [ :s | s value printString, '%' ] ifAbsent: [ '0%' ]) }.
		{ 'Proxy Count'. (cache proxyCount ifNil: [ 0 ]) }.
		{ 'Cache Size'. (cache size ifNil: [ 0 ]) }.
	}.
	
	"Update session stats"
	self updateStatGroup: sessionStatsGroup with: {
		{ 'RPC Count'. (monitor statAt: 'rpcCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Commit Count'. (monitor statAt: 'commitCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Abort Count'. (monitor statAt: 'abortCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Session ID'. (monitor statAt: 'sessionId' ifPresent: [ :s | s value ] ifAbsent: [ 'N/A' ]) }.
	}.
	
	"Update GC stats"
	self updateStatGroup: gcStatsGroup with: {
		{ 'GC Count'. (monitor statAt: 'gcCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'GC Time (ms)'. (monitor statAt: 'gcTime' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Objects Scavenged'. (monitor statAt: 'objectsScavenged' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Objects Tenured'. (monitor statAt: 'objectsTenured' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
	}.
	
	"Update memory stats"
	self updateStatGroup: memoryStatsGroup with: {
		{ 'Object Count'. (monitor statAt: 'objectCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Byte Count'. (monitor statAt: 'byteCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'OOP Count'. (monitor statAt: 'oopCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ '% Full'. (monitor statAt: 'percentFull' ifPresent: [ :s | s value printString, '%' ] ifAbsent: [ '0%' ]) }.
	}.
]

{ #category : 'updating' }
GbxStatMonitor >> updateStatGroup: group with: statValues [
	"Update a stat group with new values"
	| labels |
	
	labels := group children select: [ :child | child isKindOf: SpLabelPresenter ].
	labels := labels allButFirst. "Skip title"
	
	statValues keysAndValuesDo: [ :i :statData |
		i <= labels size ifTrue: [
			| label |
			label := labels at: i.
			label label: statData first, ': ', statData second asString.
		]
	].
]

{ #category : 'accessing' }
GbxStatMonitor >> session [
	^ session
]

{ #category : 'accessing' }
GbxStatMonitor >> session: aSession [
	session := aSession.
	cache := GbxBasicCache on: aSession.
]

{ #category : 'accessing' }
GbxStatMonitor >> monitor [
	^ monitor
]

{ #category : 'accessing' }
GbxStatMonitor >> cache [
	^ cache
]

{ #category : 'cleanup' }
GbxStatMonitor >> close [
	"Clean up when closing"
	
	self stopMonitoring.
	
	super close.
]
