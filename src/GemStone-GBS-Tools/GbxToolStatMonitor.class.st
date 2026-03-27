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
		'cacheSampleIntervalMultiplier'
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
	| groupsLayout cacheBox |
	groupsLayout := SpBoxLayout newHorizontal
		spacing: 10.
	cacheStatsGroup := self buildStatGroup: 'Cache Statistics' specs: {
		{ 'Hit Count'. #hitCount }.
		{ 'Miss Count'. #missCount }.
		{ 'Hit Ratio'. #hitRatio }.
		{ 'Proxy Count'. #proxyCount }.
		{ 'Cache Size'. #cacheSize }.
	}.
	cacheBox := SpBoxLayout newVertical spacing: 5.
	cacheBox add: cacheStatsGroup height: 150.
	cacheBox add: chartPanel expand: true.
	groupsLayout add: cacheBox.
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
		add: (self buildStatsGroups);
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
	chartPanel := self newMorph.
	chartPanel morph: (Morph new color: Color white; yourself).
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
	session ifNil: [ ^ self ].
	[
		self fetchAllStats.
		self updateDisplay.
		summaryLabel label: 'Last updated: ', DateAndTime now asString.
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
	| m canvas values keys colors x y maxV graphWidth graphHeight |
	[ 
	m := chartPanel morph.
	m color: Color white.
	m extent: ((self window ifNotNil: [ self window width - 50 ] ifNil: [ 800 ]) @ 500).
	canvas := m canvas.
	graphWidth := m width - 50 max: 400.
	graphHeight := m height - 100 max: 300.
	values := {
		(monitor statAt: 'hitCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		(monitor statAt: 'missCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		(monitor statAt: 'hitRatio' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		(monitor statAt: 'rpcCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		(monitor statAt: 'gcCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
		(monitor statAt: 'objectCount' ifPresent: [ :s | s value ] ifAbsent: [ 0 ]).
	}.
	keys := #('Hits' 'Misses' 'Ratio' 'RPC' 'GC' 'Objects').
	colors := {Color red. Color blue. Color purple. Color green. Color orange. Color brown}.
	maxV := values max max: 1.
	x := 50.
	1 to: values size do: [ :i |
		| v h |
		v := values at: i.
		h := (v / maxV) * graphHeight.
		canvas line: (x @ (50 + graphHeight)) to: ((x + (graphWidth / values size)) @ (50 + graphHeight - h)) color: (colors at: i).
		canvas fillOval: ((x + ((graphWidth / values size) / 2 - 5)) @ (50 + graphHeight - h - 5) extent: 10@10) color: (colors at: i).
		x := x + (graphWidth / values size).
	].
	0 to: graphHeight by: (graphHeight / 5) do: [ :gy | canvas line: 40@(50 + gy) to: (40 + graphWidth)@(50 + gy) color: Color lightGray ].
	0 to: graphWidth by: (graphWidth / 6) do: [ :gx | canvas line: (40 + gx)@50 to: (40 + gx)@(50 + graphHeight) color: Color lightGray ].
	canvas line: 40@50 to: 40@(50 + graphHeight) color: Color black.
	canvas line: 40@(50 + graphHeight) to: (40 + graphWidth)@(50 + graphHeight) color: Color black.
	x := 50.
	1 to: keys size do: [ :i |
		canvas drawString: (keys at: i) at: (x @ (60 + graphHeight)) font: nil color: (colors at: i).
		x := x + (graphWidth / values size).
	].
	] on: Error do: [ :ex | m changed ].
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