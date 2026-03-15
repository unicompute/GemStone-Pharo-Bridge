Class {
	#name : 'GbxConfigurationTool',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'opening' }
GbxConfigurationTool class >> open [
	^ GbsSettingsPresenter open
]

{ #category : 'opening' }
GbxConfigurationTool class >> openInShellView [
	^ self open
]

{ #category : 'opening' }
GbxConfigurationTool >> open [
	^ self class open
]

{ #category : 'opening' }
GbxConfigurationTool >> openInShellView [
	^ self class openInShellView
]
