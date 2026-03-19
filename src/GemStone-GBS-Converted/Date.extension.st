Extension { #name : #'Date' }

{ #category : '*GemStone-GBS-Converted-GBS-private' }
Date class >> gbsReplicatorClass [

	^GbxPointerMagnitudeReplicator
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
Date class >> instVarMap [
	"GBS"

	^super instVarMap ,
		#( (day dayOfYear) )
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
Date class >> gbxMonth: m day: d year: y [

	"GemStone private.  For instance creation portability."
	^self newDay: d monthNumber: m year: y
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
Date >> gbxExistingOrSpecialDelegateInSession: aGbsSession [
	"Private.  GBS.  If I am within the range to be an immediate in this session, 
	create and answer that delegate.
	Otherwise answer my mapped delegate, or nil if none."

	| delegate |
	delegate := aGbsSession delegateForSpecialDate: self.
	^delegate isNil
		ifTrue: [super gbxExistingOrSpecialDelegateInSession: aGbsSession]
		ifFalse: [delegate]
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
Date >> gbxIsServerSpecialInSession: aSession [

	^aSession isSpecialDate: self.
]

{ #category : '*GemStone-GBS-Converted-GemStone-extensions' }
Date >> asGSObjectInSession: aGbsSession [
	"Private.  GBS.  Look up or create a delegate for me. If I'm in range to be an immediate 
	in this session, create a delegate for that. Otherwise, look up my POM oop mapping, 
	or create a new mapping if I'm unmapped."

	| delegate |
	delegate := self gbxExistingOrSpecialDelegateInSession: aGbsSession.
	^delegate == nil
		ifTrue: [super asGSObjectInSession: aGbsSession]
		ifFalse: [delegate]
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Date class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Date class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Date class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Date >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Date >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Date >> isRunningUnderAssertingVM [
	^false
]

