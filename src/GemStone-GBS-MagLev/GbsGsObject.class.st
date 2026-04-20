Class {
	#name : 'GbsGsObject',
	#superclass : 'GbsMaglevRuntimeProxy',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'querying' }
GbsGsObject >> className [
	^ [ session remoteClassNameForOop: self oop ]
		on: Error
		do: [ 'Object' ]
]

{ #category : 'printing' }
GbsGsObject >> displayString [
	| result |
	result := self executeAgainstRemote: '[ obj printString ] on: Error do: [ nil ]'.
	^ result
		ifNil: [ 'a', self className ]
		ifNotNil: [ result ]
]

{ #category : 'printing' }
GbsGsObject >> reportText [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self className;
			nextPutAll: ' @ oop ';
			nextPutAll: self oop printString;
			cr; cr;
			nextPutAll: self displayString ]
]

{ #category : 'printing' }
GbsGsObject >> printOn: aStream [
	aStream nextPutAll: self displayString
]
