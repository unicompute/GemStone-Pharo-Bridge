"
GbxActivationTool represents a single stack frame (activation context) 
from GemStone server execution in the Pharo debugger.

It provides access to:
- Method information (class, selector, source code)
- Temporary variables and arguments
- Receiver and self
- Source code offsets for highlighting

Based on VisualWorks GbxActivationTool class.
"
Class {
	#name : 'GbxActivationTool',
	#superclass : 'Object',
	#instVars : [
		'processOop',
		'level',
		'session',
		'gsMethodId',
		'selector',
		'sourceString',
		'sourceOffsets',
		'argAndTempNames',
		'numArgsAndTemps',
		'receiver',
		'receiverClass',
		'selfOop',
		'methodClass',
		'stackP',
		'ipOffset',
		'quickStepPoint'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxActivationTool class >> processOop: procOop level: aLevel session: aSession [
	| activation |
	activation := self new.
	activation
		processOop: procOop;
		level: aLevel.
	(activation respondsTo: #session:)
		ifTrue: [ activation session: aSession ]
		ifFalse: [ activation instVarNamed: 'session' put: aSession ].
	activation reset.
	^ activation
]

{ #category : 'comparing' }
GbxActivationTool >> = other [
	^ (other isKindOf: GbxActivationTool)
		and: [ other level = level 
		and: [ other gsMethodId = gsMethodId ] ]
]

{ #category : 'accessing' }
GbxActivationTool >> argAndTempNames [
	^ argAndTempNames ifNil: [ #( ) ]
]

{ #category : 'accessing' }
GbxActivationTool >> argAndTempNames: aCollection [
	argAndTempNames := aCollection
]

{ #category : 'accessing' }
GbxActivationTool >> argNames [
	"Return argument names only"
	argAndTempNames ifNil: [ ^ #( ) ].
	^ argAndTempNames copyFrom: 1 to: numArgsAndTemps
]

{ #category : 'accessing' }
GbxActivationTool >> ensureArgAndTempNames [
	argAndTempNames ifNil: [ argAndTempNames := #( ) ].
	numArgsAndTemps ifNil: [ numArgsAndTemps := 0 ]
]

{ #category : 'accessing' }
GbxActivationTool >> ensureSourceOffsets [
	sourceOffsets ifNil: [ sourceOffsets := #( ) ]
]

{ #category : 'accessing' }
GbxActivationTool >> ensureSourceString [
	sourceString ifNil: [ sourceString := '' ]
]

{ #category : 'testing' }
GbxActivationTool >> gbxIsServerContext [
	^ true
]

{ #category : 'accessing' }
GbxActivationTool >> gsMethodId [
	^ gsMethodId
]

{ #category : 'accessing' }
GbxActivationTool >> gsMethodId: aString [
	gsMethodId := aString
]

{ #category : 'accessing' }
GbxActivationTool >> gsMethodIdOrUnknown [
	^ gsMethodId ifNil: [ '<unknown>' ]
]

{ #category : 'accessing' }
GbxActivationTool >> hasSourceString [
	^ sourceString isNotNil and: [ sourceString isEmpty not ]
]

{ #category : 'comparing' }
GbxActivationTool >> hash [
	^ gsMethodId hash bitXor: level
]

{ #category : 'accessing' }
GbxActivationTool >> initializeFromClass: className selector: selectorName source: sourceText contextOop: contextOop [
	self methodClass: className.
	self selector: selectorName.
	self gsMethodId: className, '>>', selectorName asString.
	self sourceString: sourceText.
	self processOop: contextOop.
	self ensureSourceString.
	self ensureArgAndTempNames.
	self ensureSourceOffsets
]

{ #category : 'accessing' }
GbxActivationTool >> ipOffset [
	^ ipOffset ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxActivationTool >> ipOffset: anInteger [
	ipOffset := anInteger
]

{ #category : 'testing' }
GbxActivationTool >> isBlockContext [
	^ gsMethodId beginsWith: '[]'
]

{ #category : 'testing' }
GbxActivationTool >> isValid [
	^ processOop isNotNil and: [ processOop ~= 20 ]
]

{ #category : 'accessing' }
GbxActivationTool >> level [
	^ level
]

{ #category : 'accessing' }
GbxActivationTool >> level: anInteger [
	level := anInteger
]

{ #category : 'temp variables' }
GbxActivationTool >> marshalValue: anObject [
	"Convert a Pharo object to GemStone syntax"
	anObject ifNil: [ ^ 'nil' ].
	anObject == true ifTrue: [ ^ 'true' ].
	anObject == false ifTrue: [ ^ 'false' ].
	anObject isInteger ifTrue: [ ^ anObject asString ].
	anObject isString ifTrue: [ 
		^ '''', (anObject copyReplaceAll: '''' with: ''''''), '''' 
	].
	^ 'nil'
]

{ #category : 'accessing' }
GbxActivationTool >> methodClass [
	^ methodClass
]

{ #category : 'accessing' }
GbxActivationTool >> methodClass: aString [
	methodClass := aString
]

{ #category : 'accessing' }
GbxActivationTool >> methodClassOrUnknown [
	^ methodClass ifNil: [ '<unknown>' ]
]

{ #category : 'accessing' }
GbxActivationTool >> methodId [
	^ gsMethodId ifNil: [ '<unknown>' ]
]

{ #category : 'accessing' }
GbxActivationTool >> numArgsAndTemps [
	^ numArgsAndTemps ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxActivationTool >> numArgsAndTemps: anInteger [
	numArgsAndTemps := anInteger
]

{ #category : 'printing' }
GbxActivationTool >> printString [
	| className selectorString lineNumber |
	self isExecutedCodeFrame ifTrue: [
		lineNumber := self displayedLineNumber.
		^ String streamContents: [ :stream |
			stream
				nextPutAll: 'GS: Executed code @';
				nextPutAll: self displayedStepPoint asString.
			lineNumber ifNotNil: [
				stream
					nextPutAll: ' line ';
					nextPutAll: lineNumber asString
			]
		]
	].

	className := methodClass ifNil: [ '<unknown>' ] ifNotNil: [ methodClass ].
	selectorString := selector ifNil: [ '<unknown>' ] ifNotNil: [ selector ].
	^ className, '>>', selectorString
]

{ #category : 'accessing' }
GbxActivationTool >> processOop [
	^ processOop
]

{ #category : 'accessing' }
GbxActivationTool >> processOop: anOop [
	processOop := anOop
]

{ #category : 'accessing' }
GbxActivationTool >> quickStepPoint [
	^ quickStepPoint ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxActivationTool >> quickStepPoint: anInteger [
	quickStepPoint := anInteger
]

{ #category : 'accessing' }
GbxActivationTool >> receiver [
	^ receiver
]

{ #category : 'accessing' }
GbxActivationTool >> receiver: anObject [
	receiver := anObject
]

{ #category : 'accessing' }
GbxActivationTool >> receiverClass [
	^ receiverClass
]

{ #category : 'accessing' }
GbxActivationTool >> receiverClass: aString [
	receiverClass := aString
]

{ #category : 'accessing' }
GbxActivationTool >> receiverClassOrUnknown [
	^ receiverClass ifNil: [ '<unknown>' ]
]

{ #category : 'private' }
GbxActivationTool >> reset [
	"Fetch activation data from GemStone"
	| script result parts |
	
	script := '[
		| obj frame fullEntry firstItem methodOrNil thisReceiver thisSelf numArgsTemps className selectorName sourceStr |
		obj := Object _objectForOop: ', processOop asString, '.
		obj ifNil: [ ^ ''ERROR|nil'' ].
		frame := [ obj _gsiDebuggerDetailedReportAt: ', level asString, ' ] on: Error do: [ nil ].
		frame ifNil: [ ^ ''ERROR|nil'' ].
		fullEntry := frame.
		firstItem := [ fullEntry at: 1 ] on: Error do: [ nil ].
		((firstItem notNil)
			and: [ (firstItem respondsTo: #selector) not
			and: [ firstItem respondsTo: #at ] ])
			ifTrue: [ fullEntry := firstItem ].
		fullEntry ifNil: [ ^ ''ERROR|nil'' ].
		methodOrNil := [ fullEntry at: 1 ] on: Error do: [ nil ].
		thisReceiver := fullEntry at: 2.
		thisSelf := fullEntry at: 3.
		numArgsTemps := 
			thisReceiver == thisSelf
				ifTrue: [ 
					methodOrNil ifNil: [ 0 ] ifNotNil: [ methodOrNil _numArgsTempsCblkargs ]
				]
				ifFalse: [ methodOrNil _numArgsTempsCblkargs ].
		className := methodOrNil ifNil: [ ''<unknown>'' ] ifNotNil: [ methodOrNil inClass ifNil: [ ''<unknown>'' ] ifNotNil: [ methodOrNil inClass name ] ].
			selectorName := fullEntry at: 4.
			selectorName ifNil: [ selectorName := ''unboundMethod'' ].
			sourceStr := fullEntry at: 9.
			sourceStr ifNil: [ sourceStr := '''' ].
			sourceStr := sourceStr copyReplaceAll: ''|'' with: ''<PIPE>''.
			"Return pipe-separated values for easy parsing"
			className, ''|'', selectorName asString, ''|'', 
			(fullEntry at: 5) printString, ''|'',
		(fullEntry at: 6) printString, ''|'',
		(fullEntry at: 7) printString, ''|'',
		sourceStr, ''|'',
		(fullEntry at: 10) printString, ''|'',
		numArgsTemps printString, ''|'',
		(fullEntry at: 8) size printString, ''|'',
		className, ''|'',
		thisReceiver printString, ''|'',
		thisReceiver class name, ''|'',
		thisSelf printString
	] value'.
	
	result := [ session evaluate: script ] on: Error do: [ 'ERROR|nil' ].
	(result respondsTo: #asLocalString) ifTrue: [ result := result asLocalString ].
	result ifNil: [ result := 'ERROR|nil' ].
	(result beginsWith: 'ERROR') ifTrue: [ ^ self ].
	
	"Parse the pipe-separated result"
	parts := result splitOn: $|.
	parts size >= 13 ifTrue: [
		gsMethodId := (parts at: 1), '>>', (parts at: 2).
		selector := (parts at: 2) asSymbol.
		quickStepPoint := (parts at: 3) asInteger.
			sourceOffsets := (parts at: 4) splitOn: $,.
			argAndTempNames := (parts at: 5) splitOn: $,.
			sourceString := (parts at: 6) copyReplaceAll: '<PIPE>' with: '|'.
			ipOffset := (parts at: 7) asInteger.
		numArgsAndTemps := (parts at: 8) asInteger.
		stackP := (parts at: 9) asInteger.
		methodClass := parts at: 10.
		receiver := parts at: 11.
		receiverClass := parts at: 12.
		selfOop := parts at: 13.
	].
]

{ #category : 'accessing' }
GbxActivationTool >> selector [
	^ selector ifNil: [ #unboundMethod ]
]

{ #category : 'accessing' }
GbxActivationTool >> selector: aSymbol [
	selector := aSymbol
]

{ #category : 'accessing' }
GbxActivationTool >> selectorOrUnknown [
	^ selector ifNil: [ #unboundMethod ]
]

{ #category : 'private' }
GbxActivationTool >> displayedLineNumber [
	| stepPoint rawOffset offset source line pos |
	source := self sourceString.
	source isEmpty ifTrue: [
		(ipOffset isNumber and: [ ipOffset > 0 ]) ifTrue: [ ^ ipOffset ].
		^ nil
	].

	stepPoint := self quickStepPoint.
	stepPoint > 0 ifFalse: [ ^ nil ].
	rawOffset := self sourceOffsets at: stepPoint ifAbsent: [ nil ].
	rawOffset ifNil: [ ^ nil ].
	offset := [ rawOffset asInteger ] on: Error do: [ nil ].
	offset ifNil: [ ^ nil ].
	(offset <= 0 or: [ offset > source size ]) ifTrue: [ ^ nil ].

	line := 1.
	pos := 1.
	[ pos < offset ] whileTrue: [
		((source at: pos) = Character lf or: [ (source at: pos) = Character cr ])
			ifTrue: [ line := line + 1 ].
		pos := pos + 1
	].
	^ line
]

{ #category : 'private' }
GbxActivationTool >> displayedStepPoint [
	quickStepPoint ifNotNil: [ :step | step > 0 ifTrue: [ ^ step ] ].
	^ level ifNil: [ 1 ]
]

{ #category : 'testing' }
GbxActivationTool >> isExecutedCodeFrame [
	| className selectorString |
	className := self methodClassOrUnknown asString.
	selectorString := self selectorOrUnknown asString.
	^ (className = 'nil' or: [ className = '<unknown>' ])
		and: [ selectorString = 'nil' or: [ selectorString = 'unboundMethod' ] ]
]

{ #category : 'testing' }
GbxActivationTool >> markAsExecutedCodeFrame [
	"Mark this frame as an executed code frame (for restart)"
	"Sets class/selector to unknown and step/line to 1"
	methodClass := 'nil'.
	selector := #unboundMethod.
	quickStepPoint := 1.
	ipOffset := 1.
	"Provide some default offsets so that step points 1-5 at least highlight the start"
	sourceOffsets := #( 1 1 1 1 1 ).
]

{ #category : 'accessing' }
GbxActivationTool >> selfOop [
	^ selfOop
]

{ #category : 'accessing' }
GbxActivationTool >> selfOop: anObject [
	selfOop := anObject
]

{ #category : 'accessing' }
GbxActivationTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxActivationTool >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxActivationTool >> sourceCode [
	"Return cached source string"
	^ sourceString ifNil: [ '' ]
]

{ #category : 'source map' }
GbxActivationTool >> sourceIntervalForStepPoint: aStepPoint [
	| map entry |
	aStepPoint ifNil: [ ^ nil ].
	map := self visibleSourceMap.
	entry := map
		detect: [ :assoc | (assoc respondsTo: #key) and: [ assoc key = aStepPoint ] ]
		ifNone: [ nil ].
	^ entry ifNil: [ nil ] ifNotNil: [ entry value ]
]

{ #category : 'accessing' }
GbxActivationTool >> sourceOffsetAt: anIndex [
	^ (self sourceOffsets at: anIndex ifAbsent: [ 0 ])
]

{ #category : 'accessing' }
GbxActivationTool >> sourceOffsets [
	^ sourceOffsets ifNil: [ #( ) ]
]

{ #category : 'accessing' }
GbxActivationTool >> sourceOffsets: aCollection [
	sourceOffsets := aCollection
]

{ #category : 'accessing' }
GbxActivationTool >> sourceOffsetsSize [
	^ self sourceOffsets size
]

{ #category : 'accessing' }
GbxActivationTool >> sourceString [
	^ sourceString ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxActivationTool >> sourceString: aString [
	sourceString := aString
]

{ #category : 'accessing' }
GbxActivationTool >> stackP [
	^ stackP ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxActivationTool >> stackP: anInteger [
	stackP := anInteger
]

{ #category : 'source map' }
GbxActivationTool >> stepPoint [
	"VW parity alias used by debugger/source-map consumers."
	^ self quickStepPoint
]

{ #category : 'temp variables' }
GbxActivationTool >> tempAt: index [
	"Get the value of a temp variable at index"
	| script |
	script := '[
		| frame |
		frame := self _frameContentsAt: ', level asString, '.
		frame ifNotNil: [ 
			frame size >= (10 + ', index asString, ') 
				ifTrue: [ frame at: ', (10 + index) asString, ' ]
				ifFalse: [ nil ]
		] ifNil: [ nil ]
	] value'.
	
	^ [ session evaluate: script ] on: Error do: [ nil ]
]

{ #category : 'temp variables' }
GbxActivationTool >> tempAt: index put: anObject [
	"Set the value of a temp variable at index"
	| script marshaledValue |
	marshaledValue := self marshalValue: anObject.
	script := '[
		| frame |
		frame := self _frameContentsAt: ', level asString, '.
		frame ifNotNil: [ 
			frame at: ', (10 + index) asString, ' put: ', marshaledValue, '
		]
	] value'.
	
	[ session evaluate: script ] on: Error do: [ ].
	self reset.
]

{ #category : 'accessing' }
GbxActivationTool >> tempNames [
	"Return temp variable names (includes arguments)"
	argAndTempNames ifNil: [ ^ #( ) ].
	^ argAndTempNames copyFrom: 1 to: (numArgsAndTemps min: argAndTempNames size)
]

{ #category : 'temp variables' }
GbxActivationTool >> tempNamesAndValues [
	"Return temp/arg values for this activation.
	Supports both context-backed and process-backed stack frames."
	| script result localDict |
	
	script := '[
		| obj dict frame fullEntry firstItem names vals maxCount receiverObj stream keyText valueText |
		obj := Object _objectForOop: ', processOop asString, '.
		obj ifNil: [ ^ '''' ].
		dict := Dictionary new.

		"Preferred: process/frame report path (VW correspondence)"
		(obj respondsTo: #_gsiDebuggerDetailedReportAt:) ifTrue: [
			frame := [ obj _gsiDebuggerDetailedReportAt: ', level asString, ' ] on: Error do: [ nil ].
			frame ifNotNil: [
				fullEntry := frame.
				firstItem := [ fullEntry at: 1 ] on: Error do: [ nil ].
				((firstItem notNil)
					and: [ (firstItem respondsTo: #selector) not
					and: [ firstItem respondsTo: #at ] ])
					ifTrue: [ fullEntry := firstItem ].
				receiverObj := [ fullEntry at: 2 ] on: Error do: [ nil ].
				receiverObj ifNotNil: [ dict at: ''self'' put: receiverObj ].
				names := [ fullEntry at: 7 ] on: Error do: [ #() ].
				vals := [ fullEntry at: 8 ] on: Error do: [ #() ].
				maxCount := (names size min: vals size) min: 200.
				1 to: maxCount do: [ :i |
					[ dict at: (names at: i) asString put: (vals at: i) ] on: Error do: [ ].
				]
			]
		].

		"Fallback: context tempAt: path"
		(obj respondsTo: #method) ifTrue: [
			[ dict at: ''self'' put: (obj receiver) ] on: Error do: [ ].
			[ obj method ifNotNil: [ :m |
				m tempNames doWithIndex: [ :name :i |
					| val |
					[
						val := obj tempAt: i.
						dict at: name asString put: val
					] on: Error do: [ ].
				]
				] ] on: Error do: [ ].
		].

		stream := WriteStream on: String new.
		dict keysAndValuesDo: [ :k :v |
			keyText := [ k asString ] on: Error do: [ ''<key-error>'' ].
			valueText := [ v printString ] on: Error do: [ ''<value-error>'' ].
			keyText := keyText
				copyReplaceAll: Character tab asString with: ''<TAB>'';
				copyReplaceAll: String cr with: ''<CR>'';
				copyReplaceAll: String lf with: ''<LF>''.
			valueText := valueText
				copyReplaceAll: Character tab asString with: ''<TAB>'';
				copyReplaceAll: String cr with: ''<CR>'';
				copyReplaceAll: String lf with: ''<LF>''.
			stream
				nextPutAll: keyText;
				tab;
				nextPutAll: valueText;
				lf.
		].
		stream contents
	] value'.
	
	[
		result := session evaluate: script.
		(result respondsTo: #asLocalString) ifTrue: [ result := result asLocalString ].
		result ifNil: [ ^ Dictionary new ].
		result isString ifFalse: [ ^ Dictionary new ].

		localDict := Dictionary new.
		(result splitOn: Character lf) do: [ :line |
			| parts key value |
			line isEmpty ifFalse: [
				parts := line splitOn: Character tab.
				parts size >= 2 ifTrue: [
					key := ((((parts at: 1)
						copyReplaceAll: '<TAB>' with: Character tab asString)
						copyReplaceAll: '<CR>' with: String cr)
						copyReplaceAll: '<LF>' with: String lf).
					value := ((((parts at: 2)
						copyReplaceAll: '<TAB>' with: Character tab asString)
						copyReplaceAll: '<CR>' with: String cr)
						copyReplaceAll: '<LF>' with: String lf).
					localDict at: key put: value.
				].
			].
		].
		^ localDict
	] on: Error do: [ :ex |
		^ Dictionary new
	]
]

{ #category : 'source map' }
GbxActivationTool >> visibleSourceMap [
	"VW parity: infer highlight range from source offset and token class."
	| map numStepPoints binaryCharClass keywordFirstCharClass keywordCharClass nullCharClass sourceText |
	binaryCharClass := '+-*~<>=|/&@%,?!\'.
	keywordFirstCharClass := '_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.
	keywordCharClass := keywordFirstCharClass , ':0123456789'.
	nullCharClass := ''.
	sourceText := self sourceString ifNil: [ '' ].
	numStepPoints := self sourceOffsets size.
	map := OrderedCollection new: numStepPoints.

	sourceText isEmpty ifTrue: [ ^ map ].

	1 to: numStepPoints do: [ :i |
		| rawOffset startOffset endOffset limit currentChar foundEnd charClass |
		rawOffset := self sourceOffsets at: i ifAbsent: [ nil ].
		rawOffset ifNotNil: [
			startOffset := [ rawOffset asInteger ] on: Error do: [ nil ].
			startOffset ifNotNil: [
				(startOffset > 0 and: [ startOffset <= sourceText size ]) ifTrue: [
					limit := sourceText size.
					endOffset := startOffset.
					currentChar := sourceText at: startOffset.
					foundEnd := false.

					currentChar = $^
						ifFalse: [
							(currentChar = $:
								and: [ (startOffset + 1 <= limit) and: [ (sourceText at: startOffset + 1) = $= ] ])
								ifTrue: [ endOffset := startOffset + 1 ]
								ifFalse: [
									charClass := (keywordFirstCharClass includes: currentChar)
										ifTrue: [ keywordCharClass ]
										ifFalse: [
											(binaryCharClass includes: currentChar)
												ifTrue: [ binaryCharClass ]
												ifFalse: [ nullCharClass ]
										].
									[ (endOffset < limit) and: [ foundEnd not ] ] whileTrue: [
										endOffset := endOffset + 1.
										currentChar := sourceText at: endOffset.
										foundEnd := (charClass includes: currentChar) not.
										foundEnd ifTrue: [ endOffset := endOffset - 1 ].
									]
								]
						].

					map add: (i -> (startOffset to: endOffset))
				]
			]
		]
	].
	^ map
]
