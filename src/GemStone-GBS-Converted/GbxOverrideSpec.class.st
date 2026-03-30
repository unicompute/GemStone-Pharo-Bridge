Class {
	#name : 'GbxOverrideSpec',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'printing' }
GbxOverrideSpec >> asExpressionString [
	^ String streamContents: [ :stream | self storeOn: stream ]
]

{ #category : 'printing' }
GbxOverrideSpec >> storeBehavior: aBehavior on: aStream [
	aBehavior ifNil: [
		aStream nextPutAll: 'nil'.
		^ self ].
	(aBehavior respondsTo: #isMeta)
		ifFalse: [ ^ aBehavior storeOn: aStream ].
	aStream nextPutAll: aBehavior instanceSide name asString.
	aBehavior isMeta ifTrue: [ aStream nextPutAll: ' class' ]
]

{ #category : 'printing' }
GbxOverrideSpec >> storeCollection: aCollection on: aStream [
	aStream nextPut: ${.
	aCollection
		do: [ :each | each storeOn: aStream ]
		separatedBy: [
			aStream
				nextPut: $.;
				space ].
	aStream nextPut: $}
]
