Class {
	#name : #'GbxMultiTripServerEvaluation',
	#superclass : #'GbxMultiTripServerInteraction',
	#instVars : [ #'contextDelegate' #'isBlock' #'sourceCode' #'symbolListDelegate' #'cSourceCode' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'accessing' }
GbxMultiTripServerEvaluation >> sourceCode: anObject
	
	sourceCode := anObject.
	cSourceCode := anObject gbxAsCString

{ #category : #'accessing' }
GbxMultiTripServerEvaluation >> contextDelegate
	^contextDelegate

{ #category : #'accessing' }
GbxMultiTripServerEvaluation >> cSourceCode
	
	^cSourceCode

{ #category : #'accessing' }
GbxMultiTripServerEvaluation >> symbolListDelegate: anObject
	symbolListDelegate := anObject

{ #category : #'accessing' }
GbxMultiTripServerEvaluation >> symbolListDelegate
	^symbolListDelegate

{ #category : #'accessing' }
GbxMultiTripServerEvaluation >> isBlock: anObject
	isBlock := anObject

{ #category : #'accessing' }
GbxMultiTripServerEvaluation >> isBlock
	^isBlock

{ #category : #'accessing' }
GbxMultiTripServerEvaluation >> contextDelegate: anObject
	contextDelegate := anObject

{ #category : #'accessing' }
GbxMultiTripServerEvaluation >> sourceCode
	^sourceCode

{ #category : #'private' }
GbxMultiTripServerEvaluation >> adjustForBlock
	
	| sourceStream |
	sourceStream := WriteStream on: String new.
	sourceStream nextPutAll: sourceCode copy.
	argumentDelegates isEmpty
		ifTrue:
			[sourceStream
				nextPut: Character space;
				nextPutAll: 'value']
		ifFalse:
			[argumentDelegates
				do:
					[:argDelegate | 
					sourceStream
						nextPut: Character cr;
						nextPutAll: ' value: ';
						nextPut: $(;
						nextPutAll: 'Object _objectForOop: ';
						nextPutAll: argDelegate oopValue printString;
						nextPut: $)]].
	self sourceCode: sourceStream contents

{ #category : #'validation' }
GbxMultiTripServerEvaluation >> verify
	"Raise an error if someone gave me bogus things to execute.
	If everything looks hunky-dory, answer true."

	^(GbsError verifyBytes: sourceCode) 
		& (GbsError verify: contextDelegate is: GbxDelegate) 
			& (GbsError verify: symbolListDelegate is: GbxDelegate)

{ #category : #'initialize-release' }
GbxMultiTripServerEvaluation >> initialize
	"Initialize instance variables that have defaults. Others must be set explicitly."
	
	super initialize.
	contextDelegate := session oopIllegal.
	symbolListDelegate := session oopNil.
	isBlock := false

{ #category : #'dispatching' }
GbxMultiTripServerEvaluation >> storeTravDoArgs
	"Answer an arguments struct appropriate for myself.
	Since I don't know anything about such structs, ask the server interface for it, since it knows
	about such things."
	
	isBlock ifTrue: [self adjustForBlock].
	^serverInterface storeTravDoArgsForEvaluation: self

{ #category : #'printing' }
GbxMultiTripServerEvaluation >> printOn: aStream

	super printOn: aStream.
	aStream
		nextPut: $ ;
		nextPutAll: sourceCode

