Class {
	#name : 'GbsRcHash',
	#superclass : 'GbsMaglevRuntimeProxy',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'querying' }
GbsRcHash >> at: aKey [
	^ self
		at: aKey
		ifAbsent: [ self error: aKey printString , ' not present in RCHash' ]
]

{ #category : 'querying' }
GbsRcHash >> at: aKey ifAbsent: aBlock [
	| result |
	result := self executeAgainstRemote: '((obj respondsTo: #at:otherwise:)
		ifTrue: [ obj at: ', (session marshalArgumentToScript: aKey), ' otherwise: nil ]
		ifFalse: [ (obj respondsTo: #at:ifAbsent:)
			ifTrue: [ obj at: ', (session marshalArgumentToScript: aKey), ' ifAbsent: [ nil ] ]
			ifFalse: [ nil ] ])'.
	^ result
		ifNil: [ aBlock value ]
		ifNotNil: [ session materializeMaglevRuntimeValue: result ]
]

{ #category : 'mutating' }
GbsRcHash >> at: aKey put: aValue [
	| result |
	result := self executeAgainstRemote: 'obj at: ', (session marshalArgumentToScript: aKey), ' put: ', (session marshalArgumentToScript: aValue), '. obj at: ', (session marshalArgumentToScript: aKey).
	^ session materializeMaglevRuntimeValue: result
]

{ #category : 'querying' }
GbsRcHash >> associations [
	| associations |
	associations := self executeAgainstRemote: '| items |
	items := OrderedCollection new.
	(obj respondsTo: #keysAndValuesDo:)
		ifTrue: [ obj keysAndValuesDo: [ :key :value | items add: (key -> value) ] ].
	items asArray'.
	associations ifNil: [ ^ #() ].
	^ associations collect: [ :each |
		each key -> (session materializeMaglevRuntimeValue: each value) ]
]

{ #category : 'querying' }
GbsRcHash >> includesKey: aKey [
	^ (self at: aKey ifAbsent: [ nil ]) notNil
]

{ #category : 'querying' }
GbsRcHash >> isEmpty [
	^ self size = 0
]

{ #category : 'querying' }
GbsRcHash >> keys [
	| keys |
	keys := self executeAgainstRemote: '| items |
	items := OrderedCollection new.
	(obj respondsTo: #keysAndValuesDo:)
		ifTrue: [ obj keysAndValuesDo: [ :key :value | items add: key ] ].
	items asArray'.
	^ keys ifNil: [ #() ] ifNotNil: [ keys ]
]

{ #category : 'mutating' }
GbsRcHash >> removeKey: aKey [
	^ self
		removeKey: aKey
		ifAbsent: [ self error: aKey printString , ' not present in RCHash' ]
]

{ #category : 'mutating' }
GbsRcHash >> removeKey: aKey ifAbsent: aBlock [
	| marker result |
	marker := '__gbs_missing__'.
	result := self executeAgainstRemote: '((obj respondsTo: #removeKey:ifAbsent:)
		ifTrue: [ obj removeKey: ', (session marshalArgumentToScript: aKey), ' ifAbsent: [ ', marker storeString, ' ] ]
		ifFalse: [ ', marker storeString, ' ])'.
	result = marker ifTrue: [ ^ aBlock value ].
	^ session materializeMaglevRuntimeValue: result
]

{ #category : 'querying' }
GbsRcHash >> size [
	^ self executeAgainstRemote: 'obj size'
]

{ #category : 'querying' }
GbsRcHash >> values [
	^ self associations collect: [ :each | each value ]
]
