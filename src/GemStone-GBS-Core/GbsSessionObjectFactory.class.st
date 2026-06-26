"
Creates server objects for a GbsSession from a free OOP (the VisualWorks
createObjectClass:values:... family), extracted from GbsSession to keep the session
extension within its size budget. Follows the same coordinator pattern as
GbsSessionCommandExecutor / GbsSessionTransactionCoordinator: an Object holding the
session, constructed with `on:`, delegating session primitives (serverInterface,
getFreeOop, proxyForOop:, unsignedOopForSignedOop:) back to the session.
"
Class {
	#name : 'GbsSessionObjectFactory',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionObjectFactory class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbsSessionObjectFactory >> session [
	^ session
]

{ #category : 'accessing' }
GbsSessionObjectFactory >> session: aSession [
	session := aSession
]

{ #category : 'creating' }
GbsSessionObjectFactory >> createObjectClass: aClassNameOrBehaviorOrOop values: values [
	"VW-compatible object creation from a free OOP. Creates a server object of the given class with the
	given values, using the default cluster bucket and temporary (non-permanent) space. Answers a proxy
	to the new server object. See createObjectClass:values:clusterBucket:permanent: for full semantics."
	^ self
		createObjectClass: aClassNameOrBehaviorOrOop
		values: values
		clusterBucket: 0
		permanent: false
]

{ #category : 'creating' }
GbsSessionObjectFactory >> createObjectClass: aClassNameOrBehaviorOrOop values: values clusterBucket: clusterBucket permanent: makePermanent [
	"VW-compatible object creation from a free OOP (GbsSession/Delegate>>createObjectClass:values:...).
	Allocates a fresh server object identifier with GciGetFreeOop, then creates the object via
	GciCreateOopObj (pointer/Nsc classes) or GciCreateByteObj (byte classes). values is either a Smalltalk
	byte object (for byte-format classes) or a collection of values for pointer/Nsc classes; pointer values
	may be proxies, already-mapped replicates, immediates, or forward references to other free OOPs.
	Answers a proxy to the newly created server object, which is added to the export set by GciCreate."
	| serverInterface classOop objId resultOop |
	serverInterface := session serverInterface.
	serverInterface ifNil: [ session error: 'No server interface is available for object creation.' ].
	(serverInterface supportsObjectCreationTransport) ifFalse: [
		GbsError signal: 'GCI object-creation transport is not available for this session.' ].
	classOop := self serverClassOopForObjectCreation: aClassNameOrBehaviorOrOop.
	classOop ifNil: [
		GbsError signal: 'Cannot create object: no server class OOP resolved for ', aClassNameOrBehaviorOrOop printString, '.' ].
	objId := session getFreeOop.
	(values isKindOf: ByteArray) ifTrue: [
		resultOop := serverInterface
			createByteObjectOfClass: classOop
			objId: objId
			bytes: values
			clusterId: clusterBucket
			permanent: makePermanent.
		^ session proxyForOop: resultOop ].
	resultOop := serverInterface
		createOopObjectOfClass: classOop
		objId: objId
		oopValues: (values collect: [ :each | self serverOopForCreationValue: each ])
		clusterId: clusterBucket
		permanent: makePermanent.
	^ session proxyForOop: resultOop
]

{ #category : 'creating' }
GbsSessionObjectFactory >> serverClassOopForObjectCreation: aClassNameOrBehaviorOrOop [
	"Resolve a class name, behavior, proxy, or OOP to an unsigned server class OOP for object creation."
	| name |
	aClassNameOrBehaviorOrOop ifNil: [ ^ nil ].
	aClassNameOrBehaviorOrOop isInteger ifTrue: [ ^ aClassNameOrBehaviorOrOop ].
	((aClassNameOrBehaviorOrOop respondsTo: #oop) and: [ aClassNameOrBehaviorOrOop oop notNil ]) ifTrue: [
		^ aClassNameOrBehaviorOrOop oop ].
	name := ((aClassNameOrBehaviorOrOop isString) or: [ aClassNameOrBehaviorOrOop isSymbol ])
		ifTrue: [ aClassNameOrBehaviorOrOop asString ]
		ifFalse: [
			((aClassNameOrBehaviorOrOop isKindOf: Behavior)
				or: [ (aClassNameOrBehaviorOrOop respondsTo: #isBehavior) and: [ aClassNameOrBehaviorOrOop isBehavior ] ])
				ifTrue: [ aClassNameOrBehaviorOrOop name asString ]
				ifFalse: [ aClassNameOrBehaviorOrOop asString ] ].
	^ (GbsDirtyReplicateStoreTraversal forSession: session) classOopForServerBehavior: name
]

{ #category : 'creating' }
GbsSessionObjectFactory >> serverOopForCreationValue: aValue [
	"Map a client value to an unsigned server OOP suitable as a GciCreateOopObj slot value. Handles nil,
	booleans, SmallIntegers, Characters, proxies/replicates already mapped to OOPs, and scalar (String/
	Symbol) values via native scalar OOP resolution. Forward references to other newly allocated free OOPs
	are honored because such objects are registered with the materialized-object tracker."
	| oop |
	aValue isNil ifTrue: [ ^ 20 ].
	aValue == true ifTrue: [ ^ 268 ].
	aValue == false ifTrue: [ ^ 12 ].
	(aValue isInteger and: [ aValue between: -1152921504606846976 and: 1152921504606846975 ]) ifTrue: [
		^ session unsignedOopForSignedOop: (aValue bitShift: 3) + 2 ].
	(aValue isCharacter) ifTrue: [
		^ session unsignedOopForSignedOop: (aValue codePoint bitShift: 3) + 6 ].
	oop := [ GbsMaterializedObjectDirtyTracker oopForObject: aValue inSession: session ] on: Error do: [ nil ].
	oop ifNotNil: [ ^ oop ].
	((aValue respondsTo: #oop) and: [ aValue oop notNil ]) ifTrue: [ ^ aValue oop ].
	(aValue isString or: [ aValue isSymbol ]) ifTrue: [
		oop := self scalarServerOopForCreationValue: aValue.
		oop ifNotNil: [ ^ oop ] ].
	GbsError signal: 'Cannot create object: value ', aValue printString, ' cannot be resolved to a server OOP.'
]

{ #category : 'creating' }
GbsSessionObjectFactory >> scalarServerOopForCreationValue: aValue [
	"Resolve a String/Symbol value to a server OOP via the native GCI scalar-resolution path used by the
	dirty-store traversal buffer."
	| serverInterface oop |
	serverInterface := session serverInterface.
	((serverInterface respondsTo: #supportsNativeScalarOopResolution)
		and: [ serverInterface supportsNativeScalarOopResolution ]) ifFalse: [ ^ nil ].
	oop := [
		aValue isSymbol
			ifTrue: [ serverInterface apiGciNewSymbol: aValue asString ]
			ifFalse: [ serverInterface apiGciNewString: aValue asString ] ]
		on: Error
		do: [ ^ nil ].
	((oop isNil) or: [ oop asInteger = 1 ]) ifTrue: [ ^ nil ].
	^ session unsignedOopForSignedOop: oop asInteger
]
