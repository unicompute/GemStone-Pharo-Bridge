Class {
	#name : 'GbsSessionMaterializationRemoteReader',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionMaterializationRemoteReader class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> clearRemoteClassNameCache [
	(session class weakRegistryNamed: #GbsSessionRemoteClassNameCaches)
		at: session
		put: Dictionary new.
	(session class weakRegistryNamed: #GbsSessionRemoteClassNameByClassOopCaches)
		at: session
		put: Dictionary new.
	(session class weakRegistryNamed: #GbsSessionRemoteClassOopCaches)
		at: session
		put: Dictionary new.
	^ self remoteClassNameCache
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseOopPairLine: aString [
	| parts |
	parts := aString asString splitOn: Character tab.
	parts size < 2 ifTrue: [ self error: 'Expected two OOP values.' ].
	^ { parts first asInteger. parts second asInteger }
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseOopPairLines: aString [
	| pairs |
	pairs := OrderedCollection new.
	aString asString lines do: [ :line |
		line isEmpty ifFalse: [ pairs add: (self parseOopPairLine: line) ] ].
	^ pairs asArray
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> oopPairsFromFlatOops: oopArray [
	| pairs |
	oopArray size even ifFalse: [ self error: 'Expected an even number of OOP values.' ].
	pairs := Array new: oopArray size // 2.
	1 to: pairs size do: [ :index |
		pairs
			at: index
			put: {
				oopArray at: (index * 2) - 1.
				oopArray at: index * 2 } ].
	^ pairs
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopAt: anInteger ofOop: anOop [
	^ session
		returnRemoteCommandBody: 'object at: index'
		literalBindings: (Dictionary new
			at: 'index' put: anInteger;
			yourself)
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsForOop: anOop [
	| size |
	size := self remoteSizeForOop: anOop.
	size <= 0 ifTrue: [ ^ #() ].
	^ [ self remoteArrayElementOopsViaGciForOop: anOop size: size ]
		on: Error
		do: [ self remoteArrayElementOopsViaCommandsForOop: anOop size: size ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsViaCommandsForOop: anOop size: size [
	| oops |
	oops := Array new: size.
	1 to: size do: [ :index |
		oops at: index put: (self remoteArrayElementOopAt: index ofOop: anOop) ].
	^ oops
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsViaGciForOop: anOop size: size [
	| buffer fetched oops |
	buffer := ExternalAddress allocate: size * 8.
	[
		fetched := session serverInterface
			apiGciFetchOops: anOop
			startingAt: 1
			into: buffer
			size: size.
		(fetched isCollection and: [ fetched isString not ])
			ifTrue: [ ^ fetched asArray ].
		oops := Array new: size.
		1 to: size do: [ :index |
			oops
				at: index
				put: ((buffer
					integerAt: 1 + ((index - 1) * 8)
					size: 8
					signed: false) asInteger) ].
		^ oops
	] ensure: [ buffer free ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteAssociationOopPairForOop: anOop [
	^ [ self remoteArrayElementOopsForOop: (self remoteAssociationPairOopFor: anOop) ]
		on: Error
		do: [ self parseOopPairLine: (session
		fetchRemoteCommandBody: '| stream |
stream := WriteStream on: String new.
stream
	nextPutAll: assoc key asOop asString;
	nextPut: Character tab;
	nextPutAll: assoc value asOop asString.
stream contents'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'assoc' put: anOop;
			yourself)
		context: 20) ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteAssociationPairOopFor: anOop [
	^ session
		returnRemoteCommandBody: 'Array with: assoc key with: assoc value'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'assoc' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameForOop: anOop [
	^ [ self remoteClassNameForClassOop: (self remoteClassOopForOop: anOop) ]
		on: Error
		do: [ self remoteClassNameForObjectOop: anOop ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameForClassOop: classOop [
	^ self remoteClassNameByClassOopCache
		at: classOop
		ifAbsentPut: [
			session
				fetchRemoteCommandBody: 'classObject name asString'
				literalBindings: Dictionary new
				oopBindings: (Dictionary new
					at: 'classObject' put: classOop;
					yourself)
				context: 20 ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteClassNameByClassOopCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteClassNameByClassOopCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameForObjectOop: anOop [
	^ self remoteClassNameCache
		at: anOop
		ifAbsentPut: [
			session
				fetchRemoteCommandBody: 'object class name asString'
				literalBindings: Dictionary new
				oopBindings: (Dictionary new
					at: 'object' put: anOop;
					yourself)
				context: 20 ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteClassNameCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteClassNameCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteCollectionAsArrayOop: anOop [
	^ session
		returnRemoteCommandBody: 'object asArray'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassOopForOop: anOop [
	^ self remoteClassOopCache
		at: anOop
		ifAbsentPut: [ (session serverInterface apiGciGetClass: anOop) asInteger ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteClassOopCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteClassOopCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationOopPairsForOop: anOop [
	^ [ self oopPairsFromFlatOops: (self
		remoteArrayElementOopsForOop: (self remoteDictionaryAssociationPairsArrayOopFor: anOop)) ]
		on: Error
		do: [
			[ self parseOopPairLines: (session
				fetchRemoteCommandBody: '| stream |
stream := WriteStream on: String new.
object associations do: [ :assoc |
	stream
		nextPutAll: assoc key asOop asString;
		nextPut: Character tab;
		nextPutAll: assoc value asOop asString;
		nextPut: Character lf ].
stream contents'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
				context: 20) ]
				on: Error
				do: [
					| associationOops |
					associationOops := self remoteArrayElementOopsForOop: (self remoteDictionaryAssociationsAsArrayOop: anOop).
					associationOops collect: [ :each | self remoteAssociationOopPairForOop: each ] ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationPairsArrayOopFor: anOop [
	^ session
		returnRemoteCommandBody: '| pairs index |
pairs := Array new: object size * 2.
index := 1.
object associations do: [ :assoc |
	pairs at: index put: assoc key.
	pairs at: index + 1 put: assoc value.
	index := index + 2 ].
pairs'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationsAsArrayOop: anOop [
	^ session
		returnRemoteCommandBody: 'object associations asArray'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteSizeForOop: anOop [
	^ [ (session serverInterface apiGciFetchSize: anOop) asInteger ] on: Error do: [
		session fetchRemoteCommand: (GbsRemoteCommand
			blockBody: 'object size'
			oopBindings: (Dictionary new
				at: 'object' put: anOop;
				yourself)) ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteStringValueForOop: anOop [
	^ session
		fetchRemoteCommandBody: 'object asString'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
		context: 20
]

{ #category : 'accessing' }
GbsSessionMaterializationRemoteReader >> session [
	^ session
]

{ #category : 'accessing' }
GbsSessionMaterializationRemoteReader >> session: aSession [
	session := aSession
]
