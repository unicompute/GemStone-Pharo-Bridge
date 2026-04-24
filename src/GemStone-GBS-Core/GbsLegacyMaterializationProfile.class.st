Class {
	#name : 'GbsLegacyMaterializationProfile',
	#superclass : 'GbsMaterializationProfile',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'materialization' }
GbsLegacyMaterializationProfile >> shouldMaterializeCollectionClassNamed: className depth: anInteger [
	^ className = 'Array'
]
