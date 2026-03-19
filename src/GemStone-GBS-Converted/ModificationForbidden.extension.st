Extension { #name : #'ModificationForbidden' }

{ #category : '*GemStone-GBS-Converted-signaling' }
ModificationForbidden >> raiseRequest [
	"Overridden by GemStone Systems, Inc to support automatic mark dirty"

	"CS: fix for become isImmutable flag handling"

	| slot |
	fieldIndex isNil 
		ifTrue: 
			[^(#(#primBecome: #becomeNoRetry:) includes: retrySelector) 
				ifTrue: [self gbxHandleAttemptedBecome]
				ifFalse: 
					["Likely one of #(changeClassTo: changeClassToThatOf:)"

					self gbxHandleAttemptedClassChange]].
	slot := retrySelector == #instVarAt:put: 
				ifTrue: [fieldIndex]
				ifFalse: [fieldIndex + self object gbxBasicClass instSize].
	"Otherwise #at:put: or #basicAt:put:"
	^self gbxIsIdenticalAssignment 
		ifTrue: [newValue]
		ifFalse: 
			[self object 
				gbxMutationAt: slot
				value: newValue
				noModError: self]
]

{ #category : '*GemStone-GBS-Converted-signalling' }
ModificationForbidden >> raiseSignal [
	"Overridden by GemStone Systems, Inc to support automatic mark dirty"

	^self raiseRequest
]

{ #category : '*GemStone-GBS-Converted-GBS-private-additions' }
ModificationForbidden >> gbxHandleAttemptedClassChange [
	"If allowable, mark the object dirty so the class change propagates to the server."

	| delegate response |
	((delegate := self object gbxDelegate) isNil or: [delegate isReadOnlyObject])
		ifTrue: [^super raiseRequest].
	delegate serverCanAcceptClassChanges ifTrue: [self object markDirty].
	
	[self object gbxIsImmutable: false.
	response := self retryModification.
	"response in this case should always be the same as self object"
	response gbxIsImmutable: true]
			valueUnpreemptively.
	^response
]

{ #category : '*GemStone-GBS-Converted-GBS-private-additions' }
ModificationForbidden >> gbxReallyRaiseRequest [
	"Unconditionally raise the request."

	^super raiseRequest
]

{ #category : '*GemStone-GBS-Converted-GBS-private-additions' }
ModificationForbidden >> gbxHandleAttemptedBecome [
	"If allowed, make the change and mark both receiver and argument dirty so change gets propagated to the server."

	| recWas argWas delegate response argument |
	argument := self newValue.
	recWas := self object gbxIsImmutable.
	argWas := argument gbxIsImmutable.
	((recWas and: 
			[(delegate := self object gbxDelegate) isNil or: [delegate isReadOnlyObject]])
		or: 
			[argWas
				and: [(delegate := argument gbxDelegate) isNil or: [delegate isReadOnlyObject]]])
			ifTrue: [^super raiseRequest].
	"Mark both dirty so change is propagated to the server."
	delegate serverCanAcceptClassChanges
		ifTrue: 
			[self object markDirty.
			argument markDirty].
	
	[self object gbxIsImmutable: false.
	argument gbxIsImmutable: false.
	response := self retryModification.
	"Receiver and argument are now swapped."
	self object gbxIsImmutable: recWas.
	argument gbxIsImmutable: argWas]
			valueUnpreemptively.
	^response
]

{ #category : '*GemStone-GBS-Converted-GBS-private-additions' }
ModificationForbidden >> gbxIsIdenticalAssignment [
	"Answer true if the proposed modification actually makes no change to the object, false otherwise.
	Only good for at:put: and instvarAt:put:."

	fieldIndex isNil ifTrue: [ ^ false ].
	retrySelector == #instVarAt:put:
		ifTrue: [ ^ newValue == (self object instVarAt: fieldIndex) ].
	retrySelector == #basicAt:put:
		ifTrue: [ ^ newValue == (self object basicAt: fieldIndex) ].
	^ newValue == (self object at: fieldIndex)
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ModificationForbidden class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ModificationForbidden class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ModificationForbidden class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ModificationForbidden >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ModificationForbidden >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ModificationForbidden >> isRunningUnderAssertingVM [
	^false
]
