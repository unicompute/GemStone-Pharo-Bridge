Class {
	#name : 'GbxServerMapNode',
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
GbxServerMapNode class >> named: aString oop: anOop [
	^ self new
		name: aString;
		oop: anOop;
		yourself
]

{ #category : 'auditing' }
GbxServerMapNode >> auditWith: auditResults [
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
GbxServerMapNode >> children [
	^ children ifNil: [ children := OrderedCollection new ]
]

{ #category : 'accessing' }
GbxServerMapNode >> children: aCollection [
	children := aCollection
]

{ #category : 'accessing' }
GbxServerMapNode >> isCached [
	^ isCached ifNil: [ false ]
]

{ #category : 'accessing' }
GbxServerMapNode >> isCached: aBoolean [
	isCached := aBoolean
]

{ #category : 'accessing' }
GbxServerMapNode >> name [
	^ name
]

{ #category : 'accessing' }
GbxServerMapNode >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxServerMapNode >> nodeType [
	^ nodeType
]

{ #category : 'accessing' }
GbxServerMapNode >> nodeType: aSymbol [
	nodeType := aSymbol
]

{ #category : 'accessing' }
GbxServerMapNode >> oop [
	^ oop
]

{ #category : 'accessing' }
GbxServerMapNode >> oop: anOop [
	oop := anOop
]

{ #category : 'accessing' }
GbxServerMapNode >> parent [
	^ parent
]

{ #category : 'accessing' }
GbxServerMapNode >> parent: aNode [
	parent := aNode.
	aNode ifNotNil: [
		aNode children add: self.
	].
]

{ #category : 'accessing' }
GbxServerMapNode >> printString [
	^ name, ' (oop: ', (oop ifNil: [ 'nil' ] ifNotNil: [ oop asString ]), ')'
]

{ #category : 'accessing' }
GbxServerMapNode >> session [
	^ session
]

{ #category : 'accessing' }
GbxServerMapNode >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxServerMapNode >> validate [
	"Validate this node"
	^ (name notNil and: [ name isNotEmpty ])
		and: [ (oop isNil or: [ oop > 20 ]) ]
]
