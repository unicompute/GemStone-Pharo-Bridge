Class {
	#name : 'GbxServerMap',
	#superclass : 'Object',
	#instVars : [
		'session',
		'nodes',
		'segments',
		'rootNode'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxServerMap class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'auditing' }
GbxServerMap >> audit [
	"Audit the server map for consistency"
	| results |
	
	results := GbxServerMapAuditResults new.
	self auditNodes: nodes results: results.
	^ results
]

{ #category : 'auditing' }
GbxServerMap >> auditNodes: nodeCollection results: auditResults [
	"Audit a collection of nodes"
	
	nodeCollection do: [ :node |
		node auditWith: auditResults.
		self auditNodes: node children results: auditResults.
	].
]

{ #category : 'accessing' }
GbxServerMap >> nodes [
	^ nodes ifNil: [ nodes := Dictionary new ]
]

{ #category : 'accessing' }
GbxServerMap >> rootNode [
	^ rootNode
]

{ #category : 'accessing' }
GbxServerMap >> rootNode: aNode [
	rootNode := aNode
]

{ #category : 'accessing' }
GbxServerMap >> segments [
	^ segments
]

{ #category : 'accessing' }
GbxServerMap >> segments: aCollection [
	segments := aCollection
]

{ #category : 'accessing' }
GbxServerMap >> session [
	^ session
]

{ #category : 'accessing' }
GbxServerMap >> session: aSession [
	session := aSession
]

{ #category : 'building' }
GbxServerMap >> buildFromServer [
	"Build the server map from GemStone"
	| script result |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| stream segs |
		stream := WriteStream on: String new.
		segs := System segmentList.
		segs do: [ :seg |
			stream
				nextPutAll: seg name asString; nextPutAll: ''|'';
				nextPutAll: (Reflection oopOf: seg) asString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	self parseSegments: result.
]

{ #category : 'parsing' }
GbxServerMap >> parseSegments: aString [
	"Parse segments string into nodes"
	| lines parts node |
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [
			parts := line splitOn: $|.
			parts size >= 2 ifTrue: [
				node := GbxServerMapNode new
					name: parts first;
					oop: parts second asInteger;
					session: session;
					yourself.
				self nodes at: parts first put: node.
			]
		]
	].
]

{ #category : 'accessing' }
GbxServerMap >> printString [
	^ 'ServerMap (', (self nodes size) asString, ' nodes)'
]
