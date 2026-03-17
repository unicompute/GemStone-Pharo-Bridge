Class {
	#name : 'GbxSymbolListDictionaryHolder',
	#superclass : 'Object',
	#instVars : [
		'dictName',
		'remoteSymbolListDictionary'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'comparing' }
GbxSymbolListDictionaryHolder >> = aGSSymbolListDictionaryHolder
[

	" Answer true if I am equivalent to aGSSymbolListDictionaryHolder. "

	^ self class == aGSSymbolListDictionaryHolder class
		and: [self dictName = aGSSymbolListDictionaryHolder dictName]
]

{ #category : 'comparing' }
GbxSymbolListDictionaryHolder >> hash
[

	^self class hash + self dictName hash
]

{ #category : 'accessing' }
GbxSymbolListDictionaryHolder >> includesKey: aSymbol
[

	" Answer true if my keys include aSymbol. "

	^ self remoteSymbolListDictionary includesKey: aSymbol asSymbol
]

{ #category : 'accessing' }
GbxSymbolListDictionaryHolder >> displayString
[

	" Answer a representation of the receiver for use in a Label, primarily for use in SequenceViews. "

	| name |

	name := self dictName.
	^ name notNil
		ifTrue: [name asString]
		ifFalse: ['<<< no name >>>']
]

{ #category : 'accessing' }
GbxSymbolListDictionaryHolder >> remoteSymbolListDictionary
[

	" Answer the value of remoteSymbolListDictionary, a forwarder to a SymbolListDictionary on GemStone. "

	^ remoteSymbolListDictionary
]

{ #category : 'accessing' }
GbxSymbolListDictionaryHolder >> dictName
[

	" Answer the value of dictName, a symbol that names my dictionary on GemStone. "

	^ dictName
]

{ #category : 'accessing' }
GbxSymbolListDictionaryHolder >> keyNames
[

	" Answer a sorted list of my keys, as local objects. "

	^ self remoteSymbolListDictionary keys asSortedCollection asArray
]

{ #category : 'initialization' }
GbxSymbolListDictionaryHolder >> on: aSymbolListDictionaryForwarder
[
	
	[self dictName: aSymbolListDictionaryForwarder name]
		on: GemStone.Gbs.GbsAuthErrSegRead
		do: [:ex | self dictName: 'restricted object'].
	self remoteSymbolListDictionary: aSymbolListDictionaryForwarder.
	^self
]

{ #category : 'printing' }
GbxSymbolListDictionaryHolder >> printOn: aStream
[

	" Append to aStream an identification of the receiver.
	  NOTE:  This implementation is required for dictionary lists to work correctly in VS and VA. "

	aStream nextPutAll: self displayString.
]

{ #category : 'private' }
GbxSymbolListDictionaryHolder >> dictName: aSymbol
[

	" Set the value of dictName, a symbol that names my dictionary on GemStone. "

	dictName := aSymbol.
]

{ #category : 'private' }
GbxSymbolListDictionaryHolder >> remoteSymbolListDictionary: aSymbolAssociationForwarder
[

	" Set the value of remoteSymbolListDictionary, a forwarder to a SymbolListDictionary on GemStone. "

	remoteSymbolListDictionary := aSymbolAssociationForwarder.
]

{ #category : 'instance creation' }
GbxSymbolListDictionaryHolder class >> on: aSymbolListDictionaryForwarder
[

	^self new on: aSymbolListDictionaryForwarder
]

