Class {
	#name : 'GbxDynamicInstVarAttribute',
	#superclass : 'GbxDerivedAttribute',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxDynamicInstVarAttribute >> value: delegate
[

	value := self object delegate session
				executeBlock: '[:obj :label :value| obj dynamicInstVarAt: label asSymbol put: value]'
				withArguments: (Array
						with: self object delegate
						with: label asString gbxSubstrings last
						with: delegate)
				context: nil
]

{ #category : 'testing' }
GbxDynamicInstVarAttribute >> isReadOnly
[

	^false
]

{ #category : 'initialize-release' }
GbxDynamicInstVarAttribute >> initialize: aString value: anObject printString: aString2 object: theObject
[

	self initialize: aString value: anObject printString: aString2.
	object := theObject
]

{ #category : 'instance creation' }
GbxDynamicInstVarAttribute class >> label: aString value: anObject printString: aString2 object: object
[

	^self new initialize: aString value: anObject printString: aString2 object: object
]

