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
	| mainLayout gridLayout |
	
	gridLayout := SpGridLayout new
		columnSpacing: 10;
		rowSpacing: 10;
		beColumnNotHomogeneous;
		yourself.
		
	"Col 1: Cache (Row 1-5)"
	#( 'Hit Count' 'Miss Count' 'Hit Ratio' 'Proxy Count' 'Cache Size' ) 
		keysAndValuesDo: [ :idx :key | gridLayout add: (graphPresenters at: key) atPoint: 1 @ idx ].
		
	"Col 2: Session (Row 1-4)"
	#( 'RPC Count' 'Commit Count' 'Abort Count' 'Session ID' )
		keysAndValuesDo: [ :idx :key | gridLayout add: (graphPresenters at: key) atPoint: 2 @ idx ].
		
	"Col 3: GC (Row 1-4)"
	#( 'GC Count' 'GC Time (ms)' 'Objects Scavenged' 'Objects Tenured' )
		keysAndValuesDo: [ :idx :key | gridLayout add: (graphPresenters at: key) atPoint: 3 @ idx ].
		
	"Col 4: Memory (Row 1-4)"
	#( 'Object Count' 'Byte Count' 'OOP Count' '% Full' )
		keysAndValuesDo: [ :idx :key | gridLayout add: (graphPresenters at: key) atPoint: 4 @ idx ].

	mainLayout := SpBoxLayout newVertical
		spacing: 5;
		add: (self buildToolbar) height: 35;
		add: summaryLabel height: 30;
		add: gridLayout expand: true;
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
]

{ #category : 'initialization' }
GbxToolStatMonitor >> initializePresenters [
	| allKeys |
	summaryLabel := self newLabel label: 'Monitoring: Not started'.
	refreshButton := self newButton label: '⟳ Refresh Now'; action: [ self refreshStats ].
	autoRefreshCheckbox := self newCheckBox label: 'Auto-refresh (5s)'; state: false;
		whenChangedDo: [ :state | state ifTrue: [ self startMonitoring ] ifFalse: [ self stopMonitoring ] ].
		
	monitor := GbxToolStatResource named: 'Monitor' type: #monitor.
	#( 'hitCount' 'missCount' 'hitRatio' 'sessionId' 'rpcCount' 'commitCount' 'abortCount' 
	   'gcCount' 'gcTime' 'objectsScavenged' 'objectsTenured' 'objectCount' 'byteCount' 'oopCount' 'percentFull')
		do: [ :k | monitor addStatNamed: k description: k category: 'System' ].
	
	history := OrderedCollection new.
	graphPresenters := Dictionary new.
	
	allKeys := #(
		'Hit Count' 'Miss Count' 'Hit Ratio' 'Proxy Count' 'Cache Size'
		'RPC Count' 'Commit Count' 'Abort Count' 'Session ID'
		'GC Count' 'GC Time (ms)' 'Objects Scavenged' 'Objects Tenured'
		'Object Count' 'Byte Count' 'OOP Count' '% Full'
	).
	
	allKeys do: [ :key |
		| img |
		img := self newImage.
		img image: (Form extent: 220 @ 120 depth: 32).
		graphPresenters at: key put: img.
	].
	
	self drawGraph.
]

{ #category : 'initialization' }
GbxToolStatMonitor >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GBS Statistics Monitor - 4x5 Performance Matrix';
		initialExtent: 1100 @ 800;
		whenClosedDo: [ self stopMonitoring ].
]

{ #category : 'monitoring' }
GbxToolStatMonitor >> refreshStats [
	| current |
	session ifNil: [ ^ self ].
	[
		self fetchAllStats.
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
		self drawGraph.
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

{ #category : 'graph' }
GbxToolStatMonitor >> drawGraph [
	| colors windowSize displayHistory |
	
	colors := {Color red. Color blue. Color purple. Color green. Color orange. Color brown. Color cyan. Color magenta. Color gray. Color black}.
	windowSize := 20.
	displayHistory := (history size > windowSize) 
		ifTrue: [ history copyFrom: history size - windowSize + 1 to: history size ]
		ifFalse: [ history ].

	graphPresenters keysAndValuesDo: [ :statName :presenter |
		| form canvas maxV color gWidth gHeight |
		form := Form extent: 250 @ 130 depth: 32.
		canvas := form getCanvas.
		canvas fillRectangle: (0 @ 0 extent: 250 @ 130) color: Color white.
		canvas frameRectangle: (0 @ 0 extent: 250 @ 130) color: Color lightGray.
		
		color := colors at: ((statName hash abs \\ colors size) + 1).
		canvas drawString: statName at: 5 @ 2 font: (LogicalFont familyName: 'Arial' pointSize: 9) color: color.
		
		gWidth := 180.
		gHeight := 80.
		
		displayHistory ifNotEmpty: [
			| prevX prevY |
			maxV := 1.
			displayHistory do: [ :h | maxV := maxV max: (h at: statName ifAbsent: [ 0 ]) ].
			
			canvas line: 40 @ 20 to: 40 @ (20 + gHeight) width: 1 color: Color black.
			canvas line: 40 @ (20 + gHeight) to: (40 + gWidth) @ (20 + gHeight) width: 1 color: Color black.
			
			canvas drawString: maxV rounded asString at: 2 @ 15 font: (LogicalFont familyName: 'Arial' pointSize: 8) color: Color gray.
			canvas drawString: '0' at: 2 @ (20 + gHeight - 5) font: (LogicalFont familyName: 'Arial' pointSize: 8) color: Color gray.

			prevX := nil.
			prevY := nil.
			
			1 to: displayHistory size do: [ :hi |
				| h v yp tx |
				h := displayHistory at: hi.
				v := h at: statName ifAbsent: [ 0 ].
				yp := (20 + gHeight - ((v / maxV) * gHeight)) rounded.
				tx := (windowSize > 1) 
					ifTrue: [ (40 + ((hi - 1) / (windowSize - 1) * gWidth)) rounded ]
					ifFalse: [ 40 + (graphWidth / 2) rounded ].
				
				prevX ifNotNil: [ canvas line: prevX @ prevY to: tx @ yp width: 1 color: color ].
				canvas fillRectangle: (tx - 1 @ (yp - 1) extent: 2 @ 2) color: color.
				prevX := tx. prevY := yp.
			].
			
			"Time Markers - safe check"
			displayHistory size >= 2 ifTrue: [
				| ts xPos |
				ts := (displayHistory last at: #time ifAbsent: [ Time now ]) asString copyFrom: 12 to: 19.
				xPos := (40 + ((displayHistory size - 1) / (windowSize - 1) * gWidth)) rounded.
				canvas drawString: ts at: (xPos - 40) @ (20 + gHeight + 2) font: (LogicalFont familyName: 'Arial' pointSize: 8) color: Color gray.
			].
		].
		presenter image: form.
	].
]
