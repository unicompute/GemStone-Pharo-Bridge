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
GbxActivation >> methodClass [
	^ methodClass
]

{ #category : 'accessing' }
GbxActivation >> receiver [
	^ receiver
]

{ #category : 'accessing' }
GbxActivation >> receiverClass [
	^ receiverClass
]

{ #category : 'accessing' }
GbxActivation >> sourceString [
	^ sourceString ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxActivation >> sourceCode [
	"Return source code, fetching from GemStone if not cached"
	sourceString ifNotNil: [ 
		sourceString isEmpty ifFalse: [ ^ sourceString ]
	].
	
	"Fetch source code directly from GemStone"
	| script result |
	script := '[
		| frame src |
		frame := self _gsiDebuggerDetailedReportAt: ', level asString, '.
		frame ifNil: [ ''<no source: frame is nil>'' ]
		ifNotNil: [
			frame first ifNil: [ ''<no source: entry is nil>'' ]
			ifNotNil: [
				frame first size >= 9 
					ifTrue: [ 
						src := frame first at: 9.
						src ifNil: [ ''<no source: sourceString is nil>'' ]
						ifNotNil: [ src ]
					]
					ifFalse: [ ''<no source: entry too small>'' ]
			]
		]
	] value'.
	
	result := [ session executeAndFetch: script context: session sessionOop ] 
		on: Error 
		do: [ :ex | '<error fetching source: ', ex messageText, '>' ].
	
	^ result ifNil: [ '<no source: result is nil>' ] ifNotNil: [ result ]
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
	
	result := session executeAndFetch: script context: session sessionOop.
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
	
	^ session executeAndFetch: script context: session sessionOop
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
	
	session executeAndFetch: script context: session sessionOop.
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
	"Return a dictionary of temp names and their values"
	| dict |
	dict := Dictionary new.
	1 to: self tempNames size do: [ :i |
		| name value |
		name := self tempNames at: i.
		value := self tempAt: i.
		dict at: name put: value.
	].
	^ dict
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
