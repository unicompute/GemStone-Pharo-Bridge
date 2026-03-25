Class {
	#name : 'GbxServerMapTool',
	#superclass : 'Object',
	#instVars : [
		'session',
		'nodes',
		'segments',
		'rootNode',
		'isWeak'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxServerMapTool class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'auditing' }
GbxServerMapTool >> audit [
	"Audit the server map for consistency"
	| results |

	results := Dictionary new.
	results at: 'status' put: 'Audit not implemented'.
	results at: 'nodes' put: (self nodes size).
	^ results
]

{ #category : 'auditing' }
GbxServerMapTool >> auditNodes: nodeCollection results: auditResults [
	"Audit a collection of nodes"

	nodeCollection do: [ :node |
		"Node auditing not implemented in this version"
	].
]

{ #category : 'building' }
GbxServerMapTool >> buildFromServer [
	"Build the server map from GemStone"
	| script result |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| stream segs |
		stream := WriteStream on: String new.
		segs := SystemRepository select: [:seg | (System canRead: seg) and: [seg ~~ nil]].
		segs do: [ :seg |
			stream
				nextPutAll: seg segmentName asString; nextPutAll: ''|'';
				nextPutAll: seg _oop asString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	self parseSegments: result.
]

{ #category : 'accessing' }
GbxServerMapTool >> nodes [
	^ nodes ifNil: [ nodes := Dictionary new ]
]

{ #category : 'parsing' }
GbxServerMapTool >> parseSegments: aString [
	"Parse segments string into nodes"
	| lines parts node |

	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [
			parts := line splitOn: $|.
			parts size >= 2 ifTrue: [
				node := Dictionary new.
				node at: 'name' put: parts first.
				node at: 'oop' put: parts second asInteger.
				self nodes at: parts first put: node.
			]
		]
	].
]

{ #category : 'accessing' }
GbxServerMapTool >> printString [
	^ 'ServerMap (', (self nodes size) asString, ' nodes)'
]

{ #category : 'accessing' }
GbxServerMapTool >> rootNode [
	^ rootNode
]

{ #category : 'accessing' }
GbxServerMapTool >> rootNode: aNode [
	rootNode := aNode
]

{ #category : 'accessing' }
GbxServerMapTool >> segments [
	^ segments
]

{ #category : 'accessing' }
GbxServerMapTool >> segments: aCollection [
	segments := aCollection
]

{ #category : 'accessing' }
GbxServerMapTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxServerMapTool >> session: aSession [
	session := aSession
]
