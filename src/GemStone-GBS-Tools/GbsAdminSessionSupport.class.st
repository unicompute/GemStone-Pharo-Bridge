Class {
	#name : 'GbsAdminSessionSupport',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbsAdminSessionSupport class >> currentUsableSession [
	| session |
	session := GbsSessionParameters currentSession.
	session ifNil: [ ^ nil ].
	(session respondsTo: #isLoggedIn)
		ifTrue: [ ^ ([ session isLoggedIn == true ] on: Error do: [ false ])
			ifTrue: [ session ]
			ifFalse: [ nil ] ].
	^ session
]

{ #category : 'accessing' }
GbsAdminSessionSupport class >> currentUsableSessionOrInform [
	| session |
	session := self currentUsableSession.
	session ifNil: [
		UIManager default inform: 'No connected GemStone session. Please login first.' ].
	^ session
]
