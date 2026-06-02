Extension { #name : 'GbxNullReplicationScheme' }

{ #category : '*GemStone-GBS-Core' }
GbxNullReplicationScheme >> invalidate [
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbxNullReplicationScheme >> isValid [
	^ true
]

{ #category : '*GemStone-GBS-Core' }
GbxNullReplicationScheme >> selector [
	^ nil
]

{ #category : '*GemStone-GBS-Core' }
GbxNullReplicationScheme >> shouldAutoMarkDirty [
	^ false
]

{ #category : '*GemStone-GBS-Core' }
GbxNullReplicationScheme >> shouldReplicate [
	^ false
]

{ #category : '*GemStone-GBS-Core' }
GbxNullReplicationScheme >> shouldStub [
	^ false
]
