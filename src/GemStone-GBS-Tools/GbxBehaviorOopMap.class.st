Class {
	#name : 'GbxBehaviorOopMap',
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
GbxBehaviorOopMap class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> addNode: aNode [
	"Add a node to the map"
	| oop |
	
	oop := aNode oop.
	oop ifNotNil: [
		oopMap at: oop put: aNode.
		nodeCount := nodeCount + 1.
	].
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> at: anOop [
	"Get node at OOP"
	^ oopMap at: anOop ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> at: anOop ifAbsent: aBlock [
	"Get node at OOP or evaluate block"
	^ oopMap at: anOop ifAbsent: aBlock
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> at: anOop put: aNode [
	"Put node at OOP"
	| existing |
	
	existing := oopMap at: anOop ifAbsent: [ nil ].
	existing ifNil: [
		nodeCount := nodeCount + 1.
	].
	oopMap at: anOop put: aNode.
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> clear [
	"Clear the map"
	oopMap := Dictionary new.
	nodeCount := 0.
]

{ #category : 'initialization' }
GbxBehaviorOopMap >> initialize [
	super initialize.
	oopMap := Dictionary new.
	nodeCount := 0.
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> nodeCount [
	^ nodeCount
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> nodes [
	^ oopMap values
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> oopMap [
	^ oopMap
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> printString [
	^ 'BehaviorOopMap (', nodeCount asString, ' nodes)'
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> session [
	^ session
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxBehaviorOopMap >> size [
	^ nodeCount
]
