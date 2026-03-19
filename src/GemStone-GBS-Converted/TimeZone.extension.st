Extension { #name : #'TimeZone' }

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
TimeZone >> dayOfWeekForDST [
	"Private.  GBS.  Return an integer representing the day of
	 the week to start daylight savings time.  Monday is 1, Sunday is 7."

	^Date dayOfWeek: self weekDayToStartDST
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
TimeZone >> dayOfWeekForStandard [
	"Private.  GBS.  Return an integer representing the day of
	 the week to start standard time.  Monday is 1, Sunday is 7."

	^Date dayOfWeek: self weekDayToStartDST
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
TimeZone >> dayOfYearForDST [
	"Private.  GBS.  Return an integer representing the day of the year
	 to begin daylight savings time.  The actual day for any given year will be
	 adjusted to fall on the previous dayOfWeekForDST"

	^dayStartDST
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
TimeZone >> dayOfYearForStandard [
	"Private.  GBS.  Return an integer representing the day of the year
	 to begin standard time.  The actual day for any given year will be
	 adjusted to fall on the previous dayOfWeekForStandard"

	^dayEndDST
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
TimeZone >> secondsForDST [
	"Private.  GBS.  Return an integer representing the number of
	 seconds to shift for daylight savings time."

	^secondsForDST
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
TimeZone >> secondsBeginDST [
	"Private.  GBS.  Return an integer representing the number of
	 seconds into the day to begin daylight savings time."

	^timeStartDST
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
TimeZone >> secondsBeginStandard [
	"Private.  GBS.  Return an integer representing the number of
	 seconds into the day to begin standard time."

	^timeEndDST
]

{ #category : '*GemStone-GBS-Converted-accessing' }
TimeZone class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
TimeZone class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
TimeZone class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
TimeZone >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
TimeZone >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
TimeZone >> isRunningUnderAssertingVM [
	^false
]

