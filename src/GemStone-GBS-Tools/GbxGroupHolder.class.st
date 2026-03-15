Class {
	#name : 'GbxGroupHolder',
	#superclass : 'Object',
	#instVars : [
		'name',
		'proxy',
		'session',
		'members',
		'privileges'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxGroupHolder class >> newWithGrp: groupName [
	"Create a holder for a GemStone group by name"
	^ self new
		name: groupName;
		yourself
]

{ #category : 'instance creation' }
GbxGroupHolder class >> newWithGrp: groupName users: userCollection [
	"Create a holder for a GemStone group with members"
	^ self new
		name: groupName;
		members: userCollection;
		yourself
]

{ #category : 'instance creation' }
GbxGroupHolder class >> on: aGroupProxy [
	"Create a holder for a GemStone group proxy"
	^ self new
		proxy: aGroupProxy;
		yourself
]

{ #category : 'comparing' }
GbxGroupHolder >> = anObject [
	^ (anObject isKindOf: GbxGroupHolder)
		and: [ name = anObject name ]
]

{ #category : 'accessing' }
GbxGroupHolder >> asString [
	^ name ifNil: [ '<unknown group>' ]
]

{ #category : 'accessing' }
GbxGroupHolder >> fetchMembers [
	"Fetch group members from GemStone"
	| script result |
	
	(session isNil or: [ proxy isNil ]) ifTrue: [ ^ #() ].
	
	script := '[
		| grp |
		grp := Object _objectForOop: ', proxy oop asString, '.
		grp members collect: [ :m | m userId ]
	] value'.
	
	result := session executeAndFetch: script.
	members := result.
]

{ #category : 'accessing' }
GbxGroupHolder >> fetchPrivileges [
	"Fetch group privileges from GemStone"
	| script result |
	
	(session isNil or: [ proxy isNil ]) ifTrue: [ ^ #() ].
	
	script := '[
		| grp |
		grp := Object _objectForOop: ', proxy oop asString, '.
		grp privileges
	] value'.
	
	result := session executeAndFetch: script.
	privileges := result.
]

{ #category : 'accessing' }
GbxGroupHolder >> hash [
	^ name hash
]

{ #category : 'accessing' }
GbxGroupHolder >> members [
	^ members ifNil: [ 
		self fetchMembers.
		members 
	]
]

{ #category : 'accessing' }
GbxGroupHolder >> members: aCollection [
	members := aCollection
]

{ #category : 'accessing' }
GbxGroupHolder >> name [
	^ name
]

{ #category : 'accessing' }
GbxGroupHolder >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxGroupHolder >> printString [
	^ 'Group: ', name
]

{ #category : 'accessing' }
GbxGroupHolder >> privileges [
	^ privileges ifNil: [ 
		self fetchPrivileges.
		privileges 
	]
]

{ #category : 'accessing' }
GbxGroupHolder >> privileges: aCollection [
	privileges := aCollection
]

{ #category : 'accessing' }
GbxGroupHolder >> proxy [
	^ proxy
]

{ #category : 'accessing' }
GbxGroupHolder >> proxy: aProxy [
	proxy := aProxy
]

{ #category : 'accessing' }
GbxGroupHolder >> session [
	^ session
]

{ #category : 'accessing' }
GbxGroupHolder >> session: aSession [
	session := aSession
]
