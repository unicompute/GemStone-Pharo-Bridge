Class {
	#name : 'GbxReceiverInspector',
	#superclass : 'GbxContextInspector',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxReceiverInspector class >> openOn: anObject service: aService [
	| inspector |
	inspector := self new.
	inspector
		object: anObject;
		service: aService.
	inspector inspect.
	^ inspector
]

{ #category : 'field list' }
GbxReceiverInspector >> fieldList [
	^ #('self' 'self oop')
]

{ #category : 'field list' }
GbxReceiverInspector >> fieldValueAtName: aName [
	aName = 'self' ifTrue: [
		^ [ object receiverClassOrUnknown asString ] on: Error do: [ '<unknown>' ]
	].
	aName = 'self oop' ifTrue: [
		^ [ object selfOop asString ] on: Error do: [ 'nil' ]
	].
	^ nil
]
