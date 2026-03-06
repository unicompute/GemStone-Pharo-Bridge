Extension { #name : 'String' }

{ #category : '*GemStone-GBS-Tools-compatibility' }
String >> withBlanksTrimmed [
	| start stop |
	(self respondsTo: #trimBoth) ifTrue: [ ^ self trimBoth ].
	start := 1.
	stop := self size.
	[ start <= stop and: [ (self at: start) isSeparator ] ] whileTrue: [ start := start + 1 ].
	[ stop >= start and: [ (self at: stop) isSeparator ] ] whileTrue: [ stop := stop - 1 ].
	^ start <= stop
		ifTrue: [ self copyFrom: start to: stop ]
		ifFalse: [ '' ]
]
