"
GbxActivation represents a single stack frame (activation context) 
from GemStone server execution in the Pharo debugger.

It provides access to:
- Method information (class, selector, source code)
- Temporary variables and arguments
- Receiver and self
- Source code offsets for highlighting

Based on VisualWorks GbxActivation class.
"
Class {
	#name : 'GbxActivation',
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
GbxActivation class >> processOop: procOop level: aLevel session: aSession [
	^ self new
		processOop: procOop;
		level: aLevel;
		session: aSession;
		reset;
		yourself
]

{ #category : 'testing' }
GbxActivation >> isBlockContext [
	^ gsMethodId beginsWith: '[]'
]

{ #category : 'testing' }
GbxActivation >> gbxIsServerContext [
	^ true
]

{ #category : 'testing' }
GbxActivation >> isValid [
	^ processOop isNotNil and: [ processOop ~= 20 ]
]

{ #category : 'accessing' }
GbxActivation >> processOop: anOop [
	processOop := anOop
]

{ #category : 'accessing' }
GbxActivation >> level: anInteger [
	level := anInteger
]

{ #category : 'accessing' }
GbxActivation >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxActivation >> level [
	^ level
]

{ #category : 'accessing' }
GbxActivation >> selector [
	^ selector ifNil: [ #unboundMethod ]
]

{ #category : 'accessing' }
GbxActivation >> selector: aSymbol [
	selector := aSymbol
]

{ #category : 'accessing' }
GbxActivation >> gsMethodId [
	^ gsMethodId
]

{ #category : 'accessing' }
GbxActivation >> gsMethodId: aString [
	gsMethodId := aString
]

{ #category : 'accessing' }
GbxActivation >> methodClass [
	^ methodClass
]

{ #category : 'accessing' }
GbxActivation >> methodClass: aString [
	methodClass := aString
]

{ #category : 'accessing' }
GbxActivation >> receiver [
	^ receiver
]

{ #category : 'accessing' }
GbxActivation >> receiver: anObject [
	receiver := anObject
]

{ #category : 'accessing' }
GbxActivation >> receiverClass [
	^ receiverClass
]

{ #category : 'accessing' }
GbxActivation >> receiverClass: aString [
	receiverClass := aString
]

{ #category : 'accessing' }
GbxActivation >> sourceString [
	^ sourceString ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxActivation >> sourceString: aString [
	sourceString := aString
]

{ #category : 'accessing' }
GbxActivation >> sourceCode [
	"Return cached source string"
	^ sourceString ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxActivation >> sourceOffsets [
	^ sourceOffsets ifNil: [ #( ) ]
]

{ #category : 'accessing' }
GbxActivation >> tempNames [
	"Return temp variable names (includes arguments)"
	argAndTempNames ifNil: [ ^ #( ) ].
	^ argAndTempNames copyFrom: 1 to: (numArgsAndTemps min: argAndTempNames size)
]

{ #category : 'accessing' }
GbxActivation >> argNames [
	"Return argument names only"
	argAndTempNames ifNil: [ ^ #( ) ].
	^ argAndTempNames copyFrom: 1 to: numArgsAndTemps
]

{ #category : 'accessing' }
GbxActivation >> methodId [
	^ gsMethodId ifNil: [ '<unknown>' ]
]

{ #category : 'printing' }
GbxActivation >> printString [
	| className selectorString |
	className := methodClass ifNil: [ '<unknown>' ] ifNotNil: [ methodClass ].
	selectorString := selector ifNil: [ '<unknown>' ] ifNotNil: [ selector ].
	^ className, '>>', selectorString
]

{ #category : 'private' }
GbxActivation >> reset [
	"Fetch activation data from GemStone"
	| script result parts |
	
	script := '[
		| frame fullEntry methodOrNil thisReceiver thisSelf numArgsTemps className selectorName sourceStr |
		frame := self _gsiDebuggerDetailedReportAt: ', level asString, '.
		frame ifNil: [ ^ ''ERROR|nil'' ].
		fullEntry := frame first.
		fullEntry ifNil: [ ^ ''ERROR|nil'' ].
		methodOrNil := fullEntry first.
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
			selectorName ifNil: [ selectorName := ''<unknown>'' ].
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

{ #category : 'temp variables' }
GbxActivation >> tempAt: index [
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
GbxActivation >> tempAt: index put: anObject [
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

{ #category : 'temp variables' }
GbxActivation >> marshalValue: anObject [
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

{ #category : 'temp variables' }
GbxActivation >> tempNamesAndValues [
	"Return temp/arg values for this activation.
	Supports both context-backed and process-backed stack frames."
	| script result |
	
	script := '[
		| obj dict frame names vals maxCount |
		obj := Object _objectForOop: ', processOop asString, '.
		obj ifNil: [ ^ Dictionary new ].
		dict := Dictionary new.

		"Preferred: process/frame report path (VW correspondence)"
		(obj respondsTo: #_gsiDebuggerDetailedReportAt:) ifTrue: [
			frame := [ obj _gsiDebuggerDetailedReportAt: ', level asString, ' ] on: Error do: [ nil ].
			frame ifNotNil: [
				names := [ frame at: 7 ] on: Error do: [ #() ].
				vals := [ frame at: 8 ] on: Error do: [ #() ].
				maxCount := (names size min: vals size) min: 200.
				1 to: maxCount do: [ :i |
					[ dict at: (names at: i) asString put: (vals at: i) ] on: Error do: [ ].
				].
				^ dict
			]
		].

		"Fallback: context tempAt: path"
		(obj respondsTo: #method) ifTrue: [
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
		dict
	] value'.
	
	[
		result := session evaluate: script.
		^ result ifNil: [ Dictionary new ] ifNotNil: [ result ]
	] on: Error do: [ :ex |
		^ Dictionary new
	]
]

{ #category : 'accessing' }
GbxActivation >> selfOop [
	^ selfOop
]

{ #category : 'accessing' }
GbxActivation >> selfOop: anObject [
	selfOop := anObject
]

{ #category : 'accessing' }
GbxActivation >> argAndTempNames: aCollection [
	argAndTempNames := aCollection
]

{ #category : 'accessing' }
GbxActivation >> numArgsAndTemps: anInteger [
	numArgsAndTemps := anInteger
]

{ #category : 'accessing' }
GbxActivation >> sourceOffsets: aCollection [
	sourceOffsets := aCollection
]

{ #category : 'accessing' }
GbxActivation >> ipOffset: anInteger [
	ipOffset := anInteger
]

{ #category : 'accessing' }
GbxActivation >> stackP: anInteger [
	stackP := anInteger
]

{ #category : 'accessing' }
GbxActivation >> quickStepPoint: anInteger [
	quickStepPoint := anInteger
]

{ #category : 'accessing' }
GbxActivation >> processOop [
	^ processOop
]

{ #category : 'accessing' }
GbxActivation >> session [
	^ session
]

{ #category : 'accessing' }
GbxActivation >> numArgsAndTemps [
	^ numArgsAndTemps ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxActivation >> argAndTempNames [
	^ argAndTempNames ifNil: [ #( ) ]
]

{ #category : 'accessing' }
GbxActivation >> quickStepPoint [
	^ quickStepPoint ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxActivation >> ipOffset [
	^ ipOffset ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxActivation >> stackP [
	^ stackP ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxActivation >> sourceOffsetAt: anIndex [
	^ (self sourceOffsets at: anIndex ifAbsent: [ 0 ])
]

{ #category : 'accessing' }
GbxActivation >> sourceOffsetsSize [
	^ self sourceOffsets size
]

{ #category : 'accessing' }
GbxActivation >> gsMethodIdOrUnknown [
	^ gsMethodId ifNil: [ '<unknown>' ]
]

{ #category : 'accessing' }
GbxActivation >> methodClassOrUnknown [
	^ methodClass ifNil: [ '<unknown>' ]
]

{ #category : 'accessing' }
GbxActivation >> receiverClassOrUnknown [
	^ receiverClass ifNil: [ '<unknown>' ]
]

{ #category : 'accessing' }
GbxActivation >> selectorOrUnknown [
	^ selector ifNil: [ #unboundMethod ]
]

{ #category : 'accessing' }
GbxActivation >> hasSourceString [
	^ sourceString isNotNil and: [ sourceString isEmpty not ]
]

{ #category : 'accessing' }
GbxActivation >> ensureSourceString [
	sourceString ifNil: [ sourceString := '' ]
]

{ #category : 'accessing' }
GbxActivation >> ensureArgAndTempNames [
	argAndTempNames ifNil: [ argAndTempNames := #( ) ].
	numArgsAndTemps ifNil: [ numArgsAndTemps := 0 ]
]

{ #category : 'accessing' }
GbxActivation >> ensureSourceOffsets [
	sourceOffsets ifNil: [ sourceOffsets := #( ) ]
]

{ #category : 'accessing' }
GbxActivation >> initializeFromClass: className selector: selectorName source: sourceText contextOop: contextOop [
	self methodClass: className.
	self selector: selectorName.
	self gsMethodId: className, '>>', selectorName asString.
	self sourceString: sourceText.
	self processOop: contextOop.
	self ensureSourceString.
	self ensureArgAndTempNames.
	self ensureSourceOffsets
]

{ #category : 'source map' }
GbxActivation >> visibleSourceMap [
	"Create a source map for highlighting"
	| map numStepPoints |
	numStepPoints := sourceOffsets size.
	map := OrderedCollection new: numStepPoints.
	
	1 to: numStepPoints do: [ :i |
		| startOffset |
		startOffset := (sourceOffsets at: i) asInteger.
		startOffset > 0 ifTrue: [
			map add: (i -> (startOffset to: startOffset + 10))
		].
	].
	^ map
]

{ #category : 'comparing' }
GbxActivation >> = other [
	^ other isKindOf: GbxActivation
		and: [ other level = level 
		and: [ other gsMethodId = gsMethodId ] ]
]

{ #category : 'comparing' }
GbxActivation >> hash [
	^ gsMethodId hash bitXor: level
]
