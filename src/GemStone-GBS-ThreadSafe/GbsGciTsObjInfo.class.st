"
Typed FFI representation of the GciTsObjInfo C structure, filled in by
GciTsFetchObjInfo. Carries an object's class OOP and size in one round trip, so
the bridge no longer needs separate GciFetchClass + GciFetchSize_ calls.
Ported from PharoGemStoneFFI (GciTsObjInfo). Allocated on the C heap -- must be freed.

The dynamic thread-safe evaluate path uses this structure to distinguish byte
objects from unsupported general objects and to size snapshot result buffers.
"
Class {
	#name : 'GbsGciTsObjInfo',
	#superclass : 'FFIStructure',
	#classVars : [
		'OFFSET_ACCESS',
		'OFFSET_NAMEDSIZE',
		'OFFSET_OBJCLASS',
		'OFFSET_OBJECTSECURITYPOLICYID',
		'OFFSET_OBJID',
		'OFFSET_OBJSIZE',
		'OFFSET__BITS'
	],
	#pools : [
		'GbsGciTypes'
	],
	#category : 'GemStone-GBS-ThreadSafe',
	#package : 'GemStone-GBS-ThreadSafe'
}

{ #category : 'field definition' }
GbsGciTsObjInfo class >> fieldsDesc [
	"Field types govern only size/alignment; the accessors below apply the correct
	signedness (objSize/namedSize are read signed). Pharo 13's FFI struct compiler
	resolves uint64/int32/uint32/uint16 cleanly, but trips
	(FFIInt64>>externalTypeAlignment subclassResponsibility) on the bare 'int64' and
	'int' type names, so use uint64 (8 bytes) and int32 (4 bytes) here."
	^ #(
		OopType objId;
		OopType objClass;
		uint64 objSize;
		int32 namedSize;
		uint32 access;
		uint16 objectSecurityPolicyId;
		uint16 _bits;
		)
]

{ #category : 'accessing structure variables' }
GbsGciTsObjInfo >> access [
	^ handle unsignedLongAt: OFFSET_ACCESS
]

{ #category : 'accessing structure variables' }
GbsGciTsObjInfo >> namedSize [
	^ handle signedLongAt: OFFSET_NAMEDSIZE
]

{ #category : 'accessing structure variables' }
GbsGciTsObjInfo >> objClass [
	^ handle unsignedLongLongAt: OFFSET_OBJCLASS
]

{ #category : 'accessing structure variables' }
GbsGciTsObjInfo >> objId [
	^ handle unsignedLongLongAt: OFFSET_OBJID
]

{ #category : 'accessing structure variables' }
GbsGciTsObjInfo >> objSize [
	^ handle signedLongLongAt: OFFSET_OBJSIZE
]

{ #category : 'accessing structure variables' }
GbsGciTsObjInfo >> objectSecurityPolicyId [
	^ handle unsignedShortAt: OFFSET_OBJECTSECURITYPOLICYID
]
