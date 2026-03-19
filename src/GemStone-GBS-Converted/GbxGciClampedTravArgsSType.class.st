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
	^data memberAt: #clampSpec
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> clampSpec: aSpec
[
	data memberAt: #clampSpec put: aSpec
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> isRpc
[
	^data memberAt: #isRpc
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> level
[
	^data memberAt: #level
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> level: aSpec
[
	data memberAt: #level put: aSpec
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> objRepHdrSize
[
	^data memberAt: #objRepHdrSize
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> resultOop
[
	^data memberAt: #resultOop
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> retrievalFlags
[
	^data memberAt: #retrievalFlags
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> retrievalFlags: aSpec
[
	data memberAt: #retrievalFlags put: aSpec
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> travBuff
[
	^data memberAt: #travBuff
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> travBuff: aSpec
[
	data memberAt: #travBuff put: aSpec
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> travBuffSize
[
	"On a 64-bit oop library, this will fail."

	^data memberAt: #travBuffSize
]

{ #category : 'accessing' }
GbxGciClampedTravArgsSType >> travBuffSize: aSpec
[
	"On a 64-bit oop library, this will do nothing."

	[data memberAt: #travBuffSize put: aSpec]
		on: Error
		do: [:ex | ex return]
]
