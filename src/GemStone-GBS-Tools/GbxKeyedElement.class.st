Class {
	#name : 'GbxKeyedElement',
	#superclass : 'KeyedElement',
	#instVars : [
		'keyDelegate',
		'keyName',
		'valueDelegate',
		'valueName',
		'partName'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'comparing' }
GbxKeyedElement >> sameTypeEquals: aPart 
[
	^key == aPart key
]

{ #category : 'comparing' }
GbxKeyedElement >> = anObject
[
	
	self gbxFixMe.	"remove this method when vw75 is no longer supported. Needed for backwards compatibility 
	fix for bug 36144."
	^self class == anObject class and: [self sameTypeEquals: anObject]
]

{ #category : 'accessing' }
GbxKeyedElement >> valueName: anObject
[
	valueName := anObject
]

{ #category : 'accessing' }
GbxKeyedElement >> basicValueDelegate
[
	"make sure we have wrapped the valueDelegate to ensure consistency,
	then get the underlying delegate. #value does the wrapping"

	^self value delegate
]

{ #category : 'accessing' }
GbxKeyedElement >> keyDelegate
[
	^keyDelegate
]

{ #category : 'accessing' }
GbxKeyedElement >> text
[
	valueName isNil 
		ifTrue: 
			[valueName := object session evaluate: 'self printString'
						context: valueDelegate].
	^valueName
]

{ #category : 'accessing' }
GbxKeyedElement >> partName
[
	"used in the part's display string. cache this if its hit a lot"
	
	partName isNil
		ifTrue:
			[partName := keyDelegate session unsynchronizedEvaluate:
					' self printString' context: keyDelegate].
	^partName
]

{ #category : 'accessing' }
GbxKeyedElement >> keyDelegate: anObject
[
	keyDelegate := anObject
]

{ #category : 'accessing' }
GbxKeyedElement >> displayString
[
	^keyName
]

{ #category : 'accessing' }
GbxKeyedElement >> keyName: anObject
[
	keyName := anObject
]

{ #category : 'accessing' }
GbxKeyedElement >> valueDelegate
[
	^valueDelegate
]

{ #category : 'accessing' }
GbxKeyedElement >> key
[
	^keyDelegate
]

{ #category : 'accessing' }
GbxKeyedElement >> value: anObject 
[
	valueDelegate := object 
				remotePerform: #at:put:
				with: keyDelegate
				with: anObject asGSObject.
	valueName := object session evaluate: 'self printString'
				context: valueDelegate.
	^valueDelegate
]

{ #category : 'accessing' }
GbxKeyedElement >> valueDelegate: anObject
[
	valueDelegate := anObject
]

{ #category : 'accessing' }
GbxKeyedElement >> value
[

	^valueDelegate gbxIsWrapped
		ifTrue: [valueDelegate]
		ifFalse: [valueDelegate := Tools.Trippy.Inspector wrappedOrNot: valueDelegate]
]

{ #category : 'accessing' }
GbxKeyedElement >> refresh
[
	valueDelegate := object remotePerform: #at: with: keyDelegate.
	valueName := object session evaluate: 'self printString'
				context: valueDelegate
]

{ #category : 'instance creation' }
GbxKeyedElement class >> of: object key: key keyName: keyName value: value valueName: valueName 
[
	^(self new)
		object: object;
		keyDelegate: key;
		keyName: keyName;
		valueDelegate: value;
		valueName: valueName;
		yourself
]

