Class {
	#name : 'GbxToolStatMonitor',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'monitor',
		'refreshButton',
		'autoRefreshCheckbox',
		'autoRefreshTimer',
		'summaryLabel',
		'cache',
		'history',
		'graphPresenters',
		'valueLabels',
		'cacheKeys',
		'sessionKeys',
		'gcKeys',
		'memoryKeys',
		'allKeys'
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
GbxToolStatMonitor >> buildGraphCell: key [
	| cell color colors |
	colors := {Color red. Color blue. Color purple. Color green. Color orange. Color brown. Color cyan. Color magenta. Color gray. Color black}.
	color := colors at: ((key hash abs \\ colors size) + 1).
	
	cell := self newPresenter.
	cell layout: (SpBoxLayout newVertical
		spacing: 2;
		add: (valueLabels at: key) height: 20;
		add: (graphPresenters at: key) expand: true;
		yourself).
	^ cell
]

{ #category : 'building' }
GbxToolStatMonitor >> buildToolbar [
	^ SpBoxLayout newHorizontal
		spacing: 10;
		add: autoRefreshCheckbox;
		add: refreshButton width: 120;
		yourself
]

{ #category : 'cleanup' }
GbxToolStatMonitor >> close [
	self stopMonitoring.
	super close.
]

{ #category : 'layout' }
GbxToolStatMonitor >> defaultLayout [
	| mainLayout gridLayout scrollContainer |
	
	gridLayout := SpGridLayout new
		columnSpacing: 15;
		rowSpacing: 15;
		beColumnNotHomogeneous;
		beRowNotHomogeneous;
		yourself.
		
	"Row 1: Column Headers"
	gridLayout add: (self newLabel label: 'Cache Statistics'; yourself) atPoint: 1 @ 1.
	gridLayout add: (self newLabel label: 'Session Statistics'; yourself) atPoint: 2 @ 1.
	gridLayout add: (self newLabel label: 'Garbage Collection'; yourself) atPoint: 3 @ 1.
	gridLayout add: (self newLabel label: 'Memory Statistics'; yourself) atPoint: 4 @ 1.
		
	"Col 1: Cache (Row 2-6)"
	cacheKeys keysAndValuesDo: [ :idx :key | gridLayout add: (self buildGraphCell: key) atPoint: 1 @ (idx + 1) ].
		
	"Col 2: Session (Row 2-5)"
	sessionKeys keysAndValuesDo: [ :idx :key | gridLayout add: (self buildGraphCell: key) atPoint: 2 @ (idx + 1) ].
		
	"Col 3: GC (Row 2-5)"
	gcKeys keysAndValuesDo: [ :idx :key | gridLayout add: (self buildGraphCell: key) atPoint: 3 @ (idx + 1) ].
		
	"Col 4: Memory (Row 2-5)"
	memoryKeys keysAndValuesDo: [ :idx :key | gridLayout add: (self buildGraphCell: key) atPoint: 4 @ (idx + 1) ].

	scrollContainer := SpScrollableLayout child: (self newPresenter layout: gridLayout; yourself).

	mainLayout := SpBoxLayout newVertical
		spacing: 5;
		add: (self buildToolbar) height: 35;
		add: summaryLabel height: 30;
		add: scrollContainer expand: true;
		yourself.
		
	^ mainLayout
]

{ #category : 'fetching' }
GbxToolStatMonitor >> fetchAllStats [
	| sessionId rpcCount |
	monitor statAt: 'hitCount' ifPresent: [ :stat | stat value: cache hitCount ].
	monitor statAt: 'missCount' ifPresent: [ :stat | stat value: cache missCount ].
	monitor statAt: 'hitRatio' ifPresent: [ :stat | stat value: (cache hitRatio * 100) ].
	sessionId := [ session sessionId ] on: Error do: [ 0 ].
	rpcCount := 0.
	monitor statAt: 'sessionId' ifPresent: [ :stat | stat value: sessionId ].
	monitor statAt: 'rpcCount' ifPresent: [ :stat | stat value: rpcCount ].
	"Initialize other stats in monitor to 0"
	#( 'commitCount' 'abortCount' 'gcCount' 'gcTime' 'objectsScavenged' 'objectsTenured' 'objectCount' 'byteCount' 'oopCount' 'percentFull')
		do: [ :k | monitor statAt: k ifPresent: [ :s | s value: 0 ] ].
]

{ #category : 'initialization' }
GbxToolStatMonitor >> initializePresenters [
	| colors |
	summaryLabel := self newLabel label: 'Monitoring: Not started'.
	refreshButton := self newButton label: '⟳ Refresh Now'; action: [ self refreshStats ].
	autoRefreshCheckbox := self newCheckBox label: 'Auto-refresh (5s)'; state: false;
		whenChangedDo: [ :state | state ifTrue: [ self startMonitoring ] ifFalse: [ self stopMonitoring ] ].
		
	cacheKeys := #( 'Hit Count' 'Miss Count' 'Hit Ratio' 'Proxy Count' 'Cache Size' ).
	sessionKeys := #( 'RPC Count' 'Commit Count' 'Abort Count' 'Session ID' ).
	gcKeys := #( 'GC Count' 'GC Time (ms)' 'Objects Scavenged' 'Objects Tenured' ).
	memoryKeys := #( 'Object Count' 'Byte Count' 'OOP Count' '% Full' ).
	allKeys := cacheKeys, sessionKeys, gcKeys, memoryKeys.

	monitor := GbxToolStatResource named: 'Monitor' type: #monitor.
	#( 'hitCount' 'missCount' 'hitRatio' 'sessionId' 'rpcCount' 'commitCount' 'abortCount' 
	   'gcCount' 'gcTime' 'objectsScavenged' 'objectsTenured' 'objectCount' 'byteCount' 'oopCount' 'percentFull')
		do: [ :k | monitor addStatNamed: k description: k category: 'System' ].
	
	history := OrderedCollection new.
	graphPresenters := Dictionary new.
	valueLabels := Dictionary new.
	colors := {Color red. Color blue. Color purple. Color green. Color orange. Color brown. Color cyan. Color magenta. Color gray. Color black}.
	
	allKeys do: [ :key |
		| img lbl color |
		img := self newImage.
		img image: (Form extent: 250 @ 100 depth: 32).
		graphPresenters at: key put: img.
		
		color := colors at: ((key hash abs \\ colors size) + 1).
		lbl := self newLabel.
		lbl color: color.
		valueLabels at: key put: lbl.
	].
	
	self drawGraph.
]

{ #category : 'initialization' }
GbxToolStatMonitor >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GBS Statistics Monitor - Matrix';
		initialExtent: 1200 @ 900;
		whenClosedDo: [ self stopMonitoring ].
]

{ #category : 'monitoring' }
GbxToolStatMonitor >> refreshStats [
	| current |
	session ifNil: [ ^ self ].
	[
		self fetchAllStats.
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
		self updateDisplay.
	] on: Error do: [ :ex |
		summaryLabel label: 'Error: ', ex messageText.
	].
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

{ #category : 'monitoring' }
GbxToolStatMonitor >> stopMonitoring [
	autoRefreshTimer ifNotNil: [ autoRefreshTimer terminate. autoRefreshTimer := nil ].
	summaryLabel label: 'Monitoring: Stopped'.
]

{ #category : 'updating' }
GbxToolStatMonitor >> updateDisplay [
	| timeStr |
	timeStr := Time now asString copyUpTo: $. .
	summaryLabel label: 'Last updated: ', timeStr.
	self window ifNotNil: [ :w | w title: 'GBS Monitor Matrix - ', timeStr ].
	
	allKeys do: [ :key |
		| label val suffix |
		label := valueLabels at: key.
		val := history ifEmpty: [ 0 ] ifNotEmpty: [ history last at: key ifAbsent: [ 0 ] ].
		suffix := (#('Hit Ratio' '% Full') includes: key) ifTrue: [ '%' ] ifFalse: [ '' ].
		label label: key, ': ', (val isNumber ifTrue: [ val rounded ] ifFalse: [ val ]) asString, suffix.
	].
	self drawGraph.
]

{ #category : 'graph' }
GbxToolStatMonitor >> drawGraph [
	| colors windowSize displayHistory actualWindow gWidth gHeight |
	
	colors := {Color red. Color blue. Color purple. Color green. Color orange. Color brown. Color cyan. Color magenta. Color gray. Color black}.
	windowSize := 20.
	displayHistory := (history size > windowSize) 
		ifTrue: [ history copyFrom: history size - windowSize + 1 to: history size ]
		ifFalse: [ history ].
	actualWindow := windowSize max: displayHistory size.
	gWidth := 180.
	gHeight := 60.

	allKeys do: [ :key |
		| presenter form canvas maxV color |
		presenter := graphPresenters at: key.
		form := Form extent: 250 @ 100 depth: 32.
		canvas := form getCanvas.
		canvas fillRectangle: (0 @ 0 extent: 250 @ 100) color: Color white.
		canvas frameRectangle: (0 @ 0 extent: 250 @ 100) color: Color lightGray.
		
		color := colors at: ((key hash abs \\ colors size) + 1).
		
		displayHistory ifNotEmpty: [
			| prevX prevY |
			maxV := 1.
			displayHistory do: [ :h | maxV := maxV max: (h at: key ifAbsent: [ 0 ]) ].
			
			canvas line: 40 @ 15 to: 40 @ (15 + gHeight) rounded width: 1 color: Color black.
			canvas line: 40 @ (15 + gHeight) to: (40 + gWidth) @ (15 + gHeight) rounded width: 1 color: Color black.
			
			canvas drawString: maxV rounded asString at: 2 @ 10 font: (LogicalFont familyName: 'Arial' pointSize: 8) color: Color gray.
			canvas drawString: '0' at: 2 @ (15 + gHeight - 5) font: (LogicalFont familyName: 'Arial' pointSize: 8) color: Color gray.

			prevX := nil.
			prevY := nil.
			
			1 to: displayHistory size do: [ :hIndex |
				| h v yp tx |
				h := displayHistory at: hIndex.
				v := h at: key ifAbsent: [ 0 ].
				yp := (15 + gHeight - ((v / maxV) * gHeight)) rounded.
				tx := (actualWindow > 1) 
					ifTrue: [ (40 + ((hIndex - 1) / (actualWindow - 1) * gWidth)) rounded ]
					ifFalse: [ 40 + (gWidth / 2) rounded ].
				
				prevX ifNotNil: [ canvas line: prevX @ prevY to: tx @ yp width: 1 color: color ].
				canvas fillRectangle: (tx - 1 @ (yp - 1) extent: 2 @ 2) color: color.
				prevX := tx. prevY := yp.
			].
			
			"Time Markers"
			displayHistory size >= 2 ifTrue: [
				| ts xPos timeIndices |
				timeIndices := (displayHistory size >= 3) ifTrue: [ {1. (displayHistory size // 2). displayHistory size} ] ifFalse: [ {1. displayHistory size} ].
				timeIndices do: [ :ti |
					| h |
					h := displayHistory at: ti.
					ts := (h at: #time ifAbsent: [ Time now ]) asString copyFrom: 12 to: 19.
					xPos := (40 + ((ti - 1) / (actualWindow - 1) * gWidth)) rounded.
					canvas drawString: ts at: (xPos - 30) @ (15 + gHeight + 2) font: (LogicalFont familyName: 'Arial' pointSize: 8) color: Color gray.
				].
			].
		].
		presenter image: form.
	].
]
