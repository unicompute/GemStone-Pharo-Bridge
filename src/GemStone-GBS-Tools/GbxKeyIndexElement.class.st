Class {
	#name : #'GbxKeyIndexElement',
	#superclass : #'GbxKeyedElement',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Tools'
}

{ #category : #'accessing' }
GbxKeyIndexElement >> partName
	^key printString

{ #category : #'accessing' }
GbxKeyIndexElement >> value: anObject 
	"we could receive a delegate or a wrapper or a special"

	| delegate |
	delegate := anObject gbxIsWrapped 
				ifTrue: [anObject delegate]
				ifFalse: [anObject putInGSSession: valueDelegate session].
	valueName := nil.
	object 
		unsynchronizedPerform: #_primitiveAt:put:
		with: key
		with: delegate.
	valueDelegate := delegate.
	^valueDelegate

{ #category : #'accessing' }
GbxKeyIndexElement >> displayString

	^Tools.Trippy.Inspector safeDisplayStringOf: key

{ #category : #'accessing' }
GbxKeyIndexElement >> key
	^key

{ #category : #'instance creation' }
GbxKeyIndexElement class >> of: object at: anIndex value: aGBSObject valueName: aString 
	^(self new)
		object: object;
		key: anIndex;
		valueDelegate: aGBSObject;
		valueName: aString;
		yourself

