Class {
	#name : 'GbxNamedVariable',
	#superclass : 'NamedVariable',
	#instVars : [
		'delegate',
		'cachedPrintString'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxNamedVariable >> index: anObject
[
	index := anObject
]

{ #category : 'accessing' }
GbxNamedVariable >> name: aString 
[
	name := aString
]

{ #category : 'accessing' }
GbxNamedVariable >> cachedPrintString: anObject
[
	cachedPrintString := anObject
]

{ #category : 'accessing' }
GbxNamedVariable >> value: anObject 
[
	| idx |
	cachedPrintString := nil.
	idx := object session 
				evaluate: '
	| gbxClass gbxIndex |
	gbxClass := self class.
	gbxIndex := gbxClass.instVarNames indexOf: ' 
						, name printString , ' asSymbol'
				context: object.
	object 
		remotePerform: #instVarAt:put:
		with: idx
		with: anObject asGSObject
]

{ #category : 'accessing' }
GbxNamedVariable >> value
[
	^delegate
]

{ #category : 'accessing' }
GbxNamedVariable >> text
[
	"cache the printString to avoid round trips"
	
	^cachedPrintString
		ifNil:
			[cachedPrintString := object session
				unsynchronizedEvaluate:
					'(self instVarAt: ' , index printString , ') printString'
				context: object]
]

{ #category : 'accessing' }
GbxNamedVariable >> delegate: anObject
[
	delegate := anObject
]

{ #category : 'initialize-release' }
GbxNamedVariable >> initialize
[
	self gbxFixMe.	"protected variables haven't been implemented yet"
	protected := false
]

{ #category : 'instance creation' }
GbxNamedVariable class >> of: anObject named: aString value: aGbsObject cachedPrintString: aString2 index: anInteger 
[
	^(self new initialize)
		object: anObject;
		name: aString;
		delegate: aGbsObject;
		cachedPrintString: aString2;
		index: anInteger;
		yourself
]
