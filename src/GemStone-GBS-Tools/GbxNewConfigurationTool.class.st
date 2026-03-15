Class {
	#name : 'GbxNewConfigurationTool',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'opening' }
GbxNewConfigurationTool class >> open [
	| editor param |
	param := GbsSessionParameters new.
	editor := GbsSessionParametersEditor new.
	editor setModel: param.
	editor onAccept: [ GbsSessionParameters addParameter: param ].
	^ editor open
]

{ #category : 'opening' }
GbxNewConfigurationTool class >> openInShellView [
	^ self open
]

{ #category : 'opening' }
GbxNewConfigurationTool >> open [
	^ self class open
]

{ #category : 'opening' }
GbxNewConfigurationTool >> openInShellView [
	^ self class openInShellView
]
