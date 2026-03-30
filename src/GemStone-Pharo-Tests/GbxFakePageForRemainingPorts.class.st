Class {
	#name : 'GbxFakePageForRemainingPorts',
	#superclass : 'Object',
	#instVars : [
		'partCount',
		'cachedRanges',
		'selectedSegments',
		'cachedIntervals',
		'fieldList'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakePageForRemainingPorts >> cachedIntervals [
	^ cachedIntervals ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxFakePageForRemainingPorts >> fieldList [
	^ fieldList ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxFakePageForRemainingPorts >> fieldList: aCollection [
	fieldList := aCollection asArray
]

{ #category : 'accessing' }
GbxFakePageForRemainingPorts >> gbxCachedRanges [
	^ cachedRanges ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxFakePageForRemainingPorts >> gbxCachedRanges: aCollection [
	cachedRanges := aCollection asArray
]

{ #category : 'actions' }
GbxFakePageForRemainingPorts >> gbxCacheInterval: anInterval [
	cachedIntervals ifNil: [ cachedIntervals := OrderedCollection new ].
	cachedIntervals add: anInterval
]

{ #category : 'accessing' }
GbxFakePageForRemainingPorts >> gbxDriverPartAt: anIndex [
	^ 'part-', anIndex asString
]

{ #category : 'accessing' }
GbxFakePageForRemainingPorts >> partCount [
	^ partCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakePageForRemainingPorts >> partCount: anInteger [
	partCount := anInteger
]

{ #category : 'accessing' }
GbxFakePageForRemainingPorts >> selectedSegments [
	^ selectedSegments ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxFakePageForRemainingPorts >> selectedSegments: aCollection [
	selectedSegments := aCollection asArray
]
