Class {
	#name : 'GbxKeyValueFaulter',
	#superclass : 'Object',
	#instVars : [
		'dictionary',
		'lastKey',
		'lastKeySlot',
		'lastValue',
		'lastValueSlot',
		'deferredKeys',
		'deferredValues'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'initialization' }
GbxKeyValueFaulter >> dictionary: aDict

	deferredKeys := Dictionary new.
	deferredValues := Dictionary new.
	dictionary := aDict

{ #category : 'replication' }
GbxKeyValueFaulter >> indexableValueAt: index put: anObj

	"This message is sent by replication.  If this is an odd slot, it's a key for the dictionary.
	 If it's an even slot, it's a value for the dictionary that corresponds with the key supplied
	 with the previous index."

	index odd
		ifTrue: [ self incomingKey: anObj assocIndex: (index // 2) + 1 ]
		ifFalse: [ self incomingValue: anObj assocIndex: (index // 2) ]

{ #category : 'private' }
GbxKeyValueFaulter >> incomingKey: incomingKey assocIndex: assocIndex

	| deferredValue |
	lastValueSlot = assocIndex ifTrue: [
		dictionary at: incomingKey put: lastValue.
		lastValue := lastValueSlot := nil.
		^self.
	].
	(deferredValue := deferredValues removeKey: assocIndex ifAbsent: []) isNil ifFalse: [
		dictionary at: incomingKey put: deferredValue.
		^self.
	].
	lastKeySlot isNil ifFalse: [
		deferredKeys at: lastKeySlot put: lastKey.
	].
	lastKey := incomingKey.
	lastKeySlot := assocIndex.

{ #category : 'private' }
GbxKeyValueFaulter >> incomingValue: incomingValue assocIndex: assocIndex

	| deferredKey |
	lastKeySlot = assocIndex ifTrue: [
		dictionary at: lastKey put: incomingValue.
		lastKey := lastKeySlot := nil.
		^self.
	].
	(deferredKey := deferredKeys removeKey: assocIndex ifAbsent: []) isNil ifFalse: [
		dictionary at: deferredKey put: incomingValue.
		^self.
	].
	lastValueSlot isNil ifFalse: [
		deferredValues at: lastValueSlot put: lastValue.
	].
	lastValue := incomingValue.
	lastValueSlot := assocIndex.

{ #category : 'instance creation' }
GbxKeyValueFaulter class >> for: aDictionary 
	^self new dictionary: aDictionary

