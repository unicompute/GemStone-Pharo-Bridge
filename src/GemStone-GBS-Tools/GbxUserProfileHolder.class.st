Class {
	#name : 'GbxUserProfileHolder',
	#superclass : 'Object',
	#instVars : [
		'remoteUserProfile',
		'session',
		'newDefaultSegment',
		'newPrivileges',
		'newSymbDicts',
		'newUserId',
		'cachedUserId'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'comparing' }
GbxUserProfileHolder >> hash
[

	^self class hash + self userId hash
]

{ #category : 'comparing' }
GbxUserProfileHolder >> <= aGSUserProfileHolder
[

	^ self userId <= aGSUserProfileHolder userId
]

{ #category : 'comparing' }
GbxUserProfileHolder >> = aGSUserProfileHolder
[

	" Answer true if I am equivalent to aGSUserProfileHolder. "

	^ self class == aGSUserProfileHolder class
		and: [self userId = aGSUserProfileHolder userId]
]

{ #category : 'accessing' }
GbxUserProfileHolder >> privileges
[

	" Answer an array of symbols identifying this user's privileges on GemStone.
	NOTE:  For new users, answer a unique array (i.e. not #()), as different
		sessions may choke if the same object is in more than one session. "

	self newPrivileges notNil ifTrue:
		[^ self newPrivileges ].
	^ self isNewUser
		ifTrue: [ Array new ]
		ifFalse: [self basicPrivileges]
]

{ #category : 'accessing' }
GbxUserProfileHolder >> basicPrivileges
[

	" Answer an array of symbols identifying this user's privileges on GemStone. "

	^ self remoteUserProfile privileges
]

{ #category : 'accessing' }
GbxUserProfileHolder >> language
[

	" Answer the language from the receiver's UserProfile. "

	self isNewUser ifTrue:
		[^ 'English' ].
	^ self remoteUserProfile nativeLanguage
]

{ #category : 'accessing' }
GbxUserProfileHolder >> remoteUserProfile
[
	" Answer the value of remoteUserProfile, a forwarder to a UserProfile on GemStone. "

	^remoteUserProfile
]

{ #category : 'accessing' }
GbxUserProfileHolder >> resetCachedUserId
[

	cachedUserId := nil
]

{ #category : 'accessing' }
GbxUserProfileHolder >> cachedUserId: aSymbol
[

	cachedUserId := aSymbol
]

{ #category : 'accessing' }
GbxUserProfileHolder >> createNewDefaultSegment
[
	" Answer a new Object Security Policy identifying this user's default one on GemStone. "

	^self session
		execute: '
| securityPolicy |
securityPolicy := GsObjectSecurityPolicy new.
securityPolicy worldAuthorization: #read.
GsCurrentSession currentSession commitTransaction.
securityPolicy'
]

{ #category : 'accessing' }
GbxUserProfileHolder >> userForwarderFor: aSymbol
[

	" Answer an UNCACHED forwarder for the object whose name is aSymbol my symbol lists. "

	| assn |

	self isNewUser ifTrue:
		[^ self internalForwarderFor: aSymbol ].
	assn := self remoteUserProfile ucfwresolveSymbol: aSymbol.
	assn isNil ifTrue:
		[^ self error: aSymbol printString , ' not defined'].
	^ assn ucfwvalue
]

{ #category : 'accessing' }
GbxUserProfileHolder >> defaultSegment
[
	" Answer a forwarder to a Object Security Policy which is this user's default one on GemStone. "

	self newDefaultSegment notNil ifTrue:
		[^ self newDefaultSegment ].
	self isNewUser ifFalse:
		[^ self basicDefaultSegment ].
	^ self createNewDefaultSegment
]

{ #category : 'accessing' }
GbxUserProfileHolder >> dictionaries
[

	" Answer a list of symbol dictionaries available to me. "

	| symList userDicts |

	self isNewUser ifTrue:
		[^ self newSymbDicts collect:
			[: aSymbolListDictionaryForwarder |
			GbxSymbolListDictionaryHolder on: aSymbolListDictionaryForwarder ]].
	userDicts := OrderedCollection new.
	symList := self remoteUserProfile ucfwsymbolList.
	1 to: symList size do:
		[: ix |
		userDicts add: (GbxSymbolListDictionaryHolder on: (symList ucfwat: ix) "beForwarder").].
	^ userDicts
]

{ #category : 'accessing' }
GbxUserProfileHolder >> userId
[
	" Answer the unique user identifier (a Symbol) associated with the receiver. "

	self newUserId notNil | self isNewUser ifTrue:
		[^ self newUserId ].
	^ self gemStoneUserId
]

{ #category : 'accessing' }
GbxUserProfileHolder >> groups
[
	" Answer the groups from the receiver's UserProfile.
	  WARNING:  We used to return #(), but it sometimes got stubbed. "

	self isNewUser ifTrue: [^Array new].
	^(self remoteUserProfile gbxDelegate session
		evaluate: '(self groups collect:[:ea | ea asString]) asSet asSortedCollection '
		context: self remoteUserProfile gbxDelegate) asList
]

{ #category : 'accessing' }
GbxUserProfileHolder >> gemStoneUserId
[
	" Answer the unique user identifier (a Symbol) currently associated with the receiver on GemStone. "

	self isNewUser ifTrue: [^self userId].
	cachedUserId isNil
		ifTrue: [cachedUserId := self remoteUserProfile ucfwuserId asGSObject asLocalObject].
	^cachedUserId
]

{ #category : 'accessing' }
GbxUserProfileHolder >> password
[

	" Answer the password from the receiver's UserProfile.
	NOTE:  Since there does not seem to be any way to get the password (or its size), we ignore it.   We would like to use 'self remoteUserProfile gspassword asLocalObject'. "

	^ ''
]

{ #category : 'accessing' }
GbxUserProfileHolder >> internalForwarderFor: aSymbol
[

	" Answer an UNCACHED forwarder for the object whose name is aSymbol my internal symbol lists. "

	self newSymbDicts do:
		[: aSymbolListDictionayForwarder |
		(aSymbolListDictionayForwarder includesKey: aSymbol) ifTrue:
			[^ aSymbolListDictionayForwarder ucfwat: aSymbol ].].
	self error: aSymbol printString , ' not defined'.
]

{ #category : 'accessing' }
GbxUserProfileHolder >> newDefaultSegment
[

	" Answer the value of newDefaultSegment, a segment identifying this user's default segment on GemStone. "

	^ newDefaultSegment
]

{ #category : 'accessing' }
GbxUserProfileHolder >> newPrivileges
[

	" Answer the value of newPrivileges, an array of symbols
	  identifying this user's privileges on GemStone. "

	^ newPrivileges
]

{ #category : 'accessing' }
GbxUserProfileHolder >> basicDefaultSegment
[

	" Answer a forwarder to this user's default segment on GemStone. "

	^ self remoteUserProfile ucfwdefaultObjectSecurityPolicy
]

{ #category : 'accessing' }
GbxUserProfileHolder >> newSymbDicts
[

	" Answer the value of newSymbDicts, a list of forwarders to SymbolListDictionaries on GemStone. "

	newSymbDicts isNil ifTrue:
		[newSymbDicts := OrderedCollection new.
		self addDefaultSymbolDictionaries.].
	^ newSymbDicts
]

{ #category : 'testing' }
GbxUserProfileHolder >> hasChangedUserId
[

	" Answer true if I am connected to a valid GS UserProfile and have a different user ID. "

	^ self remoteUserProfile notNil
		and: [self newUserId notNil
			and: [self remoteUserProfile userId ~= self userId ]]
]

{ #category : 'testing' }
GbxUserProfileHolder >> gbxIsGSDefunct
[

	" Answer true if I no longer represent a valid GS object. "

	self isNewUser ifTrue: [^false].
	^self remoteUserProfile gbxIsGSDefunct
]

{ #category : 'testing' }
GbxUserProfileHolder >> isNewUser
[

	" Answer true if I am not connected to a valid GS UserProfile. "

	^ self remoteUserProfile isNil
]

{ #category : 'private' }
GbxUserProfileHolder >> addDefaultSymbolDictionaries
[

	" I add the default symbol list dictionaries to the new user. "

	| globals userGlobals |

	globals := self sessionForwarderFor: #Globals.
	userGlobals := (self sessionForwarderFor: #SymbolDictionary) ucfwnew.
	userGlobals
		ucfwat: #UserGlobals
		put: userGlobals.
	self newSymbDicts
		add: userGlobals ;
		add: globals.
]

{ #category : 'private' }
GbxUserProfileHolder >> newUserId
[

	" Answer the value of newUserId, a symbol
	  identifying a new UserProfile on GemStone. "

	^ newUserId
]

{ #category : 'private' }
GbxUserProfileHolder >> sessionForwarderFor: aSymbol
[

	" Answer an UNCACHED forwarder for the object whose name is aSymbol in the current session. "

	^ self session
		uncachedForwarderAt: aSymbol
		ifAbsent: [self error: aSymbol printString , ' not defined']
]

{ #category : 'private' }
GbxUserProfileHolder >> session
[

	" Answer the value of session, a GsSession that identifies the current environment. "

	^ session
]

{ #category : 'private' }
GbxUserProfileHolder >> remoteUserProfile: aUserProfileForwarder
[

	" Set the value of remoteUserProfile, a forwarder to a UserProfile on GemStone. "

	aUserProfileForwarder zzzisForwarder ifFalse:
		[^ self error: 'not a forwarder'].
	remoteUserProfile := aUserProfileForwarder.
]

{ #category : 'initialization' }
GbxUserProfileHolder >> on: aUserProfileForwarder
[

	self remoteUserProfile: aUserProfileForwarder.
	^ self
]

{ #category : 'printing' }
GbxUserProfileHolder >> displayString
[

	" Answer my user ID for printing. "

	^ self userId asString
]

{ #category : 'printing' }
GbxUserProfileHolder >> printOn: aStream
[


	aStream nextPutAll: self userId asString.
]

{ #category : 'updating' }
GbxUserProfileHolder >> removeDictionaryAt: anIndex
[

	" I remove the specified SymbolListDictionay from the user's list of dictionaries. "

	self isNewUser
		ifTrue:
			[self newSymbDicts removeIndex: anIndex.]
		ifFalse:
			[self remoteUserProfile
				ucfwremoveDictionaryAt: anIndex.].
]

{ #category : 'updating' }
GbxUserProfileHolder >> session: aGsSession
[

	" Set the value of session, a GsSession that identifies the current environment. "

	session := aGsSession.
]

{ #category : 'updating' }
GbxUserProfileHolder >> newUserId: aString
[
	" Set the value of newUserId, a string identifying a new UserProfile (or the renaming of an existing one) on GemStone. "

	newUserId := aString asString.
]

{ #category : 'updating' }
GbxUserProfileHolder >> newPrivileges: anArray
[

	" Set the value of newPrivileges, an array of symbols
	  identifying this user's privileges on GemStone. "

	newPrivileges := anArray.
]

{ #category : 'updating' }
GbxUserProfileHolder >> newDefaultSegment: aGSSegment
[

	" Set the value of newDefaultSegment, a segment identifying this user's default segment on GemStone. "

	newDefaultSegment := aGSSegment.
]

{ #category : 'updating' }
GbxUserProfileHolder >> insertDictionary: aSymbolListDictionayForwarder
at: anIndex
[

		" I save the forwarder to the specified SymbolListDictionay at the specified place in the user's list of dictionaries. "

	aSymbolListDictionayForwarder zzzisForwarder ifFalse:
		[^ self error: 'not a forwarder'].
	self isNewUser
		ifTrue:
			[self newSymbDicts
				add: aSymbolListDictionayForwarder
				beforeIndex: anIndex.]
		ifFalse:
			[self remoteUserProfile
				ucfwinsertDictionary: aSymbolListDictionayForwarder
				at: anIndex.].
]

{ #category : 'instance creation' }
GbxUserProfileHolder class >> on: aUserProfileForwarder
[

	^self new on: aUserProfileForwarder
]

{ #category : 'instance creation' }
GbxUserProfileHolder class >> newUserId: aString
in: aGsSession
[

		" Answer an instance of the receiver on a new UserProfile in the GemStone session aGsSession, whose user ID is specified by aString. "

	^ self new
		newUserId: aString ;
		session: aGsSession
]
