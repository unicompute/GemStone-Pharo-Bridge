Class {
	#name : 'GbxInspectionWrapper',
	#superclass : 'Object',
	#instVars : [
		'localObject',
		'inspectedObject'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxInspectionWrapper >> inspectedObject: anObject
[
	inspectedObject := anObject
]

{ #category : 'accessing' }
GbxInspectionWrapper >> localObject
[
	^localObject
]

{ #category : 'accessing' }
GbxInspectionWrapper >> inspectedObject
[
	^inspectedObject
]

{ #category : 'accessing' }
GbxInspectionWrapper >> localObject: anObject
[
	localObject := anObject
]

{ #category : 'accessing' }
GbxInspectionWrapper >> gbxClientDoItReceiver
[
	"A message understood only by wrappers, to return the object used as 'self' for client execution
	in an inspector. Otherwise equivalent to #doItReceiver"

	^localObject == SpecialGemStoneObjects.NotCachedToken ifTrue: [nil] ifFalse: [localObject]
]

{ #category : 'private - inspecting' }
GbxInspectionWrapper >> inspectorClasses
[

	^localObject gbxIsProxy
		ifTrue: [OrderedCollection with: GbxClientBasicProxyInspector]
		ifFalse: [super inspectorClasses]
]

{ #category : 'initialize-release' }
GbxInspectionWrapper >> fetchInitialInfo
[
	self subclassResponsibility
]

{ #category : 'user interface' }
GbxInspectionWrapper >> browseHierarchy
[
	inspectedObject browseHierarchy
]

{ #category : 'user interface' }
GbxInspectionWrapper >> browse
[
	inspectedObject browse
]

{ #category : 'printing' }
GbxInspectionWrapper >> printString
[

	^self gbxDebugPrintString
]

{ #category : 'printing' }
GbxInspectionWrapper >> printOn: aStream
[
	^self gbxDebugPrintOn: aStream
]

{ #category : 'gemstone private' }
GbxInspectionWrapper >> gbxDebugPrintOn: aStream
[
	^inspectedObject gbxDebugPrintOn: aStream
]

{ #category : 'private - inspecting' }
GbxInspectionWrapper class >> isDelegate: obj
[
	"Answer whether obj is a delegate without sending messages to obj that it doesn't understand"

	^GbsStackDumper
		ifUnderstoodSend: #gbxIsDelegate
		to: obj
		else: [false]
]

{ #category : 'instance creation' }
GbxInspectionWrapper class >> findLocalObjectFromObject: aDelegateOrNot delegate: delegate sesssion: sess
[
	"we don't know yet if we're inspecting a delegate or a client object"

	| localObj |
	(self isDelegate: aDelegateOrNot)
		ifFalse: [localObj := aDelegateOrNot]
		ifTrue: 
			[localObj := sess
						ifNil: [NotCachedToken]
						ifNotNil: 
							[sess sessionCritical: 
									[sess clientObjForDelegate: delegate otherwise: NotCachedToken]]].
	^localObj
]

{ #category : 'instance creation' }
GbxInspectionWrapper class >> wrapperClassFor: anObject
[
	^anObject gbxIsProxy ifTrue: [GbxProxyInspectionWrapper] ifFalse: [GbxReplicateInspectionWrapper]
]

{ #category : 'instance creation' }
GbxInspectionWrapper class >> wrap: aDelegateOrNot delegate: delegate session: sess
[
	| inst localObj |
	localObj := self
				findLocalObjectFromObject: aDelegateOrNot
				delegate: delegate
				sesssion: sess.
	inst := ((self wrapperClassFor: localObj) new)
				localObject: localObj;
				session: sess;
				delegate: delegate.
	inst fetchInitialInfo.
	^inst
]

{ #category : 'instance creation' }
GbxInspectionWrapper class >> wrapObject: aDelegateOrNot
[
	| delegate sess local |
	delegate := (self isDelegate: aDelegateOrNot)
				ifTrue: 
					[local := NotCachedToken.
					aDelegateOrNot]
				ifFalse: 
					[local := aDelegateOrNot.
					aDelegateOrNot gbxDelegate].
	delegate ~~ nil ifTrue: [delegate := delegate forAnySingleSession].
	(delegate notNil and: [delegate hasLiveSessionFlag])
		ifTrue: 
			[sess := delegate noCheckSession.
			^sess isNil
				ifTrue: [GbxInspectionWrapperNoSession new localObject: aDelegateOrNot	"could have logged out after the first check"]
				ifFalse: 
					[sess critical: [self wrap: aDelegateOrNot delegate: delegate session: sess]
						unlessBlocked: 
							[((self wrapperClassFor: local) new)
								localObject: local;
								session: sess;
								delegate: delegate]]]
		ifFalse: 
			[" dead or blocked session"
			^GbxInspectionWrapperNoSession new localObject: aDelegateOrNot]
]

{ #category : 'instance creation' }
GbxInspectionWrapper class >> on: aDelegateOrNot
[
	"determine as best we can what kind of wrapper to be"

	" dead or blocked session"

	| inst |
	inst := self wrapObject: aDelegateOrNot.
	inst inspectedObject: aDelegateOrNot.
	^inst
]

