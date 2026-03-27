Class {
	#name : 'GbxToolStatMonitor',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'monitor',
		'statsList',
		'scrollContent',
		'refreshButton',
		'autoRefreshCheckbox',
		'autoRefreshTimer',
		'summaryLabel',
		'cacheStatsGroup',
		'sessionStatsGroup',
		'gcStatsGroup',
		'memoryStatsGroup',
		'cache',
		'process',
		'state',
		'stateChangeProtect',
		'nextResumption',
		'delay',
		'archiver',
		'sampleInterval',
		'cacheSampleIntervalMultiplier',
		'history',
		'graphPresenters'
	],
	#classVars : [
		'Instance',
		'StatMonitorPriority'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxToolStatMonitor class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbxToolStatMonitor class >> openOn: aSession [
	| monitor |
	monitor := self on: aSession.
	monitor open.
	monitor startMonitoring.
	^ monitor
]

{ #category : 'building' }
GbxToolStatMonitor >> buildRefreshControls [
	^ SpBoxLayout newHorizontal
		spacing: 10;
		add: autoRefreshCheckbox;
		add: refreshButton;
		yourself
]

{ #category : 'building' }
GbxToolStatMonitor >> buildStatGroup: title specs: statSpecs [
	| groupLayout |
	groupLayout := SpBoxLayout newVertical
		spacing: 3.
	groupLayout add: (self newLabel label: title; yourself) height: 25.
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
GbxToolStatMonitor >> buildStatsGroups [
	| groupsLayout |
	groupsLayout := SpBoxLayout newHorizontal
		spacing: 10.
	cacheStatsGroup := self buildStatGroup: 'Cache Statistics' specs: {
		{ 'Hit Count'. #hitCount }.
		{ 'Miss Count'. #missCount }.
		{ 'Hit Ratio'. #hitRatio }.
		{ 'Proxy Count'. #proxyCount }.
		{ 'Cache Size'. #cacheSize }.
	}.
	groupsLayout add: cacheStatsGroup.
	sessionStatsGroup := self buildStatGroup: 'Session Statistics' specs: {
		{ 'RPC Count'. #rpcCount }.
		{ 'Commit Count'. #commitCount }.
		{ 'Abort Count'. #abortCount }.
		{ 'Session ID'. #sessionId }.
	}.
	groupsLayout add: sessionStatsGroup.
	gcStatsGroup := self buildStatGroup: 'Garbage Collection' specs: {
		{ 'GC Count'. #gcCount }.
		{ 'GC Time (ms)'. #gcTime }.
		{ 'Objects Scavenged'. #objectsScavenged }.
		{ 'Objects Tenured'. #objectsTenured }.
	}.
	groupsLayout add: gcStatsGroup.
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
GbxToolStatMonitor >> buildToolbar [
	^ SpBoxLayout newHorizontal
		spacing: 10;
		add: autoRefreshCheckbox;
		add: refreshButton width: 120;
		yourself
]

{ #category : 'accessing' }
GbxToolStatMonitor >> cache [
	^ cache
]

{ #category : 'cleanup' }
GbxToolStatMonitor >> close [
	self stopMonitoring.
	super close.
]

{ #category : 'layout' }
GbxToolStatMonitor >> defaultLayout [
	| mainLayout scrollContainer |
	
	scrollContainer := SpScrollableLayout with: scrollContent.
	
	mainLayout := SpBoxLayout newVertical
		spacing: 5;
		add: (self buildToolbar) height: 35;
		add: summaryLabel height: 30;
		add: (self buildStatsGroups) height: 145;
		add: scrollContainer expand: true;
		yourself.
		
	^ mainLayout
]

{ #category : 'fetching' }
GbxToolStatMonitor >> fetchAllStats [
	| sessionStats sessionId rpcCount |
	monitor statAt: 'hitCount' ifPresent: [ :stat | stat value: cache hitCount ].
	monitor statAt: 'missCount' ifPresent: [ :stat | stat value: cache missCount ].
	monitor statAt: 'hitRatio' ifPresent: [ :stat | stat value: (cache hitRatio * 100) ].
	sessionStats := [ session statResource ] on: Error do: [ nil ].
	sessionId := [ session sessionId ] on: Error do: [ 'N/A' ].
	rpcCount := 0.
	monitor statAt: 'sessionId' ifPresent: [ :stat | stat value: sessionId ].
	monitor statAt: 'rpcCount' ifPresent: [ :stat | stat value: rpcCount ].
	monitor statAt: 'commitCount' ifPresent: [ :stat | stat value: 0 ].
	monitor statAt: 'abortCount' ifPresent: [ :stat | stat value: 0 ].
	monitor statAt: 'gcCount' ifPresent: [ :stat | stat value: 0 ].
	monitor statAt: 'gcTime' ifPresent: [ :stat | stat value: 0 ].
	monitor statAt: 'objectsScavenged' ifPresent: [ :stat | stat value: 0 ].
	monitor statAt: 'objectsTenured' ifPresent: [ :stat | stat value: 0 ].
	monitor statAt: 'objectCount' ifPresent: [ :stat | stat value: 0 ].
	monitor statAt: 'byteCount' ifPresent: [ :stat | stat value: 0 ].
	monitor statAt: 'oopCount' ifPresent: [ :stat | stat value: 0 ].
	monitor statAt: 'percentFull' ifPresent: [ :stat | stat value: 0 ].
]

{ #category : 'initialization' }
GbxToolStatMonitor >> initializePresenters [
	| statKeys |
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
	monitor := GbxToolStatResource named: 'Monitor' type: #monitor.
	monitor interval: 5000.
	monitor addStatNamed: 'hitCount' description: 'Cache hits' category: 'Cache'.
	monitor addStatNamed: 'missCount' description: 'Cache misses' category: 'Cache'.
	monitor addStatNamed: 'hitRatio' description: 'Cache hit ratio' category: 'Cache'.
	monitor addStatNamed: 'sessionId' description: 'Session id' category: 'Session'.
	monitor addStatNamed: 'rpcCount' description: 'RPC calls' category: 'Session'.
	monitor addStatNamed: 'commitCount' description: 'Commits' category: 'Session'.
	monitor addStatNamed: 'abortCount' description: 'Aborts' category: 'Session'.
	monitor addStatNamed: 'gcCount' description: 'GC collections' category: 'GC'.
	monitor addStatNamed: 'gcTime' description: 'GC time (ms)' category: 'GC'.
	monitor addStatNamed: 'objectsScavenged' description: 'Objects scavenged' category: 'GC'.
	monitor addStatNamed: 'objectsTenured' description: 'Objects tenured' category: 'GC'.
	monitor addStatNamed: 'objectCount' description: 'Objects' category: 'Memory'.
	monitor addStatNamed: 'byteCount' description: 'Bytes' category: 'Memory'.
	monitor addStatNamed: 'oopCount' description: 'Oops' category: 'Memory'.
	monitor addStatNamed: 'percentFull' description: 'Percent full' category: 'Memory'.
	
	history := OrderedCollection new.
	
	statKeys := #(
		'Hit Count' 'Miss Count' 'Hit Ratio' 'Proxy Count' 'Cache Size'
		'RPC Count' 'Commit Count' 'Abort Count' 'Session ID'
		'GC Count' 'GC Time (ms)' 'Objects Scavenged' 'Objects Tenured'
		'Object Count' 'Byte Count' 'OOP Count' '% Full'
	).
	
	graphPresenters := Dictionary new.
	scrollContent := self newPresenter.
	scrollContent layout: (SpBoxLayout newVertical spacing: 10).
	
	statKeys do: [ :key |
		| img |
		img := self newImage.
		img image: (Form extent: 800 @ 150 depth: 32).
		graphPresenters at: key put: img.
		scrollContent layout add: img height: 150.
	].
	
	self drawGraph.
]

{ #category : 'initialization' }
GbxToolStatMonitor >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GBS Statistics Monitor - 17 Performance Graphs';
		initialExtent: 900 @ 900;
		whenClosedDo: [ self stopMonitoring ].
]

{ #category : 'accessing' }
GbxToolStatMonitor >> monitor [
	^ monitor
]

{ #category : 'actions' }
GbxToolStatMonitor >> refresh [
	session ifNil: [ ^ self ].
]

{ #category : 'monitoring' }
GbxToolStatMonitor >> refreshStats [
	| current |
	session ifNil: [ ^ self ].
	[
		self fetchAllStats.
		self updateDisplay.
		summaryLabel label: 'Last updated: ', (DateAndTime now asString copyUpTo: $.).
		current := Dictionary new.
		current at: #time put: DateAndTime now.
		current at: 'Hit Count' put: (monitor statAt: 'hitCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'Miss Count' put: (monitor statAt: 'missCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'Hit Ratio' put: (monitor statAt: 'hitRatio' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'Proxy Count' put: (cache proxyCount ifNil: [ 0 ]).
		current at: 'Cache Size' put: (cache size ifNil: [ 0 ]).
		current at: 'RPC Count' put: (monitor statAt: 'rpcCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'Commit Count' put: (monitor statAt: 'commitCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'Abort Count' put: (monitor statAt: 'abortCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'GC Count' put: (monitor statAt: 'gcCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'GC Time (ms)' put: (monitor statAt: 'gcTime' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'Objects Scavenged' put: (monitor statAt: 'objectsScavenged' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'Objects Tenured' put: (monitor statAt: 'objectsTenured' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'Object Count' put: (monitor statAt: 'objectCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'Byte Count' put: (monitor statAt: 'byteCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'OOP Count' put: (monitor statAt: 'oopCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: '% Full' put: (monitor statAt: 'percentFull' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: 'Session ID' put: (monitor statAt: 'sessionId' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		
		history add: current.
		history size > 100 ifTrue: [ history removeFirst ].
	] on: Error do: [ :ex |
		summaryLabel label: 'Error: ', ex messageText.
	].
]

{ #category : 'accessing' }
GbxToolStatMonitor >> session [
	^ session
]

{ #category : 'accessing' }
GbxToolStatMonitor >> session: aSession [
	session := aSession.
	cache := GbxBasicCache on: aSession.
]

{ #category : 'monitoring' }
GbxToolStatMonitor >> startMonitoring [
	autoRefreshTimer ifNotNil: [ autoRefreshTimer terminate ].
	autoRefreshTimer := [
		[ autoRefreshCheckbox state ] whileTrue: [
			self refreshStats.
			(Delay forSeconds: 5) wait.
		]
	] forkAt: Processor userBackgroundPriority.
	summaryLabel label: 'Monitoring: Active (5s interval)'.
]

{ #category : 'accessing' }
GbxToolStatMonitor >> stats [
	^ stats ifNil: [ stats := Dictionary new ]
]

{ #category : 'monitoring' }
GbxToolStatMonitor >> stopMonitoring [
	autoRefreshTimer ifNotNil: [
		autoRefreshTimer terminate.
		autoRefreshTimer := nil.
	].
	summaryLabel label: 'Monitoring: Stopped'.
]

{ #category : 'updating' }
GbxToolStatMonitor >> updateDisplay [
	self updateStatGroup: cacheStatsGroup with: {
		{ 'Hit Count'. (monitor statAt: 'hitCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Miss Count'. (monitor statAt: 'missCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Hit Ratio'. (monitor statAt: 'hitRatio' ifPresent: [ :s | s value printString, '%' ] ifAbsent: [ '0%' ]) }.
		{ 'Proxy Count'. (cache proxyCount ifNil: [ 0 ]) }.
		{ 'Cache Size'. (cache size ifNil: [ 0 ]) }.
	}.
	self updateStatGroup: sessionStatsGroup with: {
		{ 'RPC Count'. (monitor statAt: 'rpcCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Commit Count'. (monitor statAt: 'commitCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Abort Count'. (monitor statAt: 'abortCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Session ID'. (monitor statAt: 'sessionId' ifPresent: [ :s | s value ] ifAbsent: [ 'N/A' ]) }.
	}.
	self updateStatGroup: gcStatsGroup with: {
		{ 'GC Count'. (monitor statAt: 'gcCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'GC Time (ms)'. (monitor statAt: 'gcTime' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Objects Scavenged'. (monitor statAt: 'objectsScavenged' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Objects Tenured'. (monitor statAt: 'objectsTenured' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
	}.
	self updateStatGroup: memoryStatsGroup with: {
		{ 'Object Count'. (monitor statAt: 'objectCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'Byte Count'. (monitor statAt: 'byteCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ 'OOP Count'. (monitor statAt: 'oopCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]) }.
		{ '% Full'. (monitor statAt: 'percentFull' ifPresent: [ :s | s value printString, '%' ] ifAbsent: [ '0%' ]) }.
	}.
	self drawGraph.
]

{ #category : 'updating' }
GbxToolStatMonitor >> updateStatGroup: group with: statValues [
	| labels |
	labels := group children select: [ :child | child isKindOf: SpLabelPresenter ].
	labels := labels allButFirst.
	statValues keysAndValuesDo: [ :i :statData |
		i <= labels size ifTrue: [
			| label |
			label := labels at: i.
			label label: statData first, ': ', statData second asString.
		]
	].
]

{ #category : 'graph' }
GbxToolStatMonitor >> drawGraph [
	| graphWidth graphHeight canvas font colors windowSize displayHistory |
	
	graphWidth := 750.
	graphHeight := 100.
	font := LogicalFont familyName: 'Arial' pointSize: 10.
	colors := {Color red. Color blue. Color purple. Color green. Color orange. Color brown. Color cyan. Color magenta. Color gray. Color black}.
	
	windowSize := 20.
	displayHistory := history size > windowSize 
		ifTrue: [ history copyFrom: history size - windowSize + 1 to: history size ]
		ifFalse: [ history ].

	graphPresenters keysAndValuesDo: [ :statName :presenter |
		| form maxV color |
		form := Form extent: 850 @ 150 depth: 32.
		canvas := form getCanvas.
		canvas fillRectangle: (0 @ 0 extent: 850 @ 150) color: (Color white alpha: 0.1).
		canvas frameRectangle: (0 @ 0 extent: 850 @ 150) color: Color lightGray.
		
		color := colors at: ((statName hash abs \\ colors size) + 1).
		
		"Draw Title"
		canvas drawString: statName at: 10 @ 5 font: (LogicalFont familyName: 'Arial' pointSize: 11) color: color.
		
		history ifNotEmpty: [
			| prevX prevY |
			maxV := 1.
			displayHistory do: [ :h | maxV := maxV max: (h at: statName ifAbsent: [ 0 ]) ].
			
			"Draw Grid and Axis"
			canvas line: 50 @ 30 to: 50 @ (30 + graphHeight) width: 1 color: Color black.
			canvas line: 50 @ (30 + graphHeight) to: (50 + graphWidth) @ (30 + graphHeight) width: 1 color: Color black.
			
			"Y-Labels"
			canvas drawString: maxV rounded asString at: 5 @ 25 font: font color: Color gray.
			canvas drawString: (maxV / 2) rounded asString at: 5 @ (30 + (graphHeight / 2) - 5) font: font color: Color gray.
			canvas drawString: '0' at: 5 @ (30 + graphHeight - 5) font: font color: Color gray.

			prevX := nil.
			prevY := nil.
			
			1 to: displayHistory size do: [ :hi |
				| h v yp tx |
				h := displayHistory at: hi.
				v := h at: statName ifAbsent: [ 0 ].
				yp := (30 + graphHeight - ((v / maxV) * graphHeight)) rounded.
				tx := (windowSize > 1) 
					ifTrue: [ (50 + ((hi - 1) / (windowSize - 1) * graphWidth)) rounded ]
					ifFalse: [ 50 + (graphWidth / 2) rounded ].
				
				prevX ifNotNil: [
					canvas line: prevX @ prevY to: tx @ yp width: 2 color: color ].
				canvas fillRectangle: (tx - 2 @ (yp - 2) extent: 4 @ 4) color: color.

				prevX := tx.
				prevY := yp.
			].
			
			"Time Markers"
			{1. (displayHistory size // 2). displayHistory size} do: [ :ti |
				| h ts xPos |
				h := displayHistory at: ti.
				ts := (h at: #time ifAbsent: [ Time now ]) asString copyFrom: 12 to: 19.
				xPos := (50 + ((ti - 1) / (windowSize - 1) * graphWidth)) rounded.
				canvas drawString: ts at: (xPos - 20) @ (30 + graphHeight + 5) font: font color: Color gray.
			].
		].
		
		presenter image: form.
	].
]

{ #category : 'building' }
GbxToolStatMonitor >> buildOtherStatsGroups [
	| groupsLayout |
	groupsLayout := SpBoxLayout newHorizontal spacing: 10.
	groupsLayout add: sessionStatsGroup.
	groupsLayout add: gcStatsGroup.
	groupsLayout add: memoryStatsGroup.
	^ groupsLayout
]
