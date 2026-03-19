Extension { #name : #'Time' }

{ #category : '*GemStone-GBS-Converted-GBS-private' }
Time class >> gbsReplicatorClass [

	^GbxTimeReplicator
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
Time class >> gbxHours: h minutes: m seconds: s [
	"Private.  GBS.  For instance creation portability."

	^self fromSeconds: (h * 3600) + (m * 60) + s
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
Time >> postFault [
	"Private.  GBS.  GemStone replication support.  Convert GemStone milliseconds to VisualWorks hours/minutes/seconds/milliseconds."
	"GemStone milliseconds was mapped into the milliseconds instvar"

	| secs secsIntoHour millisecondsHolder |
	millisecondsHolder := milliseconds.
	self initialize.	"in VW 7.10, sets all instVars to 0"
	milliseconds := millisecondsHolder \\ 1000.
	secs := millisecondsHolder // 1000.
	secsIntoHour := secs \\ 3600.
	hours := secs // 3600.
	minutes := secsIntoHour // 60.
	seconds := secsIntoHour \\ 60
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
Time >> asGSObjectInSession: aGbsSession [
	"Private.  GBS.  Look up or create a delegate for me. If I'm in range to be an immediate 
	in this session, create a delegate for that. Otherwise, look up my POM oop mapping, 
	or create a new mapping if I'm unmapped."

	| delegate |
	delegate := self gbxExistingOrSpecialDelegateInSession: aGbsSession.
	^delegate == nil
		ifTrue: [super asGSObjectInSession: aGbsSession]
		ifFalse: [delegate]
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
Time >> gbxExistingOrSpecialDelegateInSession: aGbsSession [
	"Private.  GBS.  If I am within the range to be an immediate in this session, 
	create and answer that delegate.
	Otherwise answer my mapped delegate, or nil if none."

	| delegate |
	delegate := aGbsSession delegateForSpecialTime: self.
	^delegate isNil
		ifTrue: [super gbxExistingOrSpecialDelegateInSession: aGbsSession]
		ifFalse: [delegate]
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
Time >> gbxIsServerSpecialInSession: aSession [

	^aSession isSpecialTime: self.
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
Time class >> gbxClock [
	"return the lowest resolution clock value available,  millisecondClockValue in vw5i or microsecondClock in vw7x and later"

	^self microsecondClock
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Time class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Time class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Time class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Time >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Time >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Time >> isRunningUnderAssertingVM [
	^false
]

