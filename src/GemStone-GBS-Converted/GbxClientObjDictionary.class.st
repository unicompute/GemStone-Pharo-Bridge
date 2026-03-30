Class {
	#name : 'GbxClientObjDictionary',
	#superclass : 'GbxConcurrentReadIdentityDictionary',
	#instVars : [
		'cachedClassStats'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'cache statistics' }
GbxClientObjDictionary class >> classWithStats [
	^ self
]

{ #category : 'cache statistics' }
GbxClientObjDictionary class >> classWithoutStats [
	^ self
]

{ #category : 'cache statistics' }
GbxClientObjDictionary >> inventoryCache [
	| statsByClass |
	statsByClass := cachedClassStats ifNil: [ cachedClassStats := IdentityDictionary new ].
	statsByClass valuesDo: [ :each | each reinitializeStats ].
	self keysAndValuesDo: [ :key :value |
		| proxyClass statResource estimatedBytes |
		proxyClass := key class.
		statResource := statsByClass
			at: proxyClass
			ifAbsentPut: [
				| resource |
				resource := GbxCachedClassStatResource new.
				resource cachedClass: proxyClass.
				GbxStatMonitor instance addStatResource: resource.
				resource ].
		estimatedBytes := (key respondsTo: #basicSize)
			ifTrue: [ key basicSize ]
			ifFalse: [ 0 ].
		statResource
			incNumInstances;
			incGbsBytesCached: estimatedBytes ]
]
