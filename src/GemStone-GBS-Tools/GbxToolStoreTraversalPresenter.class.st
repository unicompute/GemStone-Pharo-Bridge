Class {
	#name : 'GbxToolStoreTraversalPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'tool',
		'infoText',
		'refreshButton',
		'statusLabel'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxToolStoreTraversalPresenter class >> openOn: aTool [
	| presenter |
	presenter := self new.
	presenter open.
	presenter tool: aTool.
	^ presenter
]

{ #category : 'layout' }
GbxToolStoreTraversalPresenter >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 4;
		add: (SpBoxLayout newHorizontal
			spacing: 4;
			add: refreshButton width: 80;
			add: statusLabel;
			yourself) height: 30;
		add: infoText;
		yourself
]

{ #category : 'initialization' }
GbxToolStoreTraversalPresenter >> initializePresenters [
	infoText := self newText.
	infoText editable: false.

	refreshButton := self newButton
		label: 'Refresh';
		action: [ self refresh ].

	statusLabel := self newLabel.
	statusLabel label: ''.
]

{ #category : 'initialization' }
GbxToolStoreTraversalPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Store Traversal Tool';
		initialExtent: 500 @ 350.
]

{ #category : 'accessing' }
GbxToolStoreTraversalPresenter >> tool: aTool [
	tool := aTool.
	self refresh.
]

{ #category : 'updating' }
GbxToolStoreTraversalPresenter >> refresh [
	| stream |
	infoText ifNil: [ ^ self ].
	tool ifNil: [ infoText text: '(no tool attached)'. ^ self ].
	stream := WriteStream on: String new.
	stream
		nextPutAll: 'Objects Stored:    '; print: tool objectsStored; nl;
		nextPutAll: 'Dirty Objects:     '; print: tool dirtyObjects size; nl;
		nextPutAll: 'Cache Size:        '; print: ([ tool cache size ] on: Error do: [ '?' ]); nl;
		nextPutAll: 'Session:           '; nextPutAll: (tool session ifNil: [ 'none' ] ifNotNil: [ :s | [ s printString ] on: Error do: [ s class name ] ]); nl.
	infoText text: stream contents.
	statusLabel label: tool objectsStored asString, ' objects stored'.
]
