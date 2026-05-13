Class {
	#name : 'GbsRemoteDebuggerSourcePaneController',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerSourcePaneController class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'actions' }
GbsRemoteDebuggerSourcePaneController >> acceptSourceEdits [
	| code ok |
	self service ifNil: [ ^ false ].
	code := (self sourceText respondsTo: #text)
		ifTrue: [ self sourceText text asString ]
		ifFalse: [ '' ].
	ok := [ self service recompileCurrentMethodWithSource: code ] on: Error do: [ false ].
	ok ifTrue: [
		(self contextList notNil and: [ self contextList isEmpty not ]) ifTrue: [
			| idx |
			idx := (self stackList respondsTo: #selectedIndex)
				ifTrue: [ self stackList selectedIndex ifNil: [ 1 ] ]
				ifFalse: [ 1 ].
			(idx > 0 and: [ idx <= self contextList size ]) ifTrue: [
				| ctx |
				ctx := self contextList at: idx.
				(ctx respondsTo: #sourceString:) ifTrue: [ ctx sourceString: code ].
				(ctx respondsTo: #sourceCode:) ifTrue: [ ctx sourceCode: code ] ] ].
		debugger fetchStackFrames.
		debugger clearServiceCompileError.
		debugger syncBreakpointMarker.
		debugger refreshUiState ]
	ifFalse: [
		self showCompileErrorInSourcePane ].
	^ ok
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> applyBreakpointEmphasisFor: aContext [
	| intervals raw textAttr start stop textColorClass |
	aContext ifNil: [ ^ self ].
	self sourceText ifNil: [ ^ self ].
	(self sourceText respondsTo: #text:) ifFalse: [ ^ self ].
	raw := [ self sourceText text asString ] on: Error do: [ '' ].
	raw isEmpty ifTrue: [ ^ self ].
	intervals := debugger safeServiceCall: [ self service breakpointIntervalsInCurrentMethod ] default: #().
	(intervals isCollection and: [ intervals isEmpty not ]) ifFalse: [ ^ self ].
	textAttr := raw asText.
	textColorClass := Smalltalk at: #TextColor ifAbsent: [ nil ].
	intervals do: [ :interval |
		(interval respondsTo: #first) ifTrue: [
			start := interval first.
			stop := interval last ifNil: [ start ].
			(start isNumber and: [ stop isNumber and: [ start > 0 and: [ start <= raw size ] ] ]) ifTrue: [
				stop := stop min: raw size.
				[ textAttr addAttribute: TextEmphasis underlined from: start to: stop ] on: Error do: [ ].
				textColorClass ifNotNil: [
					[ textAttr addAttribute: (textColorClass color: Color magenta) from: start to: stop ]
						on: Error do: [ ] ] ] ] ].
	[ self sourceText text: textAttr ] on: Error do: [ ].
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> applySourceMapHighlightFor: aContext [
	| map interval lineNumber stepPoint sourceOffsets stepEntry stepCandidates |
	self sourceText ifNil: [ ^ self ].

	map := self sourceMapFor: aContext.
	(map isCollection and: [ map isEmpty not ]) ifTrue: [
		stepPoint := (aContext respondsTo: #stepPoint)
			ifTrue: [ [ aContext stepPoint ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		stepPoint ifNil: [
			stepPoint := (aContext respondsTo: #quickStepPoint)
				ifTrue: [ [ aContext quickStepPoint ] on: Error do: [ nil ] ]
				ifFalse: [ nil ] ].
		stepPoint := [ stepPoint asInteger ] on: Error do: [ nil ].
		(stepPoint isNumber and: [ stepPoint > 0 ]) ifTrue: [
			stepEntry := map
				detect: [ :assoc |
					| key |
					(assoc respondsTo: #key) ifFalse: [ false ] ifTrue: [
						key := debugger integerFromSourceMapKey: assoc key.
						key = stepPoint ] ]
				ifNone: [ nil ].
			stepEntry ifNil: [
				stepCandidates := map
					select: [ :assoc |
						| key |
						(assoc respondsTo: #key) ifFalse: [ false ] ifTrue: [
							key := debugger integerFromSourceMapKey: assoc key.
							key isNumber and: [ key <= stepPoint ] ] ].
				stepCandidates ifNotEmpty: [
					stepEntry := stepCandidates first.
					stepCandidates allButFirstDo: [ :each |
						| eachKey currentKey |
						eachKey := debugger integerFromSourceMapKey: each key.
						currentKey := debugger integerFromSourceMapKey: stepEntry key.
						(eachKey isNumber and: [ currentKey isNumber and: [ eachKey > currentKey ] ])
							ifTrue: [ stepEntry := each ] ] ] ].
			stepEntry ifNotNil: [ interval := stepEntry value ] ].

		interval ifNil: [
			interval := (self service notNil and: [ self service respondsTo: #currentSourceSelectionInterval ])
				ifTrue: [ [ self service currentSourceSelectionInterval ] on: Error do: [ nil ] ]
				ifFalse: [ nil ] ].
		interval ifNil: [ interval := map first value ].
		(interval isNil or: [ (interval respondsTo: #first) not or: [ (interval respondsTo: #last) not ] ]) ifTrue: [
			^ self clearSourceHighlight ].
		self selectAndRevealFrom: interval first to: interval last inTextPresenter: self sourceText.
		self placeCaretAt: interval first inTextPresenter: self sourceText.
		^ self ].

	lineNumber := (aContext respondsTo: #displayedLineNumber)
		ifTrue: [ [ aContext displayedLineNumber ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	(lineNumber isNumber and: [ lineNumber > 0 ])
		ifTrue: [ ^ self selectLineNumber: lineNumber inTextPresenter: self sourceText ].

	(aContext respondsTo: #isExecutedCodeFrame) ifTrue: [
		aContext isExecutedCodeFrame ifTrue: [
			stepPoint := aContext quickStepPoint ifNil: [ 1 ].
			sourceOffsets := aContext sourceOffsets ifNil: [ #( 1 ) ].
			(sourceOffsets isCollection and: [ sourceOffsets isEmpty not and: [ stepPoint <= sourceOffsets size ] ]) ifTrue: [
				interval := sourceOffsets at: stepPoint ifAbsent: [ 1 ].
				interval ifNil: [ interval := 1 ].
				interval > 0 ifTrue: [
					self selectAndRevealFrom: interval to: interval inTextPresenter: self sourceText.
					self placeCaretAt: interval inTextPresenter: self sourceText.
					^ self ] ].
			^ self selectLineNumber: 1 inTextPresenter: self sourceText ] ].

	self clearSourceHighlight.
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> clearSourceHighlight [
	| textSize |
	self sourceText ifNil: [ ^ self ].
	[
		(self sourceText respondsTo: #text)
			ifTrue: [ textSize := self sourceText text asString size ]
			ifFalse: [ textSize := 0 ].
		self
			selectAndRevealFrom: textSize + 1
			to: textSize
			inTextPresenter: self sourceText
	] on: Error do: [ ].
]

{ #category : 'accessing' }
GbsRemoteDebuggerSourcePaneController >> contextList [
	^ debugger contextList
]

{ #category : 'accessing' }
GbsRemoteDebuggerSourcePaneController >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerSourcePaneController >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> formatSource [
	| text |
	self sourceText ifNil: [ ^ false ].
	(self sourceText respondsTo: #text) ifFalse: [ ^ false ].
	text := self sourceText text asString.
	(self sourceText respondsTo: #text:)
		ifTrue: [ self sourceText text: text withBlanksTrimmed ].
	^ true
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> highlightSourceLineFromCompileError: errorMessage [
	| lower lineToken idx start lineNumber |
	(errorMessage isString and: [ errorMessage isEmpty not ]) ifFalse: [ ^ self ].
	(self sourceText respondsTo: #text) ifFalse: [ ^ self ].
	lower := errorMessage asLowercase.
	lineToken := 'line '.
	idx := lower findString: lineToken startingAt: 1.
	idx = 0 ifTrue: [ ^ self ].
	start := idx + lineToken size.
	lineNumber := [ (lower copyFrom: start to: lower size) asNumber ] on: Error do: [ nil ].
	lineNumber ifNil: [ ^ self ].
	self selectLineNumber: lineNumber inTextPresenter: self sourceText.
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> moveSourceCursorToStart [
	| text |
	self sourceText ifNil: [ ^ self ].
	text := [ (self sourceText respondsTo: #text)
		ifTrue: [ self sourceText text asString ]
		ifFalse: [ '' ] ] on: Error do: [ '' ].
	text isEmpty ifTrue: [ ^ self ].
	self selectAndRevealFrom: 1 to: 1 inTextPresenter: self sourceText.
	self reinforceSourceCaretVisibility.
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> placeCaretAt: anIndex inTextPresenter: aTextPresenter [
	| caret |
	aTextPresenter ifNil: [ ^ self ].
	caret := anIndex ifNil: [ 1 ].
	[
		aTextPresenter withAdapterDo: [ :adapter |
			| widget textArea editor |
			widget := [ adapter widget ] on: Error do: [ nil ].
			widget ifNil: [ ^ self ].
			(widget respondsTo: #takeKeyboardFocus)
				ifTrue: [ [ widget takeKeyboardFocus ] on: Error do: [ ] ].
			textArea := (widget respondsTo: #textArea)
				ifTrue: [ [ widget textArea ] on: Error do: [ nil ] ]
				ifFalse: [ nil ].
			textArea ifNotNil: [
				(textArea respondsTo: #takeKeyboardFocus)
					ifTrue: [ [ textArea takeKeyboardFocus ] on: Error do: [ ] ].
				editor := (textArea respondsTo: #editor)
					ifTrue: [ [ textArea editor ] on: Error do: [ nil ] ]
					ifFalse: [ nil ].
				editor ifNotNil: [
					(editor respondsTo: #markIndex:) ifTrue: [ editor markIndex: caret ].
					(editor respondsTo: #pointIndex:) ifTrue: [ editor pointIndex: caret ].
					(editor respondsTo: #selectAt:) ifTrue: [ editor selectAt: caret ] ].
				(textArea respondsTo: #scrollSelectionIntoView)
					ifTrue: [ [ textArea scrollSelectionIntoView ] on: Error do: [ ] ] ] ] ] on: Error do: [ ].
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> reinforceSourceCaretVisibility [
	| caret worldStateClass |
	self sourceText ifNil: [ ^ self ].
	(self sourceText respondsTo: #selectionInterval) ifFalse: [ ^ self ].
	caret := [ self sourceText selectionInterval first ] on: Error do: [ 1 ].
	caret ifNil: [ caret := 1 ].

	self placeCaretAt: caret inTextPresenter: self sourceText.

	worldStateClass := Smalltalk at: #WorldState ifAbsent: [ nil ].
	worldStateClass ifNotNil: [
		(worldStateClass respondsTo: #addDeferredUIMessage:)
			ifTrue: [
				[ worldStateClass addDeferredUIMessage: [
					self placeCaretAt: caret inTextPresenter: self sourceText
				] ] on: Error do: [ ] ] ].
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> selectAndRevealFrom: startIndex to: endIndex inTextPresenter: aTextPresenter [
	| start stop textSize |
	aTextPresenter ifNil: [ ^ self ].
	start := startIndex ifNil: [ 1 ].
	stop := endIndex ifNil: [ start ].
	stop < start ifTrue: [ stop := start ].
	textSize := [ aTextPresenter text asString size ] on: Error do: [ 0 ].
	textSize > 0 ifTrue: [
		start := (start max: 1) min: textSize.
		stop := (stop max: start) min: textSize ].

	[
		(aTextPresenter respondsTo: #selectionInterval:)
			ifTrue: [ aTextPresenter selectionInterval: (start to: stop) ]
			ifFalse: [
				(aTextPresenter respondsTo: #selectFrom:to:)
					ifTrue: [ aTextPresenter selectFrom: start to: stop ] ].

		aTextPresenter withAdapterDo: [ :adapter |
			| widget |
			widget := [ adapter widget ] on: Error do: [ nil ].
			widget ifNotNil: [
				(widget respondsTo: #setSelection:) ifTrue: [ widget setSelection: (start to: stop) ].
				(widget respondsTo: #scrollSelectionIntoView) ifTrue: [ widget scrollSelectionIntoView ].
				(widget respondsTo: #textArea) ifTrue: [
					| textArea editor |
					textArea := widget textArea.
					textArea ifNotNil: [
						(textArea respondsTo: #selectFrom:to:) ifTrue: [ textArea selectFrom: start to: stop ].
						editor := (textArea respondsTo: #editor)
							ifTrue: [ [ textArea editor ] on: Error do: [ nil ] ]
							ifFalse: [ nil ].
						editor ifNotNil: [
							(editor respondsTo: #markIndex:) ifTrue: [ editor markIndex: start ].
							(editor respondsTo: #pointIndex:) ifTrue: [ editor pointIndex: stop ].
							(editor respondsTo: #selectFrom:to:) ifTrue: [ editor selectFrom: start to: stop ].
							(editor respondsTo: #selectAt:) ifTrue: [ editor selectAt: stop ] ].
						(textArea respondsTo: #scrollSelectionIntoView) ifTrue: [ textArea scrollSelectionIntoView ] ] ] ] ].
	] on: Error do: [ :ex | ].
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> selectLineNumber: lineNumber inTextPresenter: aTextPresenter [
	| text pos currentLine lineStart lineEnd |
	(lineNumber isNumber and: [ lineNumber > 0 ]) ifFalse: [ ^ self ].
	text := aTextPresenter text asString.
	text isEmpty ifTrue: [ ^ self ].
	pos := 1.
	currentLine := 1.
	[ currentLine < lineNumber and: [ pos <= text size ] ] whileTrue: [
		(text at: pos) = Character lf ifTrue: [ currentLine := currentLine + 1 ].
		pos := pos + 1 ].
	currentLine = lineNumber ifFalse: [ ^ self ].
	lineStart := pos min: text size.
	lineEnd := lineStart.
	[ lineEnd <= text size and: [ (text at: lineEnd) ~= Character lf ] ] whileTrue: [
		lineEnd := lineEnd + 1 ].
	lineEnd := lineEnd - 1.
	lineEnd < lineStart ifTrue: [ lineEnd := lineStart ].
	self selectAndRevealFrom: lineStart to: lineEnd inTextPresenter: aTextPresenter.
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> selectedSourceOrAll [
	| selected text |
	self sourceText ifNil: [ ^ '' ].
	selected := (self sourceText respondsTo: #selectedText)
		ifTrue: [ self sourceText selectedText ]
		ifFalse: [ nil ].
	(selected isString and: [ selected isEmpty not ]) ifTrue: [ ^ selected ].
	text := (self sourceText respondsTo: #text)
		ifTrue: [ self sourceText text ]
		ifFalse: [ '' ].
	^ text asString
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> selectedStepPointFromCaret [
	| caret map entries sorted match context |
	self sourceText ifNil: [ ^ nil ].
	(self sourceText respondsTo: #selectionInterval) ifFalse: [ ^ nil ].
	caret := self sourceText selectionInterval first.
	context := (self service notNil and: [ self service respondsTo: #currentContext ])
		ifTrue: [ self service currentContext ]
		ifFalse: [ nil ].
	map := self sourceMapFor: context.
	(map isCollection and: [ map isEmpty not ]) ifFalse: [ ^ nil ].
	entries := map collect: [ :assoc |
		| interval key |
		key := assoc key.
		interval := assoc value.
		(key isNumber and: [ interval respondsTo: #first ])
			ifTrue: [ assoc ]
			ifFalse: [ nil ] ] thenReject: #isNil.
	entries isEmpty ifTrue: [ ^ nil ].
	sorted := entries asSortedCollection: [ :a :b | a value first <= b value first ].
	match := sorted detect: [ :each |
		(each value first <= caret) and: [ (each value last ifNil: [ each value first ]) >= caret ] ]
		ifNone: [ sorted detect: [ :each | each value first >= caret ] ifNone: [ sorted last ] ].
	^ match key
]

{ #category : 'accessing' }
GbsRemoteDebuggerSourcePaneController >> service [
	^ debugger service
]

{ #category : 'accessing' }
GbsRemoteDebuggerSourcePaneController >> sourceText [
	^ debugger sourceTextPresenter
]

{ #category : 'accessing' }
GbsRemoteDebuggerSourcePaneController >> stackList [
	^ debugger stackListPresenter
]

{ #category : 'accessing' }
GbsRemoteDebuggerSourcePaneController >> setInitialSourceCode: aString [
	| topContext contexts |
	(self service notNil and: [ self service respondsTo: #restartSourceString: ])
		ifTrue: [ self service restartSourceString: (aString ifNil: [ '' ] ifNotNil: [ :text | text asString ]) ].
	contexts := self contextList ifNil: [ #( ) ].
	contexts ifEmpty: [ ^ self ].
	topContext := contexts at: 1.

	topContext instVarNamed: #sourceString put: aString.

	self stackList selectIndex: 1.
	debugger contextSelected: topContext
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> setSourceText: aString [
	self sourceText ifNil: [ ^ self ].
	(self sourceText respondsTo: #text:)
		ifTrue: [
			[ self sourceText text: aString ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> showCompileErrorInSourcePane [
	| message currentText |
	message := debugger safeServiceCall: [ self service lastCompileError ] default: nil.
	message ifNil: [ message := 'Compile failed in GemStone.' ].
	currentText := (self sourceText respondsTo: #text)
		ifTrue: [ self sourceText text asString ]
		ifFalse: [ '' ].
	self setSourceText: currentText, String lf, String lf, '"Compile error: ', message asString, '"'.
	self highlightSourceLineFromCompileError: message.
]

{ #category : 'private' }
GbsRemoteDebuggerSourcePaneController >> sourceMapFor: aContext [
	| map |
	map := #( ).
	self service ifNotNil: [
		map := [ self service sourceMap ] on: Error do: [ #( ) ] ].
	((map isCollection and: [ map isEmpty not ]) or: [ aContext isNil ]) ifTrue: [ ^ map ].
	^ [ aContext visibleSourceMap ] on: Error do: [ #( ) ]
]
