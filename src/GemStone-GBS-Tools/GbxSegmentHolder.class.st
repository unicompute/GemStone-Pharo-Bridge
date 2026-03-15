Class {
	#name : 'GbxSegmentHolder',
	#superclass : 'Object',
	#instVars : [
		'name',
		'proxy',
		'session',
		'dictionary',
		'size',
		'percentFull'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxSegmentHolder class >> newWithSgmt: segmentProxy [
	"Create a holder for a GemStone segment"
	^ self new
		proxy: segmentProxy;
		yourself
]

{ #category : 'instance creation' }
GbxSegmentHolder class >> newWithSgmt: segmentProxy name: segmentName dict: dictProxy [
	"Create a holder for a GemStone segment with name and dictionary"
	^ self new
		proxy: segmentProxy;
		name: segmentName;
		dictionary: dictProxy;
		yourself
]

{ #category : 'instance creation' }
GbxSegmentHolder class >> on: aSegmentProxy [
	"Create a holder for a GemStone segment proxy"
	^ self new
		proxy: aSegmentProxy;
		yourself
]

{ #category : 'comparing' }
GbxSegmentHolder >> = anObject [
	^ (anObject isKindOf: GbxSegmentHolder)
		and: [ name = anObject name ]
]

{ #category : 'accessing' }
GbxSegmentHolder >> asString [
	^ name ifNil: [ '<unknown segment>' ]
]

{ #category : 'accessing' }
GbxSegmentHolder >> dictionary [
	^ dictionary
]

{ #category : 'accessing' }
GbxSegmentHolder >> dictionary: aProxy [
	dictionary := aProxy
]

{ #category : 'accessing' }
GbxSegmentHolder >> fetchInfo [
	"Fetch segment info from GemStone"
	| script result parts |
	
	(session isNil or: [ proxy isNil ]) ifTrue: [ ^ self ].
	
	script := '[
		| seg stream |
		seg := Object _objectForOop: ', proxy oop asString, '.
		stream := WriteStream on: String new.
		stream
			nextPutAll: seg name asString; nextPutAll: ''|'';
			nextPutAll: seg size asString; nextPutAll: ''|'';
			nextPutAll: seg percentFull asString.
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	parts := result splitOn: $|.
	parts size >= 3 ifTrue: [
		name := parts first.
		size := parts second asInteger.
		percentFull := parts third asInteger.
	].
]

{ #category : 'accessing' }
GbxSegmentHolder >> hash [
	^ name hash
]

{ #category : 'accessing' }
GbxSegmentHolder >> name [
	^ name
]

{ #category : 'accessing' }
GbxSegmentHolder >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxSegmentHolder >> percentFull [
	^ percentFull ifNil: [ 
		self fetchInfo.
		percentFull 
	]
]

{ #category : 'accessing' }
GbxSegmentHolder >> printString [
	^ 'Segment: ', name, ' (', percentFull asString, '% full)'
]

{ #category : 'accessing' }
GbxSegmentHolder >> proxy [
	^ proxy
]

{ #category : 'accessing' }
GbxSegmentHolder >> proxy: aProxy [
	proxy := aProxy
]

{ #category : 'accessing' }
GbxSegmentHolder >> session [
	^ session
]

{ #category : 'accessing' }
GbxSegmentHolder >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxSegmentHolder >> size [
	^ size ifNil: [ 
		self fetchInfo.
		size 
	]
]
