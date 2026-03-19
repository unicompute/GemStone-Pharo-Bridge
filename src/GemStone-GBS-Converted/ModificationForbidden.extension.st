Extension { #name : #'ModificationForbidden' }

{ #category : '*GemStone-GBS-Converted-signaling' }
ModificationForbidden >> raiseRequest [
	"Overridden by GemStone Systems, Inc to support automatic mark dirty"

	"CS: fix for become isImmutable flag handling"

	| slot |
	index isNil 
		ifTrue: 
			[^(#(#primBecome: #becomeNoRetry:) includes: selector) 
				ifTrue: [self gbxHandleAttemptedBecome]
				ifFalse: 
					["Likely one of #(changeClassTo: changeClassToThatOf:)"

					self gbxHandleAttemptedClassChange]].
	slot := selector == #instVarAt:put: 
				ifTrue: [index]
				ifFalse: [index + self object gbxBasicClass instSize].
	"Otherwise #at:put: or #basicAt:put:"
	^self gbxIsIdenticalAssignment 
		ifTrue: [value]
		ifFalse: 
			[self object 
				gbxMutationAt: slot
				value: value
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
	((delegate := parameter gbxDelegate) isNil or: [delegate isReadOnlyObject])
		ifTrue: [^super raiseRequest].
	delegate serverCanAcceptClassChanges ifTrue: [parameter markDirty].
	
	[parameter gbxIsImmutable: false.
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

	| recWas argWas delegate response |
	recWas := parameter gbxIsImmutable.
	argWas := value gbxIsImmutable.
	((recWas and: 
			[(delegate := parameter gbxDelegate) isNil or: [delegate isReadOnlyObject]])
		or: 
			[argWas
				and: [(delegate := value gbxDelegate) isNil or: [delegate isReadOnlyObject]]])
			ifTrue: [^super raiseRequest].
	"Mark both dirty so change is propagated to the server."
	delegate serverCanAcceptClassChanges
		ifTrue: 
			[parameter markDirty.
			value markDirty].
	
	[self object gbxIsImmutable: false.
	value gbxIsImmutable: false.
	response := self retryModification.
	"Receiver and argument are now swapped."
	self object gbxIsImmutable: recWas.
	value gbxIsImmutable: argWas]
			valueUnpreemptively.
	^response
]

{ #category : '*GemStone-GBS-Converted-GBS-private-additions' }
ModificationForbidden >> gbxIsIdenticalAssignment [
	"Answer true if the proposed modification actually makes no change to the object, false otherwise.
	Only good for at:put: and instvarAt:put:."

	^value == self currentValue
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
