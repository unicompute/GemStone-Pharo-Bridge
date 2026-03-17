Class {
	#name : 'GbxSingleTripServerEvaluation',
	#superclass : 'GbxSingleTripServerInteraction',
	#instVars : [
		'contextDelegate',
		'cSourceCode',
		'isBlock',
		'sourceCode',
		'symbolListDelegate'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'dispatching' }
GbxSingleTripServerEvaluation >> storeTravDoArgs
[
	"Answer an arguments struct appropriate for myself.
	Since I don't know anything about such structs, ask the server interface for it, since it knows
	about such things."

	^serverInterface storeTravDoArgsForEvaluation: self
]

{ #category : 'accessing' }
GbxSingleTripServerEvaluation >> contextDelegate: anObject
[
	contextDelegate := anObject
]

{ #category : 'accessing' }
GbxSingleTripServerEvaluation >> sourceCode
[
	^sourceCode
]

{ #category : 'accessing' }
GbxSingleTripServerEvaluation >> sourceCode: anObject
[
	
	sourceCode := anObject.
	cSourceCode := anObject gbxAsCString
]

{ #category : 'accessing' }
GbxSingleTripServerEvaluation >> contextDelegate
[
	^contextDelegate
]

{ #category : 'accessing' }
GbxSingleTripServerEvaluation >> cSourceCode
[
	
	^cSourceCode
]

{ #category : 'accessing' }
GbxSingleTripServerEvaluation >> symbolListDelegate: anObject
[
	symbolListDelegate := anObject
]

{ #category : 'accessing' }
GbxSingleTripServerEvaluation >> symbolListDelegate
[
	^symbolListDelegate
]

{ #category : 'accessing' }
GbxSingleTripServerEvaluation >> isBlock: anObject
[
	isBlock := anObject
]

{ #category : 'accessing' }
GbxSingleTripServerEvaluation >> isBlock
[
	^isBlock
]

{ #category : 'printing' }
GbxSingleTripServerEvaluation >> printOn: aStream
[

	super printOn: aStream.
	aStream
		nextPut: $ ;
		nextPutAll: (sourceCode isString
					ifTrue: [sourceCode]
					ifFalse: [sourceCode printString])	"sourceCode can be nil"
]

{ #category : 'validation' }
GbxSingleTripServerEvaluation >> verify
[
	"Raise an error if someone gave me bogus things to execute.
	If everything looks hunky-dory, answer true."

	^(GbsError verifyBytes: sourceCode) 
		& (GbsError verify: contextDelegate is: GbxDelegate) 
			& (GbsError verify: symbolListDelegate is: GbxDelegate)
]

{ #category : 'initialize-release' }
GbxSingleTripServerEvaluation >> initialize
[
	"Initialize instance variables that have defaults. Others must be set explicitly."

	super initialize.
	contextDelegate := session oopIllegal.
	isBlock := false.
	symbolListDelegate := session oopNil
]

