Class {
	#name : 'GbxDebuggerClient',
	#superclass : 'Object',
	#instVars : [
		'service',
		'busy',
		'cachedContext',
		'cachedSymbolList'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbxDebuggerClient >> areTextProbeCommandsLegal [
	^ self hasValidClientContext
]

{ #category : 'testing' }
GbxDebuggerClient >> canRecompileBlocks [
	^ self hasValidClientContext and: [ self notBusy ]
]

{ #category : 'testing' }
GbxDebuggerClient >> enableClientDebugCommand [
	^ self hasValidClientContext
]

{ #category : 'sessions' }
GbxDebuggerClient >> gbtService [
	^ service
]

{ #category : 'sessions' }
GbxDebuggerClient >> gbxDoItAgent [
	^ service
]

{ #category : 'accessing' }
GbxDebuggerClient >> getMethodSymbols [
	| context method |
	context := service ifNil: [ nil ] ifNotNil: [
		(service respondsTo: #context)
			ifTrue: [ service context ]
			ifFalse: [ nil ] ].
	context ifNil: [ ^ #() ].
	cachedContext == context ifTrue: [ ^ cachedSymbolList ifNil: [ #() ] ].
	method := (context respondsTo: #method)
		ifTrue: [ context method ]
		ifFalse: [ nil ].
	cachedSymbolList := method ifNil: [ #() ] ifNotNil: [
		(method respondsTo: #allSymbolLiterals)
			ifTrue: [ method allSymbolLiterals ]
			ifFalse: [ #() ] ].
	cachedContext := context.
	^ cachedSymbolList
]

{ #category : 'testing' }
GbxDebuggerClient >> hasValidClientContext [
	| context |
	context := service ifNil: [ nil ] ifNotNil: [
		(service respondsTo: #context)
			ifTrue: [ service context ]
			ifFalse: [ nil ] ].
	context ifNil: [ ^ false ].
	^ (context respondsTo: #gbxIsServerContext)
		ifTrue: [ context gbxIsServerContext not ]
		ifFalse: [ true ]
]

{ #category : 'testing' }
GbxDebuggerClient >> hasValidContext [
	^ service notNil and: [
		(service respondsTo: #context)
			ifTrue: [ service context notNil ]
			ifFalse: [ false ] ]
]

{ #category : 'initialization' }
GbxDebuggerClient >> initialize [
	super initialize.
	busy := true.
	cachedSymbolList := #()
]

{ #category : 'testing' }
GbxDebuggerClient >> notBusy [
	^ busy not
]

{ #category : 'accessing' }
GbxDebuggerClient >> service [
	^ service
]

{ #category : 'accessing' }
GbxDebuggerClient >> service: anObject [
	service := anObject
]
