Class {
	#name : 'GbsLegacyMaterializationProfile',
	#superclass : 'GbsMaterializationProfile',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'materialization' }
GbsLegacyMaterializationProfile >> shouldMaterializeCollectionClassNamed: className depth: anInteger [
	^ className = 'Array'
]
