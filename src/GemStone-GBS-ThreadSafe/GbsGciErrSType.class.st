"
Typed FFI representation of the GciErrSType C structure returned by every
thread-safe GCI call. Ported from PharoGemStoneFFI (GciErrSType).

This replaces the bridge's legacy hand-computed byte offsets into a raw 2168/2500
byte buffer (e.g. 'handle signedLongAt: 105', message at offset 113) with named,
struct-derived accessors. Allocated on the C heap -- must be freed.
"
Class {
	#name : 'GbsGciErrSType',
	#superclass : 'FFIStructure',
	#classVars : [
		'OFFSET_ARGCOUNT',
		'OFFSET_ARGS',
		'OFFSET_CATEGORY',
		'OFFSET_CONTEXT',
		'OFFSET_EXCEPTIONOBJ',
		'OFFSET_FATAL',
		'OFFSET_MESSAGE',
		'OFFSET_NUMBER',
		'OFFSET_REASON'
	],
	#pools : [
		'GbsGciTypes'
	],
	#category : 'GemStone-GBS-ThreadSafe',
	#package : 'GemStone-GBS-ThreadSafe'
}

{ #category : 'ffi support' }
GbsGciErrSType class >> fieldsDesc [
	^ #(
		OopType category;
		OopType context;
		OopType exceptionObj;
		OopTypeArray10 args;
		int32 number;
		int32 argCount;
		uint8 fatal;
		CharArray1025 message;
		CharArray1025 reason;
		)
]

{ #category : 'accessing structure variables' }
GbsGciErrSType >> argCount [
	^ handle signedLongAt: OFFSET_ARGCOUNT
]

{ #category : 'accessing structure variables' }
GbsGciErrSType >> category [
	^ handle unsignedLongLongAt: OFFSET_CATEGORY
]

{ #category : 'accessing structure variables' }
GbsGciErrSType >> context [
	^ handle unsignedLongLongAt: OFFSET_CONTEXT
]

{ #category : 'accessing structure variables' }
GbsGciErrSType >> exceptionObj [
	^ handle unsignedLongLongAt: OFFSET_EXCEPTIONOBJ
]

{ #category : 'accessing structure variables' }
GbsGciErrSType >> fatal [
	^ handle unsignedByteAt: OFFSET_FATAL
]

{ #category : 'accessing structure variables' }
GbsGciErrSType >> message [
	| rs |
	rs := ReadStream on:
		(handle copyFrom: OFFSET_MESSAGE to: OFFSET_MESSAGE + 1024) asString.
	^ rs upTo: Character null
]

{ #category : 'accessing structure variables' }
GbsGciErrSType >> number [
	^ handle signedLongAt: OFFSET_NUMBER
]

{ #category : 'accessing structure variables' }
GbsGciErrSType >> reason [
	| rs |
	rs := ReadStream on:
		(handle copyFrom: OFFSET_REASON to: OFFSET_REASON + 1024) asString.
	^ rs upTo: Character null
]
