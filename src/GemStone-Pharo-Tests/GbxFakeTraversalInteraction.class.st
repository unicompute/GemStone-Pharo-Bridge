Class {
	#name : 'GbxFakeTraversalInteraction',
	#superclass : 'Object',
	#instVars : [
		'serverInterface'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'instance creation' }
GbxFakeTraversalInteraction class >> serverInterface: aServerInterface [
	^ self new
		serverInterface: aServerInterface;
		yourself
]

{ #category : 'accessing' }
GbxFakeTraversalInteraction >> serverInterface [
	^ serverInterface
]

{ #category : 'accessing' }
GbxFakeTraversalInteraction >> serverInterface: aServerInterface [
	serverInterface := aServerInterface
]
