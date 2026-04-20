Class {
	#name : 'GbxTestableContextListPolicy',
	#superclass : 'GbxContextListPolicy',
	#instVars : [
		'serverContexts'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
GbxTestableContextListPolicy >> serverContexts: aCollection [
	serverContexts := aCollection
]

{ #category : 'context list' }
GbxTestableContextListPolicy >> fetchServerContexts [
	^ serverContexts ifNil: [ #() ]
]
