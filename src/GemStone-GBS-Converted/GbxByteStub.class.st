Class {
	#name : #'GbxByteStub',
	#superclass : #'GbxObjectStub',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'Object kernel methods' }
GbxByteStub >> isBehavior
	"Return false because we know byte stubs are not behaviors."

	^false

{ #category : #'instance creation' }
GbxByteStub class >> stubObject: anObject forDelegate: delegate freeSlots: freeSlots
	"Turn anObject into a stub. AnObject should be a byte object.
	It should be a clean replicate, and therefore marked immutable if autoMarkDirty.
	Answer anObject, which has become a stub."
	"Sender must hold delegate's session's sessionProtect."

	| stub |
	anObject gbxAssertImmutable.	"Only checks if autoMarkDirty"
	[anObject gbxDelegate] gbxAssertEquals: delegate.
	GbsConfiguration current stubDebugging
		ifTrue: 
			[self gbsMessenger comment: 'Stubbing %1 with %2.' with: anObject with: self].
	stub := self new: 0.
	anObject gbxIsImmutable: true.	"Must be immutable for stub to be immutable after become"
	"Make the object immutable before the become so there is no moment when the object 
	could be modified by another thread."
	anObject gbxBecome: stub.
	delegate stubbing

