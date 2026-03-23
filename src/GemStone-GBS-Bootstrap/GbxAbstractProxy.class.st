Class {
	#name : 'GbxAbstractProxy',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'validation' }
GbxAbstractProxy >> gbxSession [
	"Answer the session for the receiver, or nil if the proxy is already defunct."

	| delegate |
	delegate := self gbxDelegate.
	delegate isNil ifTrue: [ ^ nil ].
	^ delegate validateSessionForProxy: self
]

{ #category : 'debugging' }
GbxAbstractProxy >> gbxGsDebuggerSession [
	^ self gbxSession
]

{ #category : 'validation' }
GbxAbstractProxy >> gbxValidateExistence [
	"Validate the proxy and verify that the server-side object still exists."

	| proxy |
	proxy := self gbxValidateDelegateAndSession.
	proxy isNil ifTrue: [ ^ nil ].
	proxy exists ifFalse: [
		self
			gbxProxyError: '%1 - %2 does not exist'
			with: self gbxBasicClass
			with: proxy ].
	^ proxy
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxProxyError: errorString [
	(self gbxBasicClass respondsTo: #debugWhile:)
		ifTrue: [ ^ self gbxBasicClass debugWhile: [ self gbsMessenger error: errorString ] ].
	^ self gbsMessenger error: errorString
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxProxyError: errorString with: arg1 [
	(self gbxBasicClass respondsTo: #debugWhile:)
		ifTrue: [ ^ self gbxBasicClass debugWhile: [ self gbsMessenger error: errorString with: arg1 ] ].
	^ self gbsMessenger error: errorString with: arg1
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxProxyError: errorString with: arg1 with: arg2 [
	(self gbxBasicClass respondsTo: #debugWhile:)
		ifTrue: [ ^ self gbxBasicClass debugWhile: [ self gbsMessenger error: errorString with: arg1 with: arg2 ] ].
	^ self gbsMessenger error: errorString with: arg1 with: arg2
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxProxyError: errorString with: arg1 with: arg2 with: arg3 [
	(self gbxBasicClass respondsTo: #debugWhile:)
		ifTrue: [ ^ self gbxBasicClass debugWhile: [ self gbsMessenger error: errorString with: arg1 with: arg2 with: arg3 ] ].
	^ self gbsMessenger error: errorString with: arg1 with: arg2 with: arg3
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxPerform: selector withArguments: anArray [
	self gbxProxyError: 'Subclass responsibility.'
]
