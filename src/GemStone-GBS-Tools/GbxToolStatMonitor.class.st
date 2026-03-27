Class {
	#name : 'GbxToolStatMonitor',
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
		'history'
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
	^ SpBoxLayout newVertical
		spacing: 5;
		add: (self buildToolbar) height: 35;
		add: summaryLabel height: 30;
		add: (self buildStatsGroups) height: 145;
		add: chartPanel expand: true;
		yourself
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
	chartPanel := self newImage.
	chartPanel image: (Form extent: 800@400 depth: 32).
	history := OrderedCollection new.
	self drawGraph.
]

{ #category : 'initialization' }
GbxToolStatMonitor >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GBS Statistics Monitor';
		initialExtent: 1000 @ 800;
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
		current at: #hit put: (monitor statAt: 'hitCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: #miss put: (monitor statAt: 'missCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: #ratio put: (monitor statAt: 'hitRatio' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: #rpc put: (monitor statAt: 'rpcCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: #gc put: (monitor statAt: 'gcCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		current at: #objects put: (monitor statAt: 'objectCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		history add: current.
		history size > 20 ifTrue: [ history removeFirst ].
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
	| form graphWidth graphHeight keys colors maxV canvas font |
	[
	form := Form extent: 800@450 depth: 32.
	canvas := form getCanvas.
	canvas fillRectangle: (0@0 extent: 800@450) color: Color white.

	graphWidth := 650.
	graphHeight := 300.
	font := LogicalFont familyName: 'Arial' pointSize: 10.

	"Draw Axes Labels"
	canvas drawString: 'Value' at: 5@10 font: font color: Color black.
	canvas drawString: 'Time' at: (40 + graphWidth) @ (50 + graphHeight + 10) font: font color: Color black.

	history ifEmpty: [
		"Draw axes"
		canvas line: 40@50 to: 40@(50 + graphHeight) width: 1 color: Color black.
		canvas line: 40@(50 + graphHeight) to: (40 + graphWidth)@(50 + graphHeight) width: 1 color: Color black.
		chartPanel image: form.
		^ self ].

	keys := #('hit' 'miss' 'ratio' 'rpc' 'gc' 'objects').
	colors := {Color red. Color blue. Color purple. Color green. Color orange. Color brown}.

	maxV := 1.
	history do: [ :h | keys do: [ :k | maxV := maxV max: (h at: k ifAbsent: [0]) ] ].

	"Draw Grid"
	0 to: 5 do: [ :gi |
		| gy |
		gy := (50 + (gi * (graphHeight / 5))) rounded.
		canvas line: 40@gy to: (40 + graphWidth)@gy width: 1 color: Color lightGray.
		canvas drawString: (maxV - (gi * (maxV / 5))) rounded asString at: 5@ (gy - 5) font: font color: Color gray.
	].

	1 to: keys size do: [ :ki |
		| k col prevX prevY |
		k := keys at: ki.
		col := colors at: ki.
		prevX := nil.
		prevY := nil.
		
		"Draw Data Lines"
		1 to: history size do: [ :i |
			| h v yPos thisX |
			h := history at: i.
			v := h at: k ifAbsent: [0].
			yPos := (50 + graphHeight - ((v / maxV) * graphHeight)) rounded.
			thisX := (history size > 1) 
				ifTrue: [ (40 + ((i - 1) / (history size - 1) * graphWidth)) rounded ]
				ifFalse: [ 40 + (graphWidth / 2) rounded ].
			prevX ifNotNil: [
				canvas line: prevX@prevY to: thisX@yPos width: 2 color: col ].
			canvas fillRectangle: (thisX - 2 @ (yPos - 2) extent: 4@4) color: col.

			prevX := thisX.
			prevY := yPos.
		].

		"Draw Legend (Key)"
		| legendX legendY |
		legendX := 40 + ((ki - 1) // 3 * 200).
		legendY := 50 + graphHeight + 40 + ((ki - 1) \\ 3 * 20).
		canvas line: legendX @ legendY to: (legendX + 20) @ legendY width: 3 color: col.
		canvas drawString: k at: (legendX + 25) @ (legendY - 7) font: font color: Color black.
	].

	"Draw Time markers on X-axis"
	history size > 1 ifTrue: [
		{1. history size // 2. history size} do: [ :idx |
			| h timeStr tx |
			h := history at: idx.
			timeStr := (h at: #time ifAbsent: [Time now]) asString copyFrom: 12 to: 19.
			tx := (40 + ((idx - 1) / (history size - 1) * graphWidth)) rounded.
			canvas drawString: timeStr at: (tx - 20) @ (50 + graphHeight + 5) font: font color: Color gray.
		]
	].

	"Draw axes"
	canvas line: 40@50 to: 40@(50 + graphHeight) width: 1 color: Color black.
	canvas line: 40@(50 + graphHeight) to: (40 + graphWidth)@(50 + graphHeight) width: 1 color: Color black.

	chartPanel image: form.
	] on: Error do: [ :ex |
		Transcript show: 'DrawGraph error: ', ex messageText; cr.
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