Class {
	#name : 'GbxUserProfileHolder',
	#superclass : 'Object',
	#instVars : [
		'userId',
		'proxy',
		'session',
		'privileges',
		'groups',
		'password'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxUserProfileHolder class >> newUserId: aString in: aSession [
	"Create a new user profile holder for a new user"
	^ self new
		userId: aString;
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbxUserProfileHolder class >> on: aUserProfileProxy [
	"Create a holder for a GemStone user profile proxy"
	^ self new
		proxy: aUserProfileProxy;
		yourself
]

{ #category : 'instance creation' }
GbxUserProfileHolder class >> on: aUserProfileForwarder [
	"Create a holder for a GemStone user profile forwarder"
	^ self new
		proxy: aUserProfileForwarder;
		yourself
]

{ #category : 'comparing' }
GbxUserProfileHolder >> = anObject [
	^ (anObject isKindOf: GbxUserProfileHolder)
		and: [ userId = anObject userId ]
]

{ #category : 'accessing' }
GbxUserProfileHolder >> asString [
	^ userId ifNil: [ '<unknown user>' ]
]

{ #category : 'accessing' }
GbxUserProfileHolder >> fetchPrivileges [
	"Fetch user privileges from GemStone"
	| script result |
	
	(session isNil or: [ proxy isNil ]) ifTrue: [ ^ #() ].
	
	script := '[
		| up |
		up := Object _objectForOop: ', proxy oop asString, '.
		up privileges
	] value'.
	
	result := session executeAndFetch: script.
	privileges := result.
]

{ #category : 'accessing' }
GbxUserProfileHolder >> fetchGroups [
	"Fetch user groups from GemStone"
	| script result |
	
	(session isNil or: [ proxy isNil ]) ifTrue: [ ^ #() ].
	
	script := '[
		| up |
		up := Object _objectForOop: ', proxy oop asString, '.
		up groups collect: [ :g | g name ]
	] value'.
	
	result := session executeAndFetch: script.
	groups := result.
]

{ #category : 'accessing' }
GbxUserProfileHolder >> groups [
	^ groups ifNil: [ 
		self fetchGroups.
		groups 
	]
]

{ #category : 'accessing' }
GbxUserProfileHolder >> groups: aCollection [
	groups := aCollection
]

{ #category : 'accessing' }
GbxUserProfileHolder >> hash [
	^ userId hash
]

{ #category : 'accessing' }
GbxUserProfileHolder >> password [
	^ password
]

{ #category : 'accessing' }
GbxUserProfileHolder >> password: aString [
	password := aString
]

{ #category : 'accessing' }
GbxUserProfileHolder >> privileges [
	^ privileges ifNil: [ 
		self fetchPrivileges.
		privileges 
	]
]

{ #category : 'accessing' }
GbxUserProfileHolder >> privileges: aCollection [
	privileges := aCollection
]

{ #category : 'accessing' }
GbxUserProfileHolder >> printString [
	^ 'UserProfile: ', userId
]

{ #category : 'accessing' }
GbxUserProfileHolder >> proxy [
	^ proxy
]

{ #category : 'accessing' }
GbxUserProfileHolder >> proxy: aProxy [
	proxy := aProxy.
	userId ifNil: [
		userId := self fetchUserId.
	].
]

{ #category : 'fetching' }
GbxUserProfileHolder >> fetchUserId [
	"Fetch user ID from GemStone"
	| script |
	
	(session isNil or: [ proxy isNil ]) ifTrue: [ ^ nil ].
	
	script := '[
		| up |
		up := Object _objectForOop: ', proxy oop asString, '.
		up userId
	] value'.
	
	^ session executeAndFetch: script
]

{ #category : 'accessing' }
GbxUserProfileHolder >> session [
	^ session
]

{ #category : 'accessing' }
GbxUserProfileHolder >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxUserProfileHolder >> userId [
	^ userId
]

{ #category : 'accessing' }
GbxUserProfileHolder >> userId: aString [
	userId := aString
]
