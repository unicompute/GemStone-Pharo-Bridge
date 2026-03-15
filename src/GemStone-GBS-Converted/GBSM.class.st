Class {
	#name : 'GBSM',
	#superclass : 'Object',
	#classInstVars : [
		'CurrentSession',
		'Dependents'
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
    (GbsSessionParameters currentSession == aSession)
		ifFalse: [ GbsSessionParameters currentSession: aSession ].
	previous == aSession ifFalse: [
		self changed: #gbxCurrentSessionChanged with: aSession ]
]

{ #category : 'dependents' }
GBSM class >> dependents [
	^ Dependents ifNil: [ Dependents := OrderedCollection new ]
]

{ #category : 'dependents' }
GBSM class >> removeDependent: anObject [
	self dependents remove: anObject ifAbsent: [ ]
]

{ #category : 'cleanup' }
GBSM class >> reset [
    CurrentSession := nil.
	Dependents := OrderedCollection new
]
