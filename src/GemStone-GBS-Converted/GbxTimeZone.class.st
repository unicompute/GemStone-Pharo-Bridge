Class {
	#name : 'GbxTimeZone',
	#superclass : 'GbxTimeZoneInfo',
	#instVars : [
		'standardPrintString',
		'dstPrintString'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbxTimeZone >> = aTimeZone [
	^ aTimeZone class = self class
		and: [ self transitions = aTimeZone transitions
		and: [ self leapSeconds = aTimeZone leapSeconds ] ]
]

{ #category : 'singleton' }
GbxTimeZone class >> default [
	^ GbxTimeZoneInfo default
]

{ #category : 'instance creation' }
GbxTimeZone class >> newLocalDefault [
	| offset now transition zone |
	now := DateAndTime now.
	offset := now offset asSeconds.
	transition := GbxTimeZoneTransition
		utc: 0
		local: offset
		offset: offset
		isDST: false
		abbreviation: now offset printString.
	zone := self new.
	zone
		transitions: { transition };
		leapSeconds: #();
		standardPrintString: now offset printString;
		dstPrintString: now offset printString.
	^ zone
]

{ #category : 'accessing' }
GbxTimeZone >> dstPrintString: aString [
	dstPrintString := aString
]

{ #category : 'accessing' }
GbxTimeZone >> standardPrintString: aString [
	standardPrintString := aString
]
