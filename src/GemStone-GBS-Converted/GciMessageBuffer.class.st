Class {
	#name : 'GciMessageBuffer',
	#superclass : 'FFIExternalStructure',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'field definition' }
GciMessageBuffer class >> byteSize [
	^ 1024
]

{ #category : 'converting' }
GciMessageBuffer >> asString [
	| stream val |
	stream := WriteStream on: String new.
	1 to: 1024 do: [ :i |
		val := handle unsignedByteAt: i.
		val = 0 ifTrue: [ ^ stream contents ].
		stream nextPut: (Character value: val) ].
	^ stream contents
]

{ #category : 'instance creation' }
GciMessageBuffer >> fromString: aString [
	| bytes |
	bytes := aString asByteArray.
	1 to: (bytes size min: 1024) do: [ :i |
		handle unsignedByteAt: i put: (bytes at: i) ].
	"Null terminate"
	bytes size < 1024 ifTrue: [ handle unsignedByteAt: bytes size + 1 put: 0 ].
]
