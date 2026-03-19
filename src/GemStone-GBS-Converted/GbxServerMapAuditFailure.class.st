Class {
	#name : 'GbxServerMapAuditFailure',
	#superclass : 'Object',
	#instVars : [
		'description',
		'node'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxServerMapAuditFailure >> description: anObject
[
	description := anObject.
	^self
]

{ #category : 'accessing' }
GbxServerMapAuditFailure >> node
[
	^node
]

{ #category : 'accessing' }
GbxServerMapAuditFailure >> description
[
	^description
]

{ #category : 'accessing' }
GbxServerMapAuditFailure >> node: anObject
[
	node := anObject.
	^self
]

{ #category : 'printing' }
GbxServerMapAuditFailure >> printDescriptionOn: aStream
[

	aStream nextPutAll: ': ' , description
]

{ #category : 'printing' }
GbxServerMapAuditFailure >> printOn: aStream
[

	super printOn: aStream.
	self printDescriptionOn: aStream
]

{ #category : 'instance creation' }
GbxServerMapAuditFailure class >> node: nodeOrLeaf description: descriptiveString
[

	^(self new)
		node: nodeOrLeaf;
		description: descriptiveString
]

{ #category : 'instance creation' }
GbxServerMapAuditFailure class >> description: descriptiveString
[

	^self new description: descriptiveString
]
