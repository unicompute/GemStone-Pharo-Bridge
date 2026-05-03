Extension { #name : 'GbxDebuggerService' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> correctCurrentSelectorWithSource: sourceText [
	| remoteMethod raw |
	currentContext ifNil: [ ^ false ].
	self isSessionUsable ifFalse: [ ^ false ].
	self clearCompileError.
	remoteMethod := self selectedRemoteUnboundMethodObject.
	raw := (remoteMethod isNil or: [ remoteMethod selector = #unboundMethod ])
		ifTrue: [ self legacyCorrectedCompileResponseForSource: sourceText ]
		ifFalse: [ remoteMethod correctedCompileResponseForSource: sourceText ].
	raw ifNil: [
		lastCompileError := 'Correct selector failed: no response from GemStone'.
		^ false
	].
	(raw = 'OK') ifTrue: [ ^ true ].
	lastCompileError := (self normalizedCompileErrorFrom: raw).
	^ false
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> recompileCurrentMethodWithSource: sourceText [
	| remoteMethod raw |
	currentContext ifNil: [ ^ false ].
	self isSessionUsable ifFalse: [ ^ false ].
	self clearCompileError.
	remoteMethod := self selectedRemoteUnboundMethodObject.
	raw := (remoteMethod isNil or: [ remoteMethod selector = #unboundMethod ])
		ifTrue: [ self legacyRecompileResponseForSource: sourceText ]
		ifFalse: [ remoteMethod recompileResponseForSource: sourceText ].
	raw ifNil: [
		lastCompileError := 'Compile failed: no response from GemStone'.
		^ false
	].
	(raw = 'OK') ifTrue: [ ^ true ].
	lastCompileError := (self normalizedCompileErrorFrom: raw).
	^ false
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> selectedMethodClassName [
	| remoteMethod |
	remoteMethod := self selectedRemoteUnboundMethodObject.
	remoteMethod ifNotNil: [ ^ remoteMethod ownerName ].
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #methodClassOrUnknown) ifTrue: [ ^ currentContext methodClassOrUnknown ].
	(currentContext respondsTo: #methodClass) ifTrue: [ ^ currentContext methodClass ].
	^ nil
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> selectedMethodSelector [
	| remoteMethod |
	remoteMethod := self selectedRemoteUnboundMethodObject.
	remoteMethod ifNotNil: [ ^ remoteMethod selector ].
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #selectorOrUnknown) ifTrue: [ ^ currentContext selectorOrUnknown ].
	(currentContext respondsTo: #selector) ifTrue: [ ^ currentContext selector ].
	^ nil
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> selectedMethodProtocol [
	| remoteMethod |
	remoteMethod := self selectedRemoteUnboundMethodObject.
	remoteMethod ifNotNil: [ ^ remoteMethod protocol ].
	^ nil
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> selectedRemoteMethodLookup [
	| className isMeta lookupName selector |
	currentContext ifNil: [ ^ nil ].
	className := (currentContext respondsTo: #methodClassOrUnknown)
		ifTrue: [ currentContext methodClassOrUnknown ]
		ifFalse: [
			(currentContext respondsTo: #methodClass)
				ifTrue: [ currentContext methodClass ]
				ifFalse: [ nil ] ].
	selector := (currentContext respondsTo: #selectorOrUnknown)
		ifTrue: [ currentContext selectorOrUnknown ]
		ifFalse: [
			(currentContext respondsTo: #selector)
				ifTrue: [ currentContext selector ]
				ifFalse: [ nil ] ].
	(className isNil or: [ selector isNil or: [ selector = #unboundMethod ] ]) ifTrue: [ ^ nil ].
	isMeta := className asString endsWith: ' class'.
	lookupName := isMeta
		ifTrue: [ className asString allButLast: 6 ]
		ifFalse: [ className asString ].
	^ { lookupName. selector asSymbol. isMeta }
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> selectedRemoteMethodMirror [
	| lookup |
	self isSessionUsable ifFalse: [ ^ nil ].
	lookup := self selectedRemoteMethodLookup.
	lookup ifNil: [ ^ nil ].
	^ [
		(lookup third
			ifTrue: [
				session
					classMethodMirrorForClassNamed: lookup first
					selector: lookup second ]
			ifFalse: [
				session
					methodMirrorForClassNamed: lookup first
					selector: lookup second ]) ]
		on: Error
		do: [ :ex | nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> selectedRemoteUnboundMethodObject [
	| mirror |
	mirror := self selectedRemoteMethodMirror.
	(mirror isNil or: [ mirror exists not ]) ifTrue: [ ^ nil ].
	^ mirror asUnboundMethodObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> selectedRemoteMethodObject [
	| methodObject receiverOop receiverProxy |
	methodObject := self selectedRemoteUnboundMethodObject.
	methodObject ifNil: [ ^ nil ].
	methodObject classSide ifTrue: [ ^ methodObject bindTo: methodObject classMirror proxy ].
	receiverOop := self currentReceiverOop.
	((receiverOop isNumber) and: [ receiverOop > 20 ]) ifFalse: [ ^ methodObject ].
	receiverProxy := [ session objectForOop: receiverOop ]
		on: Error
		do: [ :ex | nil ].
	receiverProxy ifNil: [ ^ methodObject ].
	^ [ methodObject bindTo: receiverProxy ]
		on: Error
		do: [ :ex | methodObject ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> sourceCode [
	"Get the source code for the current context"
	| remoteMethod |
	remoteMethod := self selectedRemoteUnboundMethodObject.
	(remoteMethod notNil and: [ remoteMethod sourceCode notNil ]) ifTrue: [
		^ remoteMethod sourceCode ].
	currentContext ifNil: [ ^ '' ].
	^ currentContext sourceCode
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> sourceMatchesCurrentMethodIn: aTextWidget [
	| widgetText sourceText |
	aTextWidget ifNil: [ ^ true ].
	(aTextWidget respondsTo: #text) ifFalse: [ ^ true ].
	currentContext ifNil: [ ^ true ].
	sourceText := self sourceCode.
	sourceText ifNil: [
		sourceText := (currentContext respondsTo: #sourceCode)
			ifTrue: [ currentContext sourceCode ]
			ifFalse: [ (currentContext respondsTo: #sourceString) ifTrue: [ currentContext sourceString ] ifFalse: [ nil ] ] ].
	sourceText ifNil: [ ^ true ].
	widgetText := [ aTextWidget text asString ] on: Error do: [ nil ].
	widgetText ifNil: [ ^ true ].
	^ widgetText = sourceText asString
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> browseRemoteSelectedMethod [
	| methodObject newBrowser classHolder |
	methodObject := self selectedRemoteUnboundMethodObject.
	methodObject ifNil: [ ^ nil ].
	newBrowser := Smalltalk at: #GbxHierarchyBrowser ifAbsent: [ ^ nil ].
	classHolder := (Smalltalk at: #GbxClassHolder ifAbsent: [ ^ nil ])
		name: methodObject classMirror name
		proxy: methodObject classMirror proxy.
	newBrowser := newBrowser new.
	newBrowser session: session.
	newBrowser myClass: classHolder.
	newBrowser classList: nil
		class: classHolder
		protocolList: nil
		protocol: (methodObject protocol ifNil: [ 'as yet unclassified' ])
		methodList: nil
		selectedMethods: (Array with:
			((Smalltalk at: #GbxCompiledMethodHolder ifAbsent: [ ^ nil ])
				name: methodObject selector)).
	methodObject isClassSide ifTrue: [
		newBrowser initalizeMetaTabsToIndex: 2 ].
	^ newBrowser
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> browseMethod [
	"Browse current method - prefers a remote method browser when available."
	currentContext gbxIsServerContext ifTrue: [
		^ self browseRemoteSelectedMethod
			ifNil: [ self gbxBrowseMethod: self selectedMethod ]
	].
	^ nil
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxDebuggerService >> gbxRecompileMethod: sourceText notifying: requestor [
	"Recompile the method in the receiver's current stack frame using sourceText.
	Answer true if compilation is successful, otherwise false.
	Displays compiler errors in the requestor (text editor)."
	| remoteMethod gbxMethod method sess result myErrorText error preErrorText postErrorText |
	remoteMethod := self selectedRemoteUnboundMethodObject.
	remoteMethod ifNotNil: [
		(self recompileCurrentMethodWithSource: sourceText) ifTrue: [
			self gbxMethodChanged: sourceText.
			^ true ].
		requestor ifNotNil: [
			(requestor respondsTo: #insertAndSelect:at:) ifTrue: [
				requestor insertAndSelect: (lastCompileError ifNil: [ 'error' ]) , '->' at: 1 ] ].
		^ false ].

	gbxMethod := self selectedMethod.
	gbxMethod ifNil: [ ^ false ].
	method := gbxMethod methodDelegate.
	method ifNil: [ ^ false ].
	sess := method session.
	sess ifNil: [ ^ false ].

	(gbxMethod methodClass = sess oopNil) ifTrue: [
		^ false ].

	result := [
		sess unsynchronizedEvaluateBlock: '[:meth :source | meth _recompileWithSource: source]'
			with: method
			with: (sourceText gbxConvertToServerLineDelimiter ifNil: [ sourceText ])
	] on: Error do: [ :ex | ex messageText ].

	result ~~ true & (result ~~ false) ifTrue: [
		error := result isEmpty ifTrue: [ nil ] ifFalse: [ result at: 1 ].
		myErrorText := error size < 3 ifTrue: [ 'error' ] ifFalse: [ error at: 3 ].
		requestor ifNotNil: [
			(requestor respondsTo: #insertAndSelect:at:) ifTrue: [
				requestor insertAndSelect: myErrorText , '->' at: (error at: 2) ] ].
		^ false ].

	result ifTrue: [
		self gbxMethodChanged: sourceText.
		^ true
	] ifFalse: [
		self scheduleTextUpdate.
		self processEvents.
		^ true
	]
]
