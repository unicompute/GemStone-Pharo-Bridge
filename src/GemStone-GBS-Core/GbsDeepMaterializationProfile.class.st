Class {
	#name : 'GbsDeepMaterializationProfile',
	#superclass : 'GbsMaterializationProfile',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'materialization' }
GbsDeepMaterializationProfile >> shouldMaterializeCollectionClassNamed: className depth: anInteger [
	^ #('Array' 'OrderedCollection' 'SortedCollection' 'Bag' 'Set' 'IdentitySet' 'Dictionary' 'IdentityDictionary' 'Association')
		includes: className
]
