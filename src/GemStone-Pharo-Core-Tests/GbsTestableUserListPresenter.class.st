Class {
	#name : 'GbsTestableUserListPresenter',
	#superclass : 'GbsUserListPresenter',
	#instVars : [
		'forcedSelectedUser',
		'fixedInfoText',
		'openWindowResult',
		'fallbackResult',
		'didOpenWindow',
		'didFallback',
		'openedUser',
		'openedText',
		'openedSession'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
GbsTestableUserListPresenter >> connectPresenters [
	"Prevent live session refresh from superclass during test construction."
]

{ #category : 'accessing' }
GbsTestableUserListPresenter >> forcedSelectedUser: aString [
	forcedSelectedUser := aString
]

{ #category : 'accessing' }
GbsTestableUserListPresenter >> fixedInfoText: aString [
	fixedInfoText := aString
]

{ #category : 'accessing' }
GbsTestableUserListPresenter >> openWindowResult: aBoolean [
	openWindowResult := aBoolean == true
]

{ #category : 'accessing' }
GbsTestableUserListPresenter >> fallbackResult: aBoolean [
	fallbackResult := aBoolean == true
]

{ #category : 'accessing' }
GbsTestableUserListPresenter >> didOpenWindow [
	^ didOpenWindow == true
]

{ #category : 'accessing' }
GbsTestableUserListPresenter >> didFallback [
	^ didFallback == true
]

{ #category : 'accessing' }
GbsTestableUserListPresenter >> openedUser [
	^ openedUser
]

{ #category : 'accessing' }
GbsTestableUserListPresenter >> openedText [
	^ openedText
]

{ #category : 'accessing' }
GbsTestableUserListPresenter >> openedSession [
	^ openedSession
]

{ #category : 'private' }
GbsTestableUserListPresenter >> selectedUserName [
	^ forcedSelectedUser
]

{ #category : 'private' }
GbsTestableUserListPresenter >> userInfoTextFor: userName [
	^ fixedInfoText ifNil: [ 'User: ', userName ]
]

{ #category : 'private' }
GbsTestableUserListPresenter >> openUserInfoWindowFor: userName text: infoTextValue session: aSession [
	didOpenWindow := true.
	openedUser := userName.
	openedText := infoTextValue.
	openedSession := aSession.
	^ openWindowResult ifNil: [ true ]
]

{ #category : 'private' }
GbsTestableUserListPresenter >> openUserInfoFallbackText: infoTextValue forUser: userName [
	didFallback := true.
	openedUser := userName.
	openedText := infoTextValue.
	^ fallbackResult ifNil: [ true ]
]

{ #category : 'actions' }
GbsTestableUserListPresenter >> showSelectedUserInfo [
	| userName info opened |
	userName := self selectedUserName.
	userName ifNil: [ ^ self ].
	info := self userInfoTextFor: userName.
	opened := self
		openUserInfoWindowFor: userName
		text: info
		session: (self instVarNamed: 'session').
	opened ifFalse: [
		self openUserInfoFallbackText: info forUser: userName ]
]
