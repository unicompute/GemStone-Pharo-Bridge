"
Typed FFI representation of the GciTsObjInfo C structure, filled in by
GciTsFetchObjInfo. Carries an object's class OOP and size in one round trip, so
the bridge no longer needs separate GciFetchClass + GciFetchSize_ calls.
Ported from PharoGemStoneFFI (GciTsObjInfo). Allocated on the C heap -- must be freed.

NOTE: defined but not yet exercised by this prototype. The hot path uses
GciTsExecuteFetchBytes (a single round trip that needs no objInfo). This struct is
the next step -- general object fetch via GciTsFetchObjInfo.
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
	^ #(
		OopType objId;
		OopType objClass;
		int64 objSize;
		int namedSize;
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
