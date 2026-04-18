Class {
	#name : 'GbsDeepMaterializationProfile',
	#superclass : 'GbsMaterializationProfile',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'materialization' }
GbsDeepMaterializationProfile >> shouldMaterializeCollectionClassNamed: className depth: anInteger [
	^ #('Array' 'OrderedCollection' 'SortedCollection' 'Bag' 'Set' 'IdentitySet' 'Dictionary' 'IdentityDictionary' 'Association')
		includes: className
]
