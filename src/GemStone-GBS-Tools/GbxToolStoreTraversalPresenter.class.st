Class {
	#name : 'GbxToolStoreTraversalPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'tool',
		'infoText',
		'refreshButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxToolStoreTraversalPresenter class >> openOn: aTool [
	^ self new
		tool: aTool;
		open
]

{ #category : 'layout' }
GbxToolStoreTraversalPresenter >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: refreshButton height: 30;
		add: infoText;
		yourself
]

{ #category : 'initialization' }
GbxToolStoreTraversalPresenter >> initializePresenters [
	refreshButton := self newButton
		label: 'Refresh';
		action: [ self refresh ].
	infoText := self newText.
	infoText editable: false.
]

{ #category : 'initialization' }
GbxToolStoreTraversalPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Store Traversal Tool';
		initialExtent: 600 @ 400
]

{ #category : 'actions' }
GbxToolStoreTraversalPresenter >> refresh [
	tool refresh.
	infoText text: tool traversal printString
]

{ #category : 'accessing' }
GbxToolStoreTraversalPresenter >> tool: aTool [
	tool := aTool.
	self refresh
]
