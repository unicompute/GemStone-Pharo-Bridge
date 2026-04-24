Class {
	#name : 'GciError',
	#superclass : 'FFIExternalStructure',
	#classVars : [
		'OFFSET_ARGS',
		'OFFSET_CATEGORY',
		'OFFSET_CONTEXT',
		'OFFSET_EXCEPTIONOBJ',
		'OFFSET_MESSAGE',
		'OFFSET_NUMBER',
		'OFFSET_PRIORITY',
		'OFFSET_REASON'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'field definition' }
GciError class >> byteSize [
	"40 bytes of primitives + 2048 bytes for message/reason buffers"
	^ 2112
]

{ #category : 'field definition' }
GciError class >> fieldsDesc [
	"Only the primitives. We handle the buffers manually."
	^ #(
		uint64 category;
		uint64 context;
		uint64 exceptionObj;
		uint64 args;
		int32 number;
		int32 priority;
	)
]

{ #category : 'class initialization' }
GciError class >> initialize [
  "This method runs automatically whenever the class is loaded or reloaded.
	 It ensures that the FFI accessors and byte offsets are always up to date."
	
	  "GciError compileFields"

  self compileFields
]

{ #category : 'accessing' }
GciError >> context [
	"Manually read the second uint64 field (starts at byte 9) to bypass FFI compiler crashes!"
	^ handle unsignedLongLongAt: 9.
]

{ #category : 'accessing' }
GciError >> message [
	"Reads from memory starting at byte 41 until a null terminator"
	| stream val |
	stream := WriteStream on: String new.
	1 to: 1024 do: [ :i |
		val := handle unsignedByteAt: 40 + i.
		val = 0 ifTrue: [ ^ stream contents ].
		stream nextPut: (Character value: val) ].
	^ stream contents
]

{ #category : 'accessing' }
GciError >> message: aString [
	"Writes directly to memory starting at byte 41"
	| bytes |
	bytes := aString asByteArray.
	1 to: (bytes size min: 1024) do: [ :i |
		handle unsignedByteAt: 40 + i put: (bytes at: i) ].
		
	"Null terminate"
	bytes size < 1024 ifTrue: [ 
		handle unsignedByteAt: 40 + bytes size + 1 put: 0 ].
]
