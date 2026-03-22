Class {
	#name : 'GbxServerMapNodeTool',
	#superclass : 'Object',
	#instVars : [
		'name',
		'oop',
		'session',
		'children',
		'parent',
		'nodeType',
		'isCached'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxServerMapNodeTool class >> named: aString oop: anOop [
	^ self new
		name: aString;
		oop: anOop;
		yourself
]

{ #category : 'auditing' }
GbxServerMapNodeTool >> auditWith: auditResults [
	"Audit this node and record results"
	| isValid |
	
	isValid := self validate.
	isValid ifFalse: [
		auditResults addError: 'Invalid node: ', name.
	].
	
	isCached ifFalse: [
		auditResults addWarning: 'Node not cached: ', name.
	].
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> children [
	^ children ifNil: [ children := OrderedCollection new ]
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> children: aCollection [
	children := aCollection
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> isCached [
	^ isCached ifNil: [ false ]
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> isCached: aBoolean [
	isCached := aBoolean
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> name [
	^ name
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> nodeType [
	^ nodeType
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> nodeType: aSymbol [
	nodeType := aSymbol
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> oop [
	^ oop
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> oop: anOop [
	oop := anOop
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> parent [
	^ parent
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> parent: aNode [
	parent := aNode.
	aNode ifNotNil: [
		aNode children add: self.
	].
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> printString [
	^ name, ' (oop: ', (oop ifNil: [ 'nil' ] ifNotNil: [ oop asString ]), ')'
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxServerMapNodeTool >> validate [
	"Validate this node"
	^ (name notNil and: [ name isNotEmpty ])
		and: [ (oop isNil or: [ oop > 20 ]) ]
]
