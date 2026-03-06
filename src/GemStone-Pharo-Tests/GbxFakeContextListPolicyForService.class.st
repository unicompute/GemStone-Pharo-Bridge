Class {
	#name : 'GbxFakeContextListPolicyForService',
	#superclass : 'Object',
	#instVars : [
		'contexts'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeContextListPolicyForService >> computeContextList [
	^ self contextList
]

{ #category : 'accessing' }
GbxFakeContextListPolicyForService >> contextList [
	^ contexts ifNil: [ #( ) ]
]

{ #category : 'accessing' }
GbxFakeContextListPolicyForService >> contextList: aCollection [
	contexts := aCollection
]
