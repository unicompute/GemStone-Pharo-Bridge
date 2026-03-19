Class {
	#name : 'GbxGciClampedTravArgsSType',
	#superclass : 'GbxStructure',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'printing' }
GbxGciClampedTravArgsSType >> printOn: aStream indent: indent 
[
	| travBuffSize |
	aStream tab: indent - 1.
	aStream nextPutAll: self class name , ' with:'.
	aStream crtab: indent.
	aStream nextPutAll: 'clampSpec = ' , self clampSpec printString.
	aStream crtab: indent.
	aStream nextPutAll: 'travBuff = ' , self travBuff asInteger printString.
	aStream crtab: indent.
	"64-bit version has no travBuffSize; skip it if not present."
	
	[travBuffSize := self travBuffSize.
	aStream nextPutAll: 'travBuffSize = ' , travBuffSize printString.
	aStream crtab: indent] 
			on: Error
			do: [:ex | ex return].
	aStream nextPutAll: 'level = ' , self level printString.
	aStream crtab: indent.
	aStream nextPutAll: 'retrievalFlags = ' , self retrievalFlags printString.
	aStream crtab: indent.
	aStream nextPutAll: 'resultOop = ' , self resultOop printString
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> clampSpec
[
	^self oopAt: 1
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> clampSpec: aSpec
[
	self oopAt: 1 put: aSpec
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> isRpc
[
	^self boolAt: 33
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> level
[
	^self uint32At: 25
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> level: aSpec
[
	self uint32At: 25 put: aSpec
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> objRepHdrSize
[
	"GS64 does not carry objRepHdrSize in this struct."

	^0
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> resultOop
[
	^self oopAt: 9
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> retrievalFlags
[
	^self uint32At: 29
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> retrievalFlags: aSpec
[
	self uint32At: 29 put: aSpec
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> travBuff
[
	^self oopAt: 17
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> travBuff: aSpec
[
	self oopAt: 17 put: aSpec
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> travBuffSize
[
	"GS64 does not carry travBuffSize in this struct."

	^0
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> travBuffSize: aSpec
[
	"GS64 does not carry travBuffSize in this struct."
]
