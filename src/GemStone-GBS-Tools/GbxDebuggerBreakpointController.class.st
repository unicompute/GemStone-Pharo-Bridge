Class {
	#name : 'GbxDebuggerBreakpointController',
	#superclass : 'Object',
	#instVars : [
		'service'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDebuggerBreakpointController class >> on: aService [
	^ self new
		service: aService;
		yourself
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> breakpoint: aBreakPoint matchesSelection: anInterval [
	| offset |
	offset := self sourceOffsetForBreakPoint: aBreakPoint.
	offset ifNil: [ ^ false ].
	^ anInterval first <= offset and: [ anInterval last >= offset ]
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> breakpointClass [
	^ service breakpointClass
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> breakpointIntervalsInCurrentMethod [
	| intervals |
	intervals := OrderedCollection new.
	self breakpointsInSelectedMethod do: [ :bp |
		| offset |
		offset := self sourceOffsetForBreakPoint: bp.
		offset ifNotNil: [ intervals add: (offset to: offset) ] ].
	^ intervals asArray
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> breakpointSummaryString [
	| points stream |
	points := (self breakpointsInSelectedMethod
		collect: [ :bp | (bp respondsTo: #stepPoint) ifTrue: [ bp stepPoint ] ifFalse: [ nil ] ])
		select: #notNil.
	points isEmpty ifTrue: [ ^ 'No breakpoints in method' ].
	stream := WriteStream on: String new.
	points
		doWithIndex: [ :sp :idx |
			idx > 1 ifTrue: [ stream nextPutAll: ', ' ].
			stream nextPutAll: sp asString ].
	^ 'Breakpoints step points: ', stream contents
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> breakpointToRemoveIn: aTextWidget from: breakpoints [
	| selection stepPointMatch |
	selection := self selectionIntervalForTextWidget: aTextWidget.
	selection ifNil: [
		stepPointMatch := service currentStepPoint.
		stepPointMatch ifNotNil: [
			^ breakpoints
				detect: [ :bp | (bp respondsTo: #stepPoint) and: [ bp stepPoint = stepPointMatch ] ]
				ifNone: [ breakpoints first ] ].
		^ breakpoints first ].
	^ breakpoints
		detect: [ :bp | self breakpoint: bp matchesSelection: selection ]
		ifNone: [ nil ]
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> breakpointsInSelectedMethod [
	| selector className |
	self canManageBreakPoints ifFalse: [ ^ #( ) ].
	selector := self selectedMethodSelector.
	className := self selectedMethodClassName.
	(selector isNil or: [ className isNil ]) ifTrue: [ ^ #( ) ].
	^ self currentBreakPointList select: [ :bp |
		bp selector = selector and: [ bp remoteClass = className ] ]
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> browserClass [
	^ service browserClass
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> canManageBreakPoints [
	| selector currentContext |
	currentContext := service currentContext.
	currentContext ifNil: [ ^ false ].
	(currentContext respondsTo: #gbxIsServerContext)
		ifTrue: [ currentContext gbxIsServerContext ifFalse: [ ^ false ] ].
	selector := self selectedMethodSelector.
	selector isNil ifTrue: [ ^ false ].
	(selector = #unboundMethod) ifTrue: [
		^ (currentContext respondsTo: #isExecutedCodeFrame)
			and: [ currentContext isExecutedCodeFrame ] ].
	^ self selectedMethodClassName isNotNil
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> canRemoveAllBreakPoints [
	^ self breakpointsInSelectedMethod isNotEmpty
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> canRemoveBreakPoint [
	^ self hasBreakPointIn: nil
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> canSetBreakPoint [
	^ self canManageBreakPoints and: [ (self hasBreakPointIn: nil) not ]
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> canToggleBreakPoint [
	^ self canManageBreakPoints
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> currentBreakPointList [
	| klass |
	klass := self breakpointClass.
	klass ifNil: [ ^ #( ) ].
	^ klass breakPointListFor: service session
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> hasBreakPointIn: aTextWidget [
	| bps selection stepPoint |
	bps := self breakpointsInSelectedMethod.
	bps isEmpty ifTrue: [ ^ false ].
	selection := self selectionIntervalForTextWidget: aTextWidget.
	selection ifNotNil: [
		^ bps anySatisfy: [ :bp | self breakpoint: bp matchesSelection: selection ] ].
	stepPoint := service currentStepPoint.
	stepPoint ifNil: [ ^ false ].
	^ bps anySatisfy: [ :bp | (bp respondsTo: #stepPoint) and: [ bp stepPoint = stepPoint ] ]
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> highlightBreakPointsIn: aText [
	| bps methodSelector currentContext |
	currentContext := service currentContext.
	currentContext ifNil: [ ^ aText ].
	currentContext gbxIsServerContext ifFalse: [ ^ aText ].
	currentContext isValid ifFalse: [ ^ aText ].
	service isTerminated ifTrue: [ ^ aText ].
	methodSelector := self selectedMethodSelector.
	methodSelector ifNil: [ ^ aText ].
	bps := self currentBreakPointList select: [ :each |
		each selector = methodSelector and: [ each remoteClass = self selectedMethodClassName ] ].
	bps do: [ :bp |
		| offset |
		offset := currentContext sourceOffsets at: bp stepPoint ifAbsent: [ nil ].
		offset ifNotNil: [
			(aText respondsTo: #emphasizeFrom:to:with:) ifTrue: [
				aText emphasizeFrom: offset to: offset with: #( #underline #color -> #purple ) ] ] ].
	^ aText
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> removeAllBreakPoints [
	| bps |
	bps := self breakpointsInSelectedMethod.
	bps do: [ :bp | bp clear ].
	^ bps size
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> removeBreakIn: aTextWidget [
	| bps target |
	bps := self breakpointsInSelectedMethod.
	bps isEmpty ifTrue: [ ^ false ].
	target := self breakpointToRemoveIn: aTextWidget from: bps.
	target ifNil: [ ^ false ].
	target clear.
	^ true
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> removeBreakPoint [
	^ self removeBreakIn: nil
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> selectedMethodClassName [
	| currentContext |
	currentContext := service currentContext.
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #methodClassOrUnknown) ifTrue: [ ^ currentContext methodClassOrUnknown ].
	(currentContext respondsTo: #methodClass) ifTrue: [ ^ currentContext methodClass ].
	^ nil
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> selectedMethodSelector [
	| currentContext |
	currentContext := service currentContext.
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #selectorOrUnknown) ifTrue: [ ^ currentContext selectorOrUnknown ].
	(currentContext respondsTo: #selector) ifTrue: [ ^ currentContext selector ].
	^ nil
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> selectionIntervalForTextWidget: aTextWidget [
	| controller start stop |
	aTextWidget ifNil: [ ^ nil ].
	(aTextWidget respondsTo: #selectionInterval) ifTrue: [ ^ aTextWidget selectionInterval ].
	(aTextWidget respondsTo: #controller) ifFalse: [ ^ nil ].
	controller := aTextWidget controller.
	((controller respondsTo: #selectionStartIndex) and: [ controller respondsTo: #selectionStopIndex ])
		ifFalse: [ ^ nil ].
	start := controller selectionStartIndex.
	stop := controller selectionStopIndex.
	(start isNil or: [ stop isNil ]) ifTrue: [ ^ nil ].
	^ start to: stop
]

{ #category : 'accessing' }
GbxDebuggerBreakpointController >> service [
	^ service
]

{ #category : 'accessing' }
GbxDebuggerBreakpointController >> service: aService [
	service := aService
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> setBreakPoint [
	^ self setBreakPointIn: nil
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> setBreakPointIn: aTextWidget [
	| browserKlass |
	self canManageBreakPoints ifFalse: [ ^ false ].
	(self sourceMatchesCurrentMethodIn: aTextWidget) ifFalse: [ ^ false ].
	(self hasBreakPointIn: aTextWidget) ifTrue: [ ^ false ].
	browserKlass := self browserClass.
	browserKlass ifNil: [ ^ false ].
	browserKlass
		setBreakInView: aTextWidget
		model: service currentContext
		method: self selectedMethodSelector
		class: self selectedMethodClassName.
	^ true
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> sourceMatchesCurrentMethodIn: aTextWidget [
	| widgetText sourceText currentContext |
	aTextWidget ifNil: [ ^ true ].
	(aTextWidget respondsTo: #text) ifFalse: [ ^ true ].
	currentContext := service currentContext.
	currentContext ifNil: [ ^ true ].
	sourceText := (currentContext respondsTo: #sourceCode)
		ifTrue: [ currentContext sourceCode ]
		ifFalse: [ (currentContext respondsTo: #sourceString) ifTrue: [ currentContext sourceString ] ifFalse: [ nil ] ].
	sourceText ifNil: [ ^ true ].
	widgetText := [ aTextWidget text asString ] on: Error do: [ nil ].
	widgetText ifNil: [ ^ true ].
	^ widgetText = sourceText asString
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> sourceOffsetForBreakPoint: aBreakPoint [
	| stepPoint offsets rawOffset currentContext |
	currentContext := service currentContext.
	currentContext ifNil: [ ^ nil ].
	(aBreakPoint respondsTo: #stepPoint) ifFalse: [ ^ nil ].
	stepPoint := aBreakPoint stepPoint.
	stepPoint ifNil: [ ^ nil ].
	(currentContext respondsTo: #sourceOffsets) ifFalse: [ ^ nil ].
	offsets := currentContext sourceOffsets.
	rawOffset := [ offsets at: stepPoint ] on: Error do: [ nil ].
	rawOffset ifNil: [ ^ nil ].
	^ [ rawOffset asInteger ] on: Error do: [ nil ]
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> toggleBreakPoint [
	^ self toggleBreakPointIn: nil
]

{ #category : 'breakpoint support' }
GbxDebuggerBreakpointController >> toggleBreakPointIn: aTextWidget [
	(self hasBreakPointIn: aTextWidget)
		ifTrue: [ ^ self removeBreakIn: aTextWidget ]
		ifFalse: [ ^ self setBreakPointIn: aTextWidget ]
]
