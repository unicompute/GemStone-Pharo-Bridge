Class {
	#name : 'GbxBehaviorOopMapTool',
	#superclass : 'Object',
	#instVars : [
		'session',
		'oopMap',
		'nodeCount'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxBehaviorOopMapTool class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> addNode: aNode [
	"Add a node to the map"
	| oop |
	
	oop := aNode oop.
	oop ifNotNil: [
		oopMap at: oop put: aNode.
		nodeCount := nodeCount + 1.
	].
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> at: anOop [
	"Get node at OOP"
	^ oopMap at: anOop ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> at: anOop ifAbsent: aBlock [
	"Get node at OOP or evaluate block"
	^ oopMap at: anOop ifAbsent: aBlock
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> at: anOop put: aNode [
	"Put node at OOP"
	| existing |
	
	existing := oopMap at: anOop ifAbsent: [ nil ].
	existing ifNil: [
		nodeCount := nodeCount + 1.
	].
	oopMap at: anOop put: aNode.
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> clear [
	"Clear the map"
	oopMap := Dictionary new.
	nodeCount := 0.
]

{ #category : 'initialization' }
GbxBehaviorOopMapTool >> initialize [
	super initialize.
	oopMap := Dictionary new.
	nodeCount := 0.
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> nodeCount [
	^ nodeCount
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> nodes [
	^ oopMap values
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> oopMap [
	^ oopMap
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> printString [
	^ 'BehaviorOopMap (', nodeCount asString, ' nodes)'
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxBehaviorOopMapTool >> size [
	^ nodeCount
]
