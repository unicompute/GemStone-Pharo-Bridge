Class {
	#name : 'GbxTimeZoneInfo',
	#superclass : 'Object',
	#instVars : [
		'leapSeconds',
		'transitions'
	],
	#classInstVars : [
		'Default'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'singleton' }
GbxTimeZoneInfo class >> default [
	Default ifNil: [ Default := GbxTimeZone newLocalDefault ].
	^ Default
]

{ #category : 'cache' }
GbxTimeZoneInfo class >> default: aTimeZoneInfo [
	Default := aTimeZoneInfo
]

{ #category : 'private' }
GbxTimeZoneInfo >> detectLastTransition: aBlock [
	| candidate |
	candidate := nil.
	self transitions do: [ :each |
		(aBlock value: each) ifTrue: [ candidate := each ] ].
	^ candidate
]

{ #category : 'accessing' }
GbxTimeZoneInfo >> leapSeconds [
	^ leapSeconds ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxTimeZoneInfo >> leapSeconds: aCollection [
	leapSeconds := aCollection asArray
]

{ #category : 'public' }
GbxTimeZoneInfo >> offsetAtLocal: aDateAndTime [
	| transition |
	transition := self transitionAtLocal: aDateAndTime.
	transition isNil ifTrue: [ ^ 0 ].
	^ transition offsetFromUTC
]

{ #category : 'public' }
GbxTimeZoneInfo >> offsetAtUTC: aDateAndTime [
	| transition |
	transition := self transitionAtUTC: aDateAndTime.
	transition isNil ifTrue: [ ^ 0 ].
	^ transition offsetFromUTC
]

{ #category : 'accessing' }
GbxTimeZoneInfo >> transitions [
	^ transitions ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxTimeZoneInfo >> transitions: aCollection [
	transitions := aCollection asArray
]

{ #category : 'public' }
GbxTimeZoneInfo >> transitionAtLocal: aDateAndTime [
	| seconds |
	seconds := aDateAndTime asUnixTime.
	^ self detectLastTransition: [ :each | each transitionTimeLocal <= seconds ]
]

{ #category : 'public' }
GbxTimeZoneInfo >> transitionAtUTC: aDateAndTime [
	| seconds |
	seconds := aDateAndTime asUnixTime.
	^ self detectLastTransition: [ :each | each transitionTimeUTC <= seconds ]
]
