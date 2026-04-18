Class {
	#name : 'GbsShallowMaterializationProfile',
	#superclass : 'GbsMaterializationProfile',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'materialization' }
GbsShallowMaterializationProfile >> nestedProfileForDepth: anInteger [
	^ GbsProxyOnlyMaterializationProfile new
]

{ #category : 'materialization' }
GbsShallowMaterializationProfile >> shouldMaterializeCollectionClassNamed: className depth: anInteger [
	^ #('Array' 'OrderedCollection' 'SortedCollection' 'Bag' 'Set' 'IdentitySet' 'Dictionary' 'IdentityDictionary' 'Association')
		includes: className
]
