Extension { #name : 'GbxReplicationScheme' }

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme class >> none [
	^ self selector: #none
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme class >> replicate [
	^ self selector: #replicate
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme class >> selector: aSelector [
	^ self new
		selector: aSelector;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme class >> stub [
	^ self selector: #stub
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> clamp [
	^ clamp
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> clamp: aClamp [
	clamp := aClamp
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> forwarderOffsetsFor: aClass [
	^ forwarderOffsetsDict at: aClass ifAbsent: [ #() ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> forwarderOffsetsFor: aClass put: offsets [
	forwarderOffsetsDict at: aClass put: offsets asArray.
	^ offsets
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> initialize [
	super initialize.
	indexedInstvarsShouldBeForwardersDict := IdentityDictionary new.
	forwarderOffsetsDict := IdentityDictionary new.
	selector := #replicate.
	isValid := true
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> invalidate [
	isValid := false
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> isValid [
	^ isValid ~~ false
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> isNone [
	^ selector = #none
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> isReplicate [
	^ selector = #replicate
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> isStub [
	^ selector = #stub
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> selector [
	^ selector
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> selector: aSelector [
	selector := aSelector asSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> shouldAutoMarkDirty [
	^ self shouldReplicate
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> shouldReplicate [
	^ self isValid and: [
		self isNone not and: [ self isStub not ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> shouldStub [
	^ self isValid and: [ self isStub ]
]
