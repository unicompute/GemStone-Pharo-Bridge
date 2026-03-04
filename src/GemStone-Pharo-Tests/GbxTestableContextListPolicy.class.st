Class {
	#name : 'GbxTestableContextListPolicy',
	#superclass : 'GbxContextListPolicy',
	#instVars : [
		'serverContexts'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxTestableContextListPolicy >> serverContexts: aCollection [
	serverContexts := aCollection
]

{ #category : 'context list' }
GbxTestableContextListPolicy >> fetchServerContexts [
	^ serverContexts ifNil: [ #() ]
]
