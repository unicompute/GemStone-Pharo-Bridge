Class {
	#name : 'GbsBrokenDependent',
	#superclass : 'Object',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'updating' }
GbsBrokenDependent >> update: anAspect from: aSender [
	self error: 'broken dependent'
]

{ #category : 'updating' }
GbsBrokenDependent >> update: anAspect with: anObject from: aSender [
	self error: 'broken dependent'
]
