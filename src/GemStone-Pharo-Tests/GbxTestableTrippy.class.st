Class {
	#name : 'GbxTestableTrippy',
	#superclass : 'GbxTrippy',
	#instVars : [
		'showCurrentObjectCalls'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxTestableTrippy >> showCurrentObjectCalls [
	^ showCurrentObjectCalls ifNil: [ 0 ]
]

{ #category : 'navigation' }
GbxTestableTrippy >> showCurrentObject [
	showCurrentObjectCalls := self showCurrentObjectCalls + 1
]
