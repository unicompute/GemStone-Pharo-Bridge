Class {
	#name : 'GbxTimeZoneTransition',
	#superclass : 'Object',
	#instVars : [
		'transitionTimeUTC',
		'transitionTimeLocal',
		'offsetFromUTC',
		'isDST',
		'abbreviation'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxTimeZoneTransition class >> utc: utcSeconds local: localSeconds offset: offsetSeconds isDST: aBoolean abbreviation: aString [
	^ self new
		transitionTimeUTC: utcSeconds;
		transitionTimeLocal: localSeconds;
		offsetFromUTC: offsetSeconds;
		isDST: aBoolean;
		abbreviation: aString;
		yourself
]

{ #category : 'accessing' }
GbxTimeZoneTransition >> abbreviation [
	^ abbreviation
]

{ #category : 'accessing' }
GbxTimeZoneTransition >> abbreviation: aString [
	abbreviation := aString
]

{ #category : 'testing' }
GbxTimeZoneTransition >> isDST [
	^ isDST ifNil: [ false ]
]

{ #category : 'accessing' }
GbxTimeZoneTransition >> isDST: aBoolean [
	isDST := aBoolean
]

{ #category : 'accessing' }
GbxTimeZoneTransition >> offsetFromUTC [
	^ offsetFromUTC ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxTimeZoneTransition >> offsetFromUTC: anInteger [
	offsetFromUTC := anInteger
]

{ #category : 'accessing' }
GbxTimeZoneTransition >> transitionTimeLocal [
	^ transitionTimeLocal ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxTimeZoneTransition >> transitionTimeLocal: anInteger [
	transitionTimeLocal := anInteger
]

{ #category : 'accessing' }
GbxTimeZoneTransition >> transitionTimeUTC [
	^ transitionTimeUTC ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxTimeZoneTransition >> transitionTimeUTC: anInteger [
	transitionTimeUTC := anInteger
]
