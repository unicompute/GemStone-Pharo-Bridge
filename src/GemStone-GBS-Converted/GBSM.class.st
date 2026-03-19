Class {
	#name : 'GBSM',
	#superclass : 'Object',
	#classInstVars : [
		'CurrentSession',
		'Dependents',
		'Manager'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'dependents' }
GBSM class >> addDependent: anObject [
	anObject ifNil: [ ^ self ].
	(self dependents includes: anObject) ifFalse: [ self dependents add: anObject ]
]

{ #category : 'cleanup' }
GBSM class >> aboutToQuit [
	Manager ifNotNil: [
		[ Manager aboutToQuit ] on: Error do: [ ] ].
	self changed: #gbxAboutToQuit.
	self reset
]

{ #category : 'dependents' }
GBSM class >> changed: anEventSymbol [
	self changed: anEventSymbol with: CurrentSession
]

{ #category : 'dependents' }
GBSM class >> changed: anEventSymbol with: anObject [
	self dependents do: [ :each |
		(each respondsTo: #update:with:from:)
			ifTrue: [ [ each update: anEventSymbol with: anObject from: self ] on: Error do: [ ] ]
			ifFalse: [
				(each respondsTo: #update:from:)
					ifTrue: [ [ each update: anEventSymbol from: self ] on: Error do: [ ] ] ] ]
]

{ #category : 'accessing' }
GBSM class >> currentSession [
	CurrentSession ifNotNil: [ ^ CurrentSession ].
	^ GbsSessionParameters currentSession
]

{ #category : 'accessing' }
GBSM class >> currentSession: aSession [
	| previous |
	previous := CurrentSession.
	CurrentSession := aSession.
	Manager ifNotNil: [
		[ Manager currentSession: aSession ] on: Error do: [ ] ].
	(GbsSessionParameters currentSession == aSession)
		ifFalse: [ GbsSessionParameters currentSession: aSession ].
	previous == aSession ifFalse: [
		self changed: #gbxCurrentSessionChanged with: aSession ]
]

{ #category : 'dependents' }
GBSM class >> dependents [
	^ Dependents ifNil: [ Dependents := OrderedCollection new ]
]

{ #category : 'message forwarding' }
GBSM class >> doesNotUnderstand: aMessage [
	^ self manager
		perform: aMessage selector
		withArguments: aMessage arguments
]

{ #category : 'accessing' }
GBSM class >> manager [
	Manager ifNil: [
		GbsSessionManager initialize.
		Manager := GbsSessionManager basicNew.
		Manager initialize ].
	^ Manager
]

{ #category : 'accessing' }
GBSM class >> managerIfPresent [
	^ Manager
]

{ #category : 'dependents' }
GBSM class >> removeDependent: anObject [
	self dependents remove: anObject ifAbsent: [ ]
]

{ #category : 'cleanup' }
GBSM class >> reset [
	CurrentSession := nil.
	Dependents := OrderedCollection new.
	Manager := nil
]

{ #category : 'ui' }
GBSM class >> showBusyWhile: aBlock [
	(UIManager default notNil and: [ UIManager default respondsTo: #showWaitCursorWhile: ])
		ifTrue: [ ^ UIManager default showWaitCursorWhile: aBlock ].
	^ aBlock value
]
