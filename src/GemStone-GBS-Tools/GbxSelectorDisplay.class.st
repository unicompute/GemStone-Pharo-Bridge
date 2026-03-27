Class {
	#name : 'GbxSelectorDisplay',
	#superclass : 'Object',
	#instVars : [
		'selector',
		'className',
		'theClassName'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxSelectorDisplay >> selector: anObject
[
	selector := anObject
]

{ #category : 'accessing' }
GbxSelectorDisplay >> className
[
	^className
]

{ #category : 'accessing' }
GbxSelectorDisplay >> selector
[
	^selector
]

{ #category : 'accessing' }
GbxSelectorDisplay >> theClassName: anObject
[
	theClassName := anObject
]

{ #category : 'accessing' }
GbxSelectorDisplay >> theClassName
[
	^theClassName
]

{ #category : 'accessing' }
GbxSelectorDisplay >> className: anObject
[
	className := anObject
]

{ #category : 'printing' }
GbxSelectorDisplay >> displayString
[
	^className = theClassName 
		ifTrue: [selector displayString]
		ifFalse: 
			[(Text fromString: selector , ' (' , className displayString , ')') 
				allItalic]
]

