Class {
	#name : 'GbsBuffer',
	#superclass : 'Array',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbsBuffer >> namedValueAt: index
[
	^self at: index
]

{ #category : 'accessing' }
GbsBuffer >> indexableValueAt: index put: anObject
[
	^self at: index put: anObject
]

{ #category : 'accessing' }
GbsBuffer >> indexableValueAt: index
[
	^self at: index
]

{ #category : 'accessing' }
GbsBuffer >> namedValueAt: index put: anObject
[
	^self at: index put: anObject
]

{ #category : 'accessing' }
GbsBuffer >> namedSize
[
	^self size
]

{ #category : 'accessing' }
GbsBuffer >> indexableSize
[
	^self size
]

