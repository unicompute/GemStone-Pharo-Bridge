Extension { #name : 'IdentityDictionary' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
IdentityDictionary class >> gbsReplicatorClass [
	^ GbxIdentityDictionaryReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
IdentityDictionary class >> gsObjImpl [
	^ 0
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
IdentityDictionary >> indexableValuesBuffer [
	^ GbxKeyValueFaulter for: self
]
