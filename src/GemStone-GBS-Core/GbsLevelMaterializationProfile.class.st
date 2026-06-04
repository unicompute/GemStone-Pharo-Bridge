Class {
	#name : 'GbsLevelMaterializationProfile',
	#superclass : 'GbsDeepMaterializationProfile',
	#instVars : [
		'maxLevel'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsLevelMaterializationProfile class >> maxLevel: anInteger [
	^ self new
		maxLevel: anInteger;
		yourself
]

{ #category : 'accessing' }
GbsLevelMaterializationProfile >> maxLevel [
	^ maxLevel ifNil: [ 1 ]
]

{ #category : 'accessing' }
GbsLevelMaterializationProfile >> maxLevel: anInteger [
	maxLevel := anInteger ifNil: [ 1 ] ifNotNil: [ anInteger asInteger max: 1 ]
]

{ #category : 'materialization' }
GbsLevelMaterializationProfile >> shouldMaterializeCollectionClassNamed: className depth: anInteger [
	^ anInteger < self maxLevel and: [
		super shouldMaterializeCollectionClassNamed: className depth: anInteger ]
]

{ #category : 'materialization' }
GbsLevelMaterializationProfile >> shouldMaterializeMappedClassNamed: className inSession: aSession depth: anInteger [
	^ anInteger < self maxLevel and: [
		super shouldMaterializeMappedClassNamed: className inSession: aSession ]
]
