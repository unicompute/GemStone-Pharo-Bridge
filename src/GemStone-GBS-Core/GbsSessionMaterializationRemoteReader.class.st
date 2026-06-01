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
	(session class weakRegistryNamed: #GbsSessionRemoteSizeCaches)
		at: session
		put: Dictionary new.
	(session class weakRegistryNamed: #GbsSessionRemoteArrayElementOopsCaches)
		at: session
		put: Dictionary new.
	(session class weakRegistryNamed: #GbsSessionRemoteDictionaryAssociationOopPairCaches)
		at: session
		put: Dictionary new.
	^ self remoteClassNameCache
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> batchesForOops: oopCollection [
	| batches batch batchSize |
	batchSize := self materializationBatchSize.
	batches := OrderedCollection new.
	batch := OrderedCollection new.
	oopCollection do: [ :oop |
		batch add: oop.
		batch size >= batchSize ifTrue: [
			batches add: batch asArray.
			batch := OrderedCollection new ] ].
	batch isEmpty ifFalse: [ batches add: batch asArray ].
	^ batches asArray
]

{ #category : 'metrics' }
GbsSessionMaterializationRemoteReader >> incrementMaterializationMetric: aSymbol [
	^ session materializer incrementMaterializationMetric: aSymbol
]

{ #category : 'metrics' }
GbsSessionMaterializationRemoteReader >> incrementMaterializationMetric: aSymbol by: anInteger [
	^ session materializer incrementMaterializationMetric: aSymbol by: anInteger
]

{ #category : 'metrics' }
GbsSessionMaterializationRemoteReader >> materializationBatchSize [
	^ [ session materializationBatchSize ]
		on: Error
		do: [ 1000 ]
]

{ #category : 'metrics' }
GbsSessionMaterializationRemoteReader >> recordMillisecondsForMetric: aSymbol during: aBlock [
	^ session materializer
		recordMillisecondsForMetric: aSymbol
		during: aBlock
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
GbsSessionMaterializationRemoteReader >> parseClassNameLines: aString [
	| classNames |
	classNames := Dictionary new.
	aString asString lines do: [ :line |
		line isEmpty ifFalse: [
			| parts |
			parts := line asString splitOn: Character tab.
			parts size < 2 ifTrue: [ self error: 'Expected an OOP and class name.' ].
			classNames at: parts first asInteger put: parts second asString ] ].
	^ classNames
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
	self incrementMaterializationMetric: #slotCommandCalls.
	^ self
		recordMillisecondsForMetric: #slotFetchMs
		during: [
			session
				returnRemoteCommandBody: 'object at: index'
				literalBindings: (Dictionary new
					at: 'index' put: anInteger;
					yourself)
				oopBindings: (Dictionary new
					at: 'object' put: anOop;
					yourself) ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsForOop: anOop [
	^ self remoteArrayElementOopsCache
		at: anOop
		ifAbsentPut: [
			| size |
			size := self remoteSizeForOop: anOop.
			size <= 0
				ifTrue: [ #() ]
				ifFalse: [
					[ self remoteArrayElementOopsViaGciForOop: anOop size: size ]
						on: Error
						do: [ self remoteArrayElementOopsViaCommandsForOop: anOop size: size ] ] ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteArrayElementOopsCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsViaCommandsForOop: anOop size: size [
	| oops |
	self incrementMaterializationMetric: #slotFallbackCalls.
	oops := Array new: size.
	1 to: size do: [ :index |
		oops at: index put: (self remoteArrayElementOopAt: index ofOop: anOop) ].
	^ oops
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsViaGciForOop: anOop size: size [
	| buffer fetched oops |
	self incrementMaterializationMetric: #slotBatchCalls.
	self incrementMaterializationMetric: #slotBatchOopCount by: size.
	buffer := ExternalAddress allocate: size * 8.
	^ [
		self
			recordMillisecondsForMetric: #slotFetchMs
			during: [
				fetched := session serverInterface
					apiGciFetchOops: anOop
					startingAt: 1
					into: buffer
					size: size.
				(fetched isCollection and: [ fetched isString not ])
					ifTrue: [ fetched asArray ]
					ifFalse: [
						oops := Array new: size.
						1 to: size do: [ :index |
							oops
								at: index
								put: ((buffer
									integerAt: 1 + ((index - 1) * 8)
									size: 8
									signed: false) asInteger) ].
						oops ] ]
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
			self incrementMaterializationMetric: #classNameByClassOopCalls.
			self
				recordMillisecondsForMetric: #classNameByClassOopMs
				during: [
					session
						fetchRemoteCommandBody: 'classObject name asString'
						literalBindings: Dictionary new
						oopBindings: (Dictionary new
							at: 'classObject' put: classOop;
							yourself)
						context: 20 ] ]
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
			self incrementMaterializationMetric: #classNameObjectCalls.
			self
				recordMillisecondsForMetric: #classNameObjectMs
				during: [
					session
						fetchRemoteCommandBody: 'object class name asString'
						literalBindings: Dictionary new
						oopBindings: (Dictionary new
							at: 'object' put: anOop;
							yourself)
							context: 20 ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameDictionaryForOops: oopCollection [
	self incrementMaterializationMetric: #classNameBatchCalls.
	self incrementMaterializationMetric: #classNameBatchOopCount by: oopCollection size.
	^ self
		recordMillisecondsForMetric: #classNameBatchMs
		during: [
			self parseClassNameLines: (session
				fetchRemoteCommandBody: '| stream object |
stream := WriteStream on: String new.
oops do: [ :oop |
	object := Object _objectForOop: oop.
	stream
		nextPutAll: oop asString;
		nextPut: Character tab;
		nextPutAll: object class name asString;
		nextPut: Character lf ].
stream contents'
				literalBindings: (Dictionary new
					at: 'oops' put: oopCollection asArray;
					yourself)
				oopBindings: Dictionary new
				context: 20) ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNamesForOops: oopCollection [
	| result cache missing batches |
	result := Dictionary new.
	cache := self remoteClassNameCache.
	missing := OrderedCollection new.
	oopCollection do: [ :oop |
		(cache includesKey: oop)
			ifTrue: [ result at: oop put: (cache at: oop) ]
			ifFalse: [
				(missing includes: oop) ifFalse: [
					missing add: oop ] ] ].
	missing isEmpty ifTrue: [ ^ result ].
	batches := self batchesForOops: missing.
	batches do: [ :batch |
		| fetched |
		fetched := [ self remoteClassNameDictionaryForOops: batch ]
			on: Error
			do: [
				self incrementMaterializationMetric: #classNameBatchFallbacks.
				nil ].
		fetched
			ifNil: [
				self incrementMaterializationMetric: #classNameFallbackCalls by: batch size.
				batch do: [ :oop |
					result at: oop put: (self remoteClassNameForOop: oop) ] ]
			ifNotNil: [
				batch do: [ :oop |
					| className |
					className := fetched
						at: oop
						ifAbsent: [
							self incrementMaterializationMetric: #classNameFallbackCalls.
							self remoteClassNameForOop: oop ].
					cache at: oop put: className.
					result at: oop put: className ] ] ].
	^ result
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
		ifAbsentPut: [
			self incrementMaterializationMetric: #classOopCalls.
			self
				recordMillisecondsForMetric: #classOopMs
				during: [ (session serverInterface apiGciGetClass: anOop) asInteger ] ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteClassOopCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteClassOopCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationOopPairsForOop: anOop [
	^ self remoteDictionaryAssociationOopPairCache
		at: anOop
		ifAbsentPut: [
			[ self oopPairsFromFlatOops: (self
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
						associationOops collect: [ :each | self remoteAssociationOopPairForOop: each ] ] ] ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationOopPairCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteDictionaryAssociationOopPairCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
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
	^ self remoteSizeCache
		at: anOop
		ifAbsentPut: [
			self incrementMaterializationMetric: #sizeFetchCalls.
			self
				recordMillisecondsForMetric: #sizeFetchMs
				during: [
					[ (session serverInterface apiGciFetchSize: anOop) asInteger ] on: Error do: [
						session fetchRemoteCommand: (GbsRemoteCommand
							blockBody: 'object size'
							oopBindings: (Dictionary new
								at: 'object' put: anOop;
								yourself)) ] ] ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteSizeCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteSizeCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
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
