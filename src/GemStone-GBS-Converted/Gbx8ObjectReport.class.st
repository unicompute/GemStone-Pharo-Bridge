Class {
	#name : 'Gbx8ObjectReport',
	#superclass : 'GbxObjectReport',
	#instVars : [
		'bits'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing header' }
Gbx8ObjectReport >> setObjIdFromDelegate: del
[
	"del must be of my size and endianness"

	data
		gbxReplaceBytesFrom: offset + 8
		to: offset + 15
		with: del
		startingAt: 5
]

{ #category : 'accessing header' }
Gbx8ObjectReport >> isPartial
[

	^((data basicAt: offset + 32) bitAnd: 16r10) ~= 0
]

{ #category : 'accessing header' }
Gbx8ObjectReport >> firstOffset
[

	firstOffset == nil ifTrue: [firstOffset := data longLongAt: offset + 24].
	^firstOffset
]

{ #category : 'accessing header' }
Gbx8ObjectReport >> objImpl: impl
[
	"impl must be between 0 and 3, inclusive"
	"We also set the isOverlayed bit (mask 16r20)."

	objImpl := impl.
	bits := bits bitOr: (impl bitOr: 16r20)
]

{ #category : 'accessing header' }
Gbx8ObjectReport >> objSize: aSize
[
	"Cannot set this directly in 64-bit headers."
]

{ #category : 'accessing header' }
Gbx8ObjectReport >> setObjClassFromDelegate: del
[
	"del must be of my size and endianness"

	data
		gbxReplaceBytesFrom: offset + 16
		to: offset + 23
		with: del
		startingAt: 5
]

{ #category : 'accessing header' }
Gbx8ObjectReport >> objId
[

	objId == nil
		ifTrue: 
			[objId := session bufferOopClass
				fromBuffer: data
				offset: offset + 8].
	^objId
]

{ #category : 'accessing header' }
Gbx8ObjectReport >> lacksReadAuth
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
Gbx8ObjectReport >> objClass
[

	objClass == nil
		ifTrue: 
			[objClass := session bufferOopClass
				fromBuffer: data
				offset: offset + 16].
	^objClass
]

{ #category : 'accessing header' }
Gbx8ObjectReport >> idxSize: aSize
[

	indexedSize := aSize
]

{ #category : 'accessing header' }
Gbx8ObjectReport >> firstOffset: anOffset
[

	firstOffset := anOffset.
	data
		longLongAt: offset + 24
		put: anOffset
]

{ #category : 'printing' }
Gbx8ObjectReport >> stringClasses
[

	^super stringClasses
]

{ #category : 'printing' }
Gbx8ObjectReport >> printHeaderOn: aStream indent: indent
[

	super printHeaderOn: aStream indent: indent.
	aStream crtab: indent.
	aStream nextPutAll: 'isPartial = ' , self isPartial printString.
	aStream crtab: indent.
	aStream nextPutAll: 'lacksReadAuth = ' , self lacksReadAuth printString.
	aStream crtab: indent.
	aStream nextPutAll: 'isClamped = ' , self isClamped printString
]

{ #category : 'GBS private' }
Gbx8ObjectReport >> segmentValueForSession: sess
[
	"Answer the segment marker that means 'leave unchanged / current default segment'."

	^16rFFFF
]

{ #category : 'GBS private' }
Gbx8ObjectReport >> bytesPerOop
[

	^8
]

{ #category : 'accessing' }
Gbx8ObjectReport >> setOffsetTo: aByteOffset
[
	"aByteOffset is a positive SmallInteger"

	offset := aByteOffset.
	segment := indexedSize := nil.
	bits := 0.
	self oopsBuffer setOffsetTo: offset + fixedSize.
	self bytesBuffer setOffsetTo: offset + fixedSize.
	self objId setOffsetTo: offset + 8.
	self objClass setOffsetTo: offset + 16.
	valueBuffSize := namedSize := firstOffset := objImpl := nil
]
