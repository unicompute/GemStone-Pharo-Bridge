Class {
	#name : 'GbxReplicateInspectionWrapper',
	#superclass : 'GbxInspectionWrapperWithSession',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxReplicateInspectionWrapper >> partName
[
	^objectText
]

{ #category : 'accessing' }
GbxReplicateInspectionWrapper >> value
[
	^self
]

{ #category : 'accessing' }
GbxReplicateInspectionWrapper >> doItReceiver
[
	^localObject
]

{ #category : 'printing' }
GbxReplicateInspectionWrapper >> basicPrintOn: aStream
[
	"it is possible for a client object's class and gemstone object's class to be different. Make sure to handle this case in the window title"

	| wasBlocked |
	wasBlocked := false. 
	(localObject class name asString = remoteClassName
		or: [localObject == NotCachedToken])
			ifTrue: [self printRemoteOn: aStream]
			ifFalse: 
				[self printClientOn: aStream.
				aStream nextPutAll: '; GemStone: ' , self uncachedPrintString.
				wasBlocked := self printRemoteOn: aStream].
	wasBlocked
		ifFalse: 
			[(localObject ~~ NotCachedToken and: 
					[localObject isImmutable
						and: [delegate isReadOnlyObject or: [delegate isSpecial]]])
				ifTrue: [aStream nextPutAll: ' (immutable)']]
]

{ #category : 'printing' }
GbxReplicateInspectionWrapper >> gbxDebugPrintOn: aStream
[
	"defer printString to the wrapped object.

	However, if its the NotCachedToken, then show the delegate printString as that is more interesting and helpful. "

	localObject == NotCachedToken
		ifTrue: [delegate gbxDebugPrintOn: aStream]
		ifFalse: 
			[inspectedObject == delegate
				ifTrue: 
					[delegate printOn: aStream.
					aStream cr.
					aStream nextPutAllText: 'associated with local object: ' asText allBold.
					localObject gbxDebugPrintOn: aStream]
				ifFalse: 
					[localObject gbxDebugPrintOn: aStream.
					aStream cr.
					aStream nextPutAllText: 'associated with delegate: ' asText allBold.
					delegate printOn: aStream]]
]

{ #category : 'printing' }
GbxReplicateInspectionWrapper >> printRemoteOn: aStream
[

	| remotePrintString wasBlocked |
	
	wasBlocked := false.
	remotePrintString := self critical: 
					[remoteClassName isNil
						ifTrue: ['Unretrievable GemStone Object']
						ifFalse: 
							[self objectIsClass
								ifTrue: [remoteClassName copyFrom: 1 to: remoteClassName size - 6]
								ifFalse: 
									[(remoteClassName first isVowel ifTrue: ['an '] ifFalse: ['a '])
										, remoteClassName]]]
				unlessBlocked: 
					[wasBlocked := true.
					'Unretrievable GemStone Object'].
	aStream nextPutAll: remotePrintString.
	^wasBlocked
]

{ #category : 'printing' }
GbxReplicateInspectionWrapper >> printClientOn: aStream 
[
	aStream nextPutAll: 'client: '.
	localObject basicPrintOn: aStream
]

{ #category : 'printing' }
GbxReplicateInspectionWrapper >> printString
[
	"make a TextStream for nice formatting"

	| aStream |
	aStream := GbxLimitingStream on: (TextStream on: (String new: 16)).
	
	[[self gbxDebugPrintOn: aStream] on: GemStone.Gbs.GbsMaxStreamSizeNotification
		do: [:notification | aStream nextPutAll: ' << etc. >>']]
			on: Error
			do: [:err | aStream nextPutAll: '||| Printing error: ' , err description].
	^aStream contents
]

{ #category : 'private - inspecting' }
GbxReplicateInspectionWrapper >> addServerBehaviorInspectorTo: oc
[

	"no action in VW 8.0"
]

{ #category : 'private - inspecting' }
GbxReplicateInspectionWrapper >> inspectorClasses
[

	| oc addBehaviorTab |
	oc := OrderedCollection new.
	addBehaviorTab := false.
	(localObject ~~ NotCachedToken and: [delegate hasLiveSessionFlag])
		ifTrue: 
			[oc addAll: localObject inspectorClasses.
			self addClientBehaviorInspectorTo: oc].
	(delegate hasLiveSessionFlag and: 
			[delegate session
				critical: [[delegate exists] on: Error do: [:ex | ex return: false]]
				unlessBlocked: [false]])
		ifTrue: 
			[oc addAll: self gbxInspectorClasses.
			remoteClass ifNotNil: [addBehaviorTab := true]].
	oc add: GbxDelegateInspector.
	addBehaviorTab
		ifTrue: [self addServerBehaviorInspectorTo: oc].
	oc add: GbxWatchLogInspector.
	^oc
]

{ #category : 'private - inspecting' }
GbxReplicateInspectionWrapper >> inspectables
[

	| oc |
	oc := OrderedCollection new.
	(localObject ~~ NotCachedToken and: [delegate hasLiveSessionFlag])
		ifTrue: 
			[oc
				addAll: ((GbxInspector
						gbxCautiousInspectorClassesFor: localObject)
							collect: [:class | localObject])].
	oc add: self.
	delegate hasLiveSessionFlag
		ifTrue: 
			[remoteClass
				ifNotNil: 
					[4 timesRepeat: [oc add: self]	"the last one is for the GbxBehaviorInspector"]].
	oc add: localObject. "Watch Log"
	^oc asArray
]

{ #category : 'private - inspecting' }
GbxReplicateInspectionWrapper >> inspectableObjectFor: aClass
[

	^self inspectables at: (self inspectorClasses indexOf: aClass)
]

{ #category : 'private - inspecting' }
GbxReplicateInspectionWrapper >> addClientBehaviorInspectorTo: oc
[

	"no action in VW 8.0"
]

{ #category : 'user interface' }
GbxReplicateInspectionWrapper >> inspectorActions
[
	"add fault-on-demand to stubs. Trigger an event to notify interested parties"

	| oc |
	oc := super inspectorActions asOrderedCollection.
	localObject == SpecialGemStoneObjects.NotCachedToken
		ifFalse: 
			[oc add: (GbxAction label: #Stub << #gbs >> 'Become Stub'
						block: 
							[localObject stubYourself.
							self triggerEvent: #objectChanged])].
	^oc asArray
]

