Class {
	#name : 'GbxCachedClassStatResource',
	#superclass : 'GbxStatResource',
	#instVars : [
		'numInstances',
		'gbsBytesCached',
		'cachedClass'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxCachedClassStatResource >> cachedClass [
	^ cachedClass
]

{ #category : 'accessing' }
GbxCachedClassStatResource >> cachedClass: aClass [
	cachedClass := aClass
]

{ #category : 'class initialization' }
GbxCachedClassStatResource class >> initialize [
	statDescriptors := OrderedCollection new.
	#(
		('numInstances' 'The number of instances of this class in the cache' 5 false false 'instances')
		('gbsBytesCached' 'The number of bytes occupied by instances of this class in the cache' 5 false false 'bytes')
	) do: [ :spec |
		self addStatDescriptor: (GbxStatDescriptor
			name: spec first
			description: spec second
			type: spec third
			isCounter: spec fourth
			isLargerBetter: spec fifth
			unit: spec sixth) ]
]

{ #category : 'initialize-release' }
GbxCachedClassStatResource >> initializeStatistics [
	super initializeStatistics.
	self initializeZeroStatisticsFromDescriptors
]

{ #category : 'archiving' }
GbxCachedClassStatResource >> instanceDescription [
	^ cachedClass
		ifNil: [ 'UnknownCachedClass' ]
		ifNotNil: [ cachedClass name asString ]
]

{ #category : 'archiving' }
GbxCachedClassStatResource class >> resourceTypeId [
	^ 2
]

{ #category : 'archiving' }
GbxCachedClassStatResource class >> resourceTypeName [
	^ 'Cache'
]
