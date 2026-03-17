Class {
	#name : #'GbxCachedClassStatResource',
	#superclass : #'GbxStatResource',
	#instVars : [ #'numInstances' #'gbsBytesCached' #'cachedClass' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'stat updating' }
GbxCachedClassStatResource >> incGbsBytesCached: delta
	gbsBytesCached incValue: delta

{ #category : #'stat updating' }
GbxCachedClassStatResource >> incNumInstances
	numInstances incValue: 1

{ #category : #'stat updating' }
GbxCachedClassStatResource >> reinitializeStats
	gbsBytesCached setValue: 0.
	numInstances setValue: 0

{ #category : #'stat accessing' }
GbxCachedClassStatResource >> numInstances
	"The number of instances of cachedClass in stObjectCache"

	^numInstances value

{ #category : #'stat accessing' }
GbxCachedClassStatResource >> gbxBytesCached
	"The number of bytes occupied by instances of cachedClass in stObjectCache"

	^gbsBytesCached value

{ #category : #'archiving' }
GbxCachedClassStatResource >> instanceDescription

	^cachedClass name

{ #category : #'initialize-release' }
GbxCachedClassStatResource >> cachedClass: aClass

	cachedClass := aClass

{ #category : #'initialize-release' }
GbxCachedClassStatResource >> initializeStatistics
	"Set the receiver's statistics to 0"

	super initializeStatistics.
	numInstances := self newGbxStatFor: 'numInstances' value: 0.
	gbsBytesCached := self newGbxStatFor: 'gbsBytesCached' value: 0

{ #category : #'class initialization' }
GbxCachedClassStatResource class >> initialize
	"Create GbxStatDescriptors for this stat resource"

	statDescriptors := OrderedCollection new.
	self
		addStatDescriptor: (GbxStatDescriptor 
					name: 'numInstances'
					description: 'The number of instances of this class in the stObjectCache'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'instances');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'gbsBytesCached'
					description: 'The number of bytes occupied by instances of this class in the stObjectCache'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes')

{ #category : #'archiving' }
GbxCachedClassStatResource class >> resourceTypeDescription
	^'Statistics associated with instances of a specific class in the stObjectCache'

{ #category : #'archiving' }
GbxCachedClassStatResource class >> resourceTypeId
	^2

{ #category : #'archiving' }
GbxCachedClassStatResource class >> resourceTypeName
	^'Cache'

