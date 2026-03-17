Class {
	#name : 'GbxPointerStub',
	#superclass : 'GbxObjectStub',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxPointerStub class >> stubObject: anObject forDelegate: delegate freeSlots: freeSlots
[
	"Turn anObject into a stub using changeClass, not become:.  ChangeClass is quicker than become: and does not require copying any translucent instvars."
	"Sender must hold delegate's session's sessionProtect."

	| replicator |
	anObject gbxAssertImmutable.
	GbsConfiguration current stubDebugging
		ifTrue: 
			[self gbsMessenger comment: 'Stubbing %1 with: %2.' with: anObject with: self].
	replicator := delegate session replicatorForClient: anObject
				ifAbsent: 
					[self gbsMessenger
						error: 'Attempt to stub a replicate whose class has no replicator.'].
	self changeObjectToStub: anObject.
	"If in persistent-slot nilling mode, nil out all persistent instVars"
	freeSlots ifTrue: [replicator nilMappedSlotsOf: anObject].
	delegate stubbing
]

