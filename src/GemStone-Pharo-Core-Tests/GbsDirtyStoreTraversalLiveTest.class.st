Class {
	#name : 'GbsDirtyStoreTraversalLiveTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'integration tests' }
GbsDirtyStoreTraversalLiveTest >> testNativeDirtyStoreTraversalFlushesMappedArray [
	| support session policy previousTransport previousProfile arrayOop array flushed verified |
	support := self liveSessionSupportClass.
	session := support ensureSharedSession.
	session ifNil: [
		self skip: support unavailableReason ].
	(session serverInterface supportsDirtyStoreTraversalBufferTransport) ifFalse: [
		self skip: 'GemStone server interface does not expose dirty store traversal buffer transport.' ].

	policy := GbsReplicationPolicy forSession: session.
	previousTransport := policy storeTraversalTransport.
	previousProfile := session fetchProfile.
	[
		session abortTransaction.
		[ session checkForError ] on: Error do: [ ].
		session resetMaterializedObjectDirtyTracking.
		session fetchDeep.
		arrayOop := session executeScriptAndReturnOop: '{ 1 . 2 . nil }'.
		self assert: arrayOop > 20.

		array := session fetchObject: arrayOop.
		self assert: array first equals: 1.
		self assert: array second equals: 2.
		self assert: array third isNil.

		policy storeTraversalTransport: 'binaryRequired'.
		array
			at: 2 put: 42;
			at: 3 put: true.
		self assert: (session dirtyMaterializedObjectOops includes: arrayOop).

		flushed := session flushDirtyMaterializedObjects.
		self assert: flushed asArray equals: { arrayOop }.
		self assert: session dirtyMaterializedObjectOops isEmpty.

		verified := session fetchRemoteCommand: (GbsRemoteCommand
			blockBody: '((object at: 1) = 1) and: [ ((object at: 2) = 42) and: [ (object at: 3) = true ] ]'
			literalBindings: Dictionary new
			oopBindings: (Dictionary new
				at: 'object' put: arrayOop;
				yourself)).
		self assert: verified ]
		ensure: [
			policy storeTraversalTransport: previousTransport.
			session fetchProfile: previousProfile.
			[ session resetMaterializedObjectDirtyTracking ] on: Error do: [ ].
			[ session abortTransaction ] on: Error do: [ ] ]
]

{ #category : 'integration tests' }
GbsDirtyStoreTraversalLiveTest >> testNativeDirtyStoreTraversalFlushesMappedAssociation [
	| support session policy previousTransport previousProfile associationOop association flushed verified |
	support := self liveSessionSupportClass.
	session := support ensureSharedSession.
	session ifNil: [
		self skip: support unavailableReason ].
	(session serverInterface supportsDirtyStoreTraversalBufferTransport) ifFalse: [
		self skip: 'GemStone server interface does not expose dirty store traversal buffer transport.' ].

	policy := GbsReplicationPolicy forSession: session.
	previousTransport := policy storeTraversalTransport.
	previousProfile := session fetchProfile.
	[
		session abortTransaction.
		[ session checkForError ] on: Error do: [ ].
		session resetMaterializedObjectDirtyTracking.
		session fetchDeep.
		associationOop := session executeScriptAndReturnOop: '(Association key: 1 value: 2)'.
		self assert: associationOop > 20.

		association := session fetchObject: associationOop.
		self assert: association key equals: 1.
		self assert: association value equals: 2.

		policy storeTraversalTransport: 'binaryRequired'.
		association value: 77.
		self assert: (session dirtyMaterializedObjectOops includes: associationOop).

		flushed := session flushDirtyMaterializedObjects.
		self assert: flushed asArray equals: { associationOop }.
		self assert: session dirtyMaterializedObjectOops isEmpty.

		verified := session fetchRemoteCommand: (GbsRemoteCommand
			blockBody: '((object key) = 1) and: [ (object value) = 77 ]'
			literalBindings: Dictionary new
			oopBindings: (Dictionary new
				at: 'object' put: associationOop;
				yourself)).
		self assert: verified ]
		ensure: [
			policy storeTraversalTransport: previousTransport.
			session fetchProfile: previousProfile.
			[ session resetMaterializedObjectDirtyTracking ] on: Error do: [ ].
			[ session abortTransaction ] on: Error do: [ ] ]
]

{ #category : 'integration tests' }
GbsDirtyStoreTraversalLiveTest >> testNativeDirtyStoreTraversalFlushesMappedOrderedCollection [
	| support session policy previousTransport previousProfile orderedOop ordered flushed verified |
	support := self liveSessionSupportClass.
	session := support ensureSharedSession.
	session ifNil: [
		self skip: support unavailableReason ].
	(session serverInterface supportsDirtyStoreTraversalBufferTransport) ifFalse: [
		self skip: 'GemStone server interface does not expose dirty store traversal buffer transport.' ].

	policy := GbsReplicationPolicy forSession: session.
	previousTransport := policy storeTraversalTransport.
	previousProfile := session fetchProfile.
	[
		session abortTransaction.
		[ session checkForError ] on: Error do: [ ].
		session resetMaterializedObjectDirtyTracking.
		session fetchDeep.
		orderedOop := session executeScriptAndReturnOop: '(OrderedCollection new add: 1; add: 2; yourself)'.
		self assert: orderedOop > 20.

		ordered := session fetchObject: orderedOop.
		self assert: ordered asArray equals: #(1 2).

		policy storeTraversalTransport: 'binaryRequired'.
		ordered add: 3.
		self assert: (session dirtyMaterializedObjectOops includes: orderedOop).

		flushed := session flushDirtyMaterializedObjects.
		self assert: flushed asArray equals: { orderedOop }.
		self assert: session dirtyMaterializedObjectOops isEmpty.

		verified := session fetchRemoteCommand: (GbsRemoteCommand
			blockBody: 'object asArray = #(1 2 3)'
			literalBindings: Dictionary new
			oopBindings: (Dictionary new
				at: 'object' put: orderedOop;
				yourself)).
		self assert: verified ]
		ensure: [
			policy storeTraversalTransport: previousTransport.
			session fetchProfile: previousProfile.
			[ session resetMaterializedObjectDirtyTracking ] on: Error do: [ ].
			[ session abortTransaction ] on: Error do: [ ] ]
]

{ #category : 'private' }
GbsDirtyStoreTraversalLiveTest >> liveSessionSupportClass [
	^ Smalltalk
		at: #GbsLiveSessionTestSupport
		ifAbsent: [ Smalltalk at: #CoreGbsLiveSessionTestSupport ]
]
