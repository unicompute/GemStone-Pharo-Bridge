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
	signedness (objSize/namedSize are read signed). Historical note: the bare
	'int64' type name used to trip FFIInt64>>externalTypeAlignment
	subclassResponsibility -- NOT a Pharo limitation, but the incomplete FFIInt64
	shadow class the GemStone-GBS-Converted package carried, which silently
	REPLACED UnifiedFFI's real FFIInt64 image-wide (it also broke Iceberg's
	libgit structs, found on the Pharo 14 upgrade 2026-07-16). That shadow class
	is deleted; uint64/int32 stay here because they are correct for
	size/alignment and proven in production."
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
