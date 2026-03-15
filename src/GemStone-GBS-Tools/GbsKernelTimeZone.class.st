Class {
	#name : 'GbsKernelTimeZone',
	#superclass : 'Object',
	#instVars : [
		'offset',
		'name',
		'daylightSavings'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsKernelTimeZone class >> current [
	"Get the current time zone"
	^ self new
		initializeFromSystem;
		yourself
]

{ #category : 'instance creation' }
GbsKernelTimeZone class >> named: aString [
	"Create a time zone by name"
	^ self new
		name: aString;
		yourself
]

{ #category : 'conversion' }
GbsKernelTimeZone >> convertGemStoneTime: gsTime toLocal: ignoredFlag [
	"Convert GemStone internal time to local DateAndTime"
	| epoch seconds localTime |
	
	"GemStone uses seconds since Jan 1, 1901"
	epoch := DateAndTime year: 1901 month: 1 day: 1 hour: 0 minute: 0 second: 0.
	seconds := gsTime.
	
	localTime := epoch + seconds seconds.
	
	"Apply timezone offset"
	offset ifNotNil: [
		localTime := localTime + offset seconds.
	].
	
	^ localTime.
]

{ #category : 'conversion' }
GbsKernelTimeZone >> convertLocalTime: localTime toGemStone: ignoredFlag [
	"Convert local DateAndTime to GemStone internal time"
	| epoch seconds gsTime |
	
	"GemStone uses seconds since Jan 1, 1901"
	epoch := DateAndTime year: 1901 month: 1 day: 1 hour: 0 minute: 0 second: 0.
	seconds := localTime - epoch.
	
	gsTime := seconds asSeconds.
	
	"Apply timezone offset"
	offset ifNotNil: [
		gsTime := gsTime - offset.
	].
	
	^ gsTime.
]

{ #category : 'initialization' }
GbsKernelTimeZone >> initialize [
	super initialize.
	offset := 0.
	name := 'UTC'.
	daylightSavings := false.
]

{ #category : 'initialization' }
GbsKernelTimeZone >> initializeFromSystem [
	"Initialize from system time zone"
	| zone |
	
	zone := Timezone current.
	zone ifNotNil: [
		name := zone name.
		offset := zone offset.
		daylightSavings := zone isDaylightSavings.
	].
]

{ #category : 'accessing' }
GbsKernelTimeZone >> daylightSavings [
	^ daylightSavings ifNil: [ false ]
]

{ #category : 'accessing' }
GbsKernelTimeZone >> daylightSavings: aBoolean [
	daylightSavings := aBoolean
]

{ #category : 'accessing' }
GbsKernelTimeZone >> name [
	^ name
]

{ #category : 'accessing' }
GbsKernelTimeZone >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbsKernelTimeZone >> offset [
	^ offset ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsKernelTimeZone >> offset: anInteger [
	offset := anInteger
]

{ #category : 'accessing' }
GbsKernelTimeZone >> printString [
	^ name, ' (UTC', (offset >= 0 ifTrue: [ '+' ] ifFalse: [ '-' ]),
	  (offset abs // 3600) asString, ':',
	  ((offset abs \\ 3600) // 60 printPaddedWith: $0 to: 2), ')'
]
