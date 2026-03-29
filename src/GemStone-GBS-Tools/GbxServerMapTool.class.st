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
	| results issueCount |

	results := Dictionary new.
	results
		at: #nodeCount put: self nodes size;
		at: #segmentCount put: (segments ifNil: [ 0 ] ifNotNil: [ segments size ]);
		at: #duplicateOops put: OrderedCollection new;
		at: #invalidOops put: OrderedCollection new;
		at: #missingNames put: OrderedCollection new;
		at: #duplicateNames put: OrderedCollection new.
	self auditNodes: self nodes values results: results.
	issueCount := #(duplicateOops invalidOops missingNames duplicateNames)
		inject: 0
		into: [ :sum :key | sum + ((results at: key) size) ].
	results
		at: #issueCount put: issueCount;
		at: #rootNode put: (rootNode ifNil: [ nil ] ifNotNil: [ rootNode at: #name ]);
		at: #status put: (issueCount = 0 ifTrue: [ 'ok' ] ifFalse: [ 'issues found' ]).
	^ results
]

{ #category : 'auditing' }
GbxServerMapTool >> auditNodes: nodeCollection results: auditResults [
	"Audit a collection of nodes"
	| oopOwners seenNames |

	oopOwners := Dictionary new.
	seenNames := Set new.
	nodeCollection do: [ :node |
		| name oop |
		name := node at: #name ifAbsent: [ '' ].
		oop := node at: #oop ifAbsent: [ nil ].

		name ifEmpty: [ (auditResults at: #missingNames) add: node ].
		(seenNames includes: name) ifTrue: [
			(auditResults at: #duplicateNames) add: name ].
		seenNames add: name.

		((oop isInteger not) or: [ oop <= 0 ]) ifTrue: [
			(auditResults at: #invalidOops) add: node ].

		((oopOwners at: oop ifAbsentPut: [ OrderedCollection new ])
			add: name).
	].

	oopOwners keysAndValuesDo: [ :oop :owners |
		(oop isInteger and: [ owners size > 1 ]) ifTrue: [
			(auditResults at: #duplicateOops) add: {
				#oop -> oop.
				#names -> owners asArray } asDictionary ].
	].
]

{ #category : 'building' }
GbxServerMapTool >> buildFromServer [
	"Build the server map from GemStone"
	| script result |
	
	session ifNil: [ ^ self ].
	nodes := Dictionary new.
	segments := OrderedCollection new.
	rootNode := nil.
	
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
	| lines parts node oop |

	nodes := Dictionary new.
	segments := OrderedCollection new.
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [
			parts := line splitOn: $|.
			parts size >= 2 ifTrue: [
				oop := [ parts second asInteger ] on: Error do: [ nil ].
				node := Dictionary new.
				node
					at: #name put: parts first;
					at: #oop put: oop.
				self nodes at: parts first put: node.
				segments add: node.
			]
		]
	].
	segments := segments asSortedCollection: [ :a :b |
		(a at: #oop ifAbsent: [ 0 ]) <= (b at: #oop ifAbsent: [ 0 ]) ].
	rootNode := segments ifEmpty: [ nil ] ifNotEmpty: [ segments first ].
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
