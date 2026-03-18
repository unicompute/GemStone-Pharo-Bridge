Class {
	#name : 'GbsTimeZone',
	#superclass : 'Object',
	#instVars : [
		'secondsFromGMT',
		'secondsForDST',
		'dayOfYearForDST',
		'dayOfWeekForDST',
		'secondsBeginDST',
		'dayOfYearForStandard',
		'dayOfWeekForStandard',
		'secondsBeginStandard'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'deprecated' }
GbsTimeZone >> localTimeFromGMT: aGMTTime 
[
	"Convert the GMT Time to a local Time, returned as a new instance.
	 The argument is not modified."

	| gmtDiff |
	GbsConfiguration 
		deprecated: 'GbsSession>>localTimeFromGMT: deprecated March, 2007.'.
	gmtDiff := (self isDST: self datetimeClass now) 
				ifTrue: [secondsFromGMT + secondsForDST]
				ifFalse: [secondsFromGMT].
	^self wrappedTimeFromSeconds: aGMTTime asSeconds + gmtDiff
]

{ #category : 'deprecated' }
GbsTimeZone >> gmtTimeFromLocal: aLocalTime 
[
	"Convert the local Time to a GMT Time, based on whether we are currently
	 in daylight savings time.  Return a new instance of Time - the argument is
	 not modified."

	| gmtDiff |
	GbsConfiguration 
		deprecated: 'GbsSession>>gmtTimeFromLocal: deprecated March, 2007.'.
	gmtDiff := (self isDST: self datetimeClass now) 
				ifTrue: [secondsFromGMT + secondsForDST]
				ifFalse: [secondsFromGMT].
	^self wrappedTimeFromSeconds: aLocalTime asSeconds - gmtDiff
]

{ #category : 'comparing' }
GbsTimeZone >> = aGbsTimeZone
[

	self == aGbsTimeZone ifTrue: [ ^true ].
	(aGbsTimeZone isMemberOf: self class) ifFalse: [ ^false ].

	^aGbsTimeZone
		equalsSecondsFromGMT: secondsFromGMT
		secondsForDST: secondsForDST
		dayOfYearForDST: dayOfYearForDST
		dayOfWeekForDST: dayOfWeekForDST
		secondsBeginDST: secondsBeginDST
		dayOfYearForStandard: dayOfYearForStandard
		dayOfWeekForStandard: dayOfWeekForStandard
		secondsBeginStandard: secondsBeginStandard
]

{ #category : 'comparing' }
GbsTimeZone >> hash
[

	^secondsFromGMT hash
]

{ #category : 'GBS private' }
GbsTimeZone >> localToUniversal: localTimestamp
[
	"Convert the local DateTime to a GMT DateTime, returned as a new instance.
	 The argument is not modified."

	| gmtDiff |
	gmtDiff := (self isDST: localTimestamp)
				ifTrue: [secondsFromGMT + secondsForDST]
				ifFalse: [secondsFromGMT].
	^localTimestamp class
		fromMilliseconds: localTimestamp asMilliseconds - (gmtDiff * 1000)
]

{ #category : 'initialization' }
GbsTimeZone >> secondsFromGMT: secsFromGMT
[
secondsForDST: secsForDST
dayOfYearForDST: doyForDST
dayOfWeekForDST: dowForDST
secondsBeginDST: secsBeginDST
dayOfYearForStandard: doyForStandard
dayOfWeekForStandard: dowForStandard
secondsBeginStandard: secsBeginStandard

	secondsFromGMT := secsFromGMT.  "Number of seconds the time zone is offset from GMT"
	secondsForDST := secsForDST.  "Number of seconds to shift for daylight savings time"
	dayOfYearForDST := doyForDST.  "Day of year index to start daylight savings"
	dayOfWeekForDST := dowForDST.  "Day of week index (Monday is 1, Sunday is 7) to start daylight savings"
	secondsBeginDST := secsBeginDST.  "Seconds after midnight to begin daylight savings"
	dayOfYearForStandard := doyForStandard.  "Day of year index to start standard time"
	dayOfWeekForStandard := dowForStandard.  "Day of week index (Monday is 1, Sunday is 7) to start standard time"
	secondsBeginStandard := secsBeginStandard.  "Seconds after midnight to begin standard time"
]

{ #category : 'private' }
GbsTimeZone >> equalsSecondsFromGMT: sfgmt secondsForDST: sfdst dayOfYearForDST: dydst dayOfWeekForDST: dwdst secondsBeginDST: sbdst dayOfYearForStandard: dystd dayOfWeekForStandard: dwstd secondsBeginStandard: sbstd
[
	^secondsFromGMT = sfgmt
	and: [ secondsForDST = sfdst
	and: [ dayOfYearForDST = dydst
	and: [ dayOfWeekForDST = dwdst
	and: [ secondsBeginDST = sbdst
	and: [ dayOfYearForStandard = dystd
	and: [ dayOfWeekForStandard = dwstd
	and: [ secondsBeginStandard = sbstd ]]]]]]]
]

{ #category : 'private' }
GbsTimeZone >> wrappedTimeFromSeconds: anInteger
[

	"Return a new Time from anInteger seconds, which might
	 be wrapped before or after midnight."

	| seconds |
	seconds := anInteger.
	"Check for wraparound to next day"
	seconds > 86400 ifTrue: [ seconds := seconds - 86400 ].
	"Check for wraparound to previous day"
	seconds < 0 ifTrue: [ seconds := seconds + 86400 ].
	^Time fromSeconds: seconds
]

{ #category : 'gmt conversion' }
GbsTimeZone >> isDST: aDateTime 
[
	"Return true if aDateTime falls in daylight savings time, false otherwise"

	| start end |
	secondsForDST == 0 ifTrue: [^false].
	start := self startOfDSTInYear: aDateTime year.
	end := self startOfStandardInYear: aDateTime year.
	start < end 
		ifTrue: [^aDateTime >= start and: [aDateTime < end]]
		ifFalse: [^aDateTime >= start or: [aDateTime < end]]
]

{ #category : 'gmt conversion' }
GbsTimeZone >> localDateTimeFromGMT: gmtDateTime
[
	"Convert the GMT DateTime to a local DateTime, returned as a new instance.
	 The argument is not modified."
	"first convert the DateTime to local time, then decide when if the time is in 
	Daylight Savings Time. If so, adjust."

	| localDateTime |
	localDateTime := self datetimeClass
				fromMilliseconds: gmtDateTime asMilliseconds + (secondsFromGMT * 1000).
	^(self isDST: localDateTime)
		ifTrue: [localDateTime addSeconds: secondsForDST]
		ifFalse: [localDateTime]
]

{ #category : 'gmt conversion' }
GbsTimeZone >> gmtDateTimeFromLocal: localTimestamp
[
	"Convert the local DateTime to a GMT DateTime, returned as a new instance.
	 The argument is not modified."

	^self localToUniversal: localTimestamp
]

{ #category : 'gmt conversion' }
GbsTimeZone >> startOfDSTInYear: year
[

	"Return a Timestamp marking the beginning of daylight savings time in the given year"
	| theDay |
	"If it's after leap day in a leap year, add one to dayOfYearForDST"
	theDay := dayOfYearForDST > 60
		ifTrue: [ dayOfYearForDST + (Date leapYear: year) ]
		ifFalse: [ dayOfYearForDST ].
	"If this day falls on dayOfWeek, that's the one.  Otherwise, find previous dayOfWeek"
	theDay := (Date newDay: theDay + 1 year: year) previous: (Date nameOfDay: dayOfWeekForDST).
	^self datetimeClass
		date: theDay
		time: (Time fromSeconds: secondsBeginDST)
]

{ #category : 'gmt conversion' }
GbsTimeZone >> startOfStandardInYear: year
[

	"Return a Timestamp marking the end of daylight savings time in the given year"
	| theDay |
	"If it's after leap day in a leap year, add one to dayOfYearForStandard"
	theDay := dayOfYearForStandard > 60
		ifTrue: [ dayOfYearForStandard + (Date leapYear: year) ]
		ifFalse: [ dayOfYearForStandard ].
	"If this day falls on dayOfWeek, that's the one.  Otherwise, find previous dayOfWeek"
	theDay := (Date newDay: theDay + 1 year: year) previous: (Date nameOfDay: dayOfWeekForStandard).
	^self datetimeClass
		date: theDay
		time: (Time fromSeconds: secondsBeginStandard)
]

{ #category : 'printing' }
GbsTimeZone >> printOn: aStream
[

	| nm |
	nm := nil.
	NamedTimeZones isNil
		ifFalse: [NamedTimeZones keysAndValuesDo: [ :k :v | v = self ifTrue: [ nm := k ]]].
	nm isNil
		ifTrue: [ self printVerboseOn: aStream ]
		ifFalse: [ aStream nextPut: $(; nextPutAll: self class name; nextPutAll: ' named: #'; nextPutAll: nm; nextPut: $) ]
]

{ #category : 'printing' }
GbsTimeZone >> printVerboseOn: aStream
[

	aStream
		nextPut: $(;
		nextPutAll: self class name;
		space.
	aStream cr; nextPutAll: '	secondsFromGMT: '.
	secondsFromGMT printOn: aStream.
	aStream cr; nextPutAll: '	secondsForDST: '.
	secondsForDST printOn: aStream.
	aStream cr; nextPutAll: '	dayOfYearForDST: '.
	dayOfYearForDST printOn: aStream.
	aStream cr; nextPutAll: '	dayOfWeekForDST: '.
	dayOfWeekForDST printOn: aStream.
	aStream cr; nextPutAll: '	secondsBeginDST: '.
	secondsBeginDST printOn: aStream.
	aStream cr; nextPutAll: '	dayOfYearForStandard: '.
	dayOfYearForStandard printOn: aStream.
	aStream cr; nextPutAll: '	dayOfWeekForStandard: '.
	dayOfWeekForStandard printOn: aStream.
	aStream cr; nextPutAll: '	secondsBeginStandard: '.
	secondsBeginStandard printOn: aStream.
	aStream nextPut: $)
]

{ #category : 'class initialization' }
GbsTimeZone class >> initialize
[

	"GbsTimeZone initialize"
	self initializeNamedTimeZones
]

{ #category : 'class initialization' }
GbsTimeZone class >> current: aGbsTimeZone
[

	"Specify a timezone object representing the image's current timezone,
	 which wil be used for converting client Timezone & Time objects (which
	 are represented in local time) into GemStone DateTime and Time objects
	 (which are representing in GMT)"

	"Example for Pacific Standard:"
	"GbsTimeZone current:
	(GbsTimeZone
		secondsFromGMT: -28800
		secondsForDST: 3600
		dayOfYearForDST: 97
		dayOfWeekForDST: 7
		secondsBeginDST: 7200
		dayOfYearForStandard: 304
		dayOfWeekForStandard: 7
		secondsBeginStandard: 7200
	)."

	CurrentTimeZone := aGbsTimeZone
]

{ #category : 'class initialization' }
GbsTimeZone class >> gbsClassUnloading
[

	NamedTimeZones := nil.
	CurrentTimeZone := nil.
]

{ #category : 'class initialization' }
GbsTimeZone class >> initializeNamedTimeZones
[

	"GbsTimeZone initializeNamedTimeZones"

	NamedTimeZones := Dictionary new.
	NamedTimeZones
		at: #Pacific
		put: (GbsTimeZone
				secondsFromGMT: -28800
				secondsForDST: 3600
				dayOfYearForDST: 97 "Apr 7"
				dayOfWeekForDST: 7
				secondsBeginDST: 7200
				dayOfYearForStandard: 304 "Oct 31"
				dayOfWeekForStandard: 7
				secondsBeginStandard: 7200);
		at: #Eastern
		put: (GbsTimeZone
				secondsFromGMT: -18000
				secondsForDST: 3600
				dayOfYearForDST: 97 "Apr 7"
				dayOfWeekForDST: 7
				secondsBeginDST: 7200
				dayOfYearForStandard: 304 "Oct 31"
				dayOfWeekForStandard: 7
				secondsBeginStandard: 7200);
		at: #GreatBritain
		put: (GbsTimeZone
				secondsFromGMT: 0
				secondsForDST: 3600
				dayOfYearForDST: 89 "Mar 31"
				dayOfWeekForDST: 7
				secondsBeginDST: 3600
				dayOfYearForStandard: 304 "Oct 31"
				dayOfWeekForStandard: 7
				secondsBeginStandard: 3600);
		at: #Greenwich
		put: (GbsTimeZone
				secondsFromGMT: 0
				secondsForDST: 0
				dayOfYearForDST: 0
				dayOfWeekForDST: 0
				secondsBeginDST: 0
				dayOfYearForStandard: 0
				dayOfWeekForStandard: 0
				secondsBeginStandard: 0);
		at: #Germany
		put: (GbsTimeZone
				secondsFromGMT: 3600
				secondsForDST: 3600
				dayOfYearForDST: 89 "Mar 31"
				dayOfWeekForDST: 7
				secondsBeginDST: 3600
				dayOfYearForStandard: 304 "end of October"
				dayOfWeekForStandard: 7
				secondsBeginStandard: 3600);
		at: #Japan
		put: (GbsTimeZone
				secondsFromGMT: 32400
				secondsForDST: 0
				dayOfYearForDST: 0
				dayOfWeekForDST: 0
				secondsBeginDST: 0
				dayOfYearForStandard: 0
				dayOfWeekForStandard: 0
				secondsBeginStandard: 0)
]

{ #category : 'instance creation' }
GbsTimeZone class >> named: aSymbol
[

	"Returns a predefined instance of GbsTimeZone stored with the name aSymbol,
	 or raises an error if there is no predefined GbsTimeZone with that name"
	"GbsTimeZone named: #Pacific"
	^NamedTimeZones
		at: aSymbol
		ifAbsent: [ self gbsMessenger error: 'No GbsTimeZone named %1.  Valid names are: %2' with: aSymbol with: self names ]
]

{ #category : 'instance creation' }
GbsTimeZone class >> names
[

	"Returns an array of symbols representing predefined GbsTimeZone instances
	 that can be retrieved using GbsTimeZone class>>named:"
	^NamedTimeZones keys asArray
]

{ #category : 'instance creation' }
GbsTimeZone class >> current
[

	"Return a timezone object representing the image's current timezone"
	self basicCurrent isNil ifTrue: [
		self current: self clientDefaultInstance.
		self basicCurrent isNil
			ifTrue: [^self gbsMessenger error: 'A time zone must be specified using GbsTimeZone current:' ]
	].
	^self basicCurrent
]

{ #category : 'instance creation' }
GbsTimeZone class >> secondsFromGMT: secondsFromGMT secondsForDST: secondsForDST dayOfYearForDST: dayOfYearForDST dayOfWeekForDST: dayOfWeekForDST secondsBeginDST: secondsBeginDST dayOfYearForStandard: dayOfYearForStandard dayOfWeekForStandard: dayOfWeekForStandard secondsBeginStandard: secondsBeginStandard
[
	"Return a new instance of the receiver describing a time zone"

	^self new
		secondsFromGMT: secondsFromGMT  "Number of seconds the time zone is offset from GMT"
		secondsForDST: secondsForDST  "Number of seconds to shift for daylight savings time"
		dayOfYearForDST: dayOfYearForDST  "Day of year index to start daylight savings"
		dayOfWeekForDST: dayOfWeekForDST  "Day of week index (Monday is 1, Sunday is 7) to start daylight savings"
		secondsBeginDST: secondsBeginDST  "Seconds after midnight to begin daylight savings"
		dayOfYearForStandard: dayOfYearForStandard  "Day of year index to start standard time"
		dayOfWeekForStandard: dayOfWeekForStandard  "Day of week index (Monday is 1, Sunday is 7) to start standard time"
		secondsBeginStandard: secondsBeginStandard  "Seconds after midnight to begin standard time"
]

{ #category : 'private' }
GbsTimeZone class >> basicCurrent
[

	^CurrentTimeZone
]

