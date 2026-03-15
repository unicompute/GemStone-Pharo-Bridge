Class {
	#name : 'GbxClassHolder',
	#superclass : 'GbxDelegate',
	#instVars : [
		'name',
		'proxy',
		'session',
		'category',
		'superclassName',
		'instVarNames',
		'classInstVarNames',
		'classVarNames'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxClassHolder class >> name: aString proxy: aProxy [
	^ self new
		name: aString;
		proxy: aProxy;
		yourself
]

{ #category : 'instance creation' }
GbxClassHolder class >> name: aString proxy: aProxy session: aSession [
	^ self new
		name: aString;
		proxy: aProxy;
		session: aSession;
		yourself
]

{ #category : 'comparing' }
GbxClassHolder >> = anObject [
	^ (anObject isKindOf: GbxClassHolder)
		and: [ name = anObject name ]
]

{ #category : 'accessing' }
GbxClassHolder >> asString [
	^ name ifNil: [ '<unknown>' ]
]

{ #category : 'accessing' }
GbxClassHolder >> category [
	^ category
]

{ #category : 'accessing' }
GbxClassHolder >> category: aString [
	category := aString
]

{ #category : 'accessing' }
GbxClassHolder >> classInstVarNames [
	^ classInstVarNames ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxClassHolder >> classInstVarNames: aCollection [
	classInstVarNames := aCollection
]

{ #category : 'accessing' }
GbxClassHolder >> classVarNames [
	^ classVarNames ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxClassHolder >> classVarNames: aCollection [
	classVarNames := aCollection
]

{ #category : 'accessing' }
GbxClassHolder >> fetchDefinitionFromServer [
	"Fetch class definition details from GemStone"
	| script result parts |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| cls stream |
		cls := Object _objectForOop: ', proxy oop asString, '.
		stream := WriteStream on: String new.
		stream
			nextPutAll: cls category asString; nextPutAll: ''|'';
			nextPutAll: cls superclass name asString; nextPutAll: ''|'';
			nextPutAll: (cls allInstVarNames collect: [ :n | n asString ]) asString; nextPutAll: ''|'';
			nextPutAll: (cls class instVarNames collect: [ :n | n asString ]) asString; nextPutAll: ''|'';
			nextPutAll: (cls classVarNames collect: [ :n | n asString ]) asString.
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	parts := result splitOn: $|.
	parts size >= 5 ifTrue: [
		category := parts first.
		superclassName := parts second.
		instVarNames := parts third.
		classInstVarNames := parts fourth.
		classVarNames := parts fifth.
	].
]

{ #category : 'accessing' }
GbxClassHolder >> hash [
	^ name hash
]

{ #category : 'accessing' }
GbxClassHolder >> instVarNames [
	^ instVarNames ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxClassHolder >> instVarNames: aCollection [
	instVarNames := aCollection
]

{ #category : 'accessing' }
GbxClassHolder >> isBehavior [
	^ true
]

{ #category : 'accessing' }
GbxClassHolder >> name [
	^ name
]

{ #category : 'accessing' }
GbxClassHolder >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxClassHolder >> printString [
	^ name ifNil: [ '<unknown class>' ]
]

{ #category : 'accessing' }
GbxClassHolder >> proxy [
	^ proxy
]

{ #category : 'accessing' }
GbxClassHolder >> proxy: aProxy [
	proxy := aProxy
]

{ #category : 'accessing' }
GbxClassHolder >> session [
	^ session
]

{ #category : 'accessing' }
GbxClassHolder >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxClassHolder >> superclassName [
	^ superclassName
]

{ #category : 'accessing' }
GbxClassHolder >> superclassName: aString [
	superclassName := aString
]
