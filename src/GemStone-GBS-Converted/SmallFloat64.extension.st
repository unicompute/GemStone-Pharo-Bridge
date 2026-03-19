Extension { #name : #'SmallFloat64' }

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
SmallFloat64 >> gbxIsServerSpecialInSession: aSession [
	"Sender must hold sessionProtect"

	^aSession isSpecialDouble: self
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
SmallFloat64 >> gbxCouldBeForwarder [
	"Private GBS.  Answer boolean whether the receiver can become a forwarder."

	^false
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
SmallFloat64 >> gbxDelegate [
	"Private.  Return the delegate or delegates cached for the receiver, or nil if no such delegates."

	^nil	"Objects that are special on the server do not have delegates."
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
SmallFloat64 >> asGSObjectInSession: aGbsSession [
	"Private to GBS.  Given the Smalltalk object <self>, find an existing or create a new corresponding delegate."
	"This method will only be executed if you have a SmallFloat64 instance. This implies 64-bit VW, which implies
	64-bit oops on the server. So we don't have to worry about other cases here."

	^aGbsSession sessionCritical: [aGbsSession delegateForSpecialDouble: self]
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
SmallFloat64 >> gbxIdentityHash [
	"SmallDoubles are not used as keys in GBS dictionaries, but GbsStackDumper wants to send this message to anyone who can understand it, and the implementation in Object fails, so we'll just make it answer the identity hash."

	^self identityHash
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SmallFloat64 class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SmallFloat64 class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SmallFloat64 class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SmallFloat64 >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SmallFloat64 >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SmallFloat64 >> isRunningUnderAssertingVM [
	^false
]

