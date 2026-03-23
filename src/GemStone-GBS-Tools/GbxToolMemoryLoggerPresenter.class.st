Class {
	#name : 'GbxToolMemoryLoggerPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'logger',
		'messageText',
		'clearButton',
		'refreshButton',
		'statusLabel'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxToolMemoryLoggerPresenter class >> openOn: aLogger [
	| presenter |
	presenter := self new.
	presenter open.
	presenter logger: aLogger.
	^ presenter
]

{ #category : 'layout' }
GbxToolMemoryLoggerPresenter >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 4;
		add: (SpBoxLayout newHorizontal
			spacing: 4;
			add: refreshButton width: 80;
			add: clearButton width: 80;
			add: statusLabel;
			yourself) height: 30;
		add: messageText;
		yourself
]

{ #category : 'initialization' }
GbxToolMemoryLoggerPresenter >> initializePresenters [
	messageText := self newText.
	messageText editable: false.

	refreshButton := self newButton
		label: 'Refresh';
		action: [ self refresh ].

	clearButton := self newButton
		label: 'Clear';
		action: [
			logger ifNotNil: [ logger clear ].
			self refresh ].

	statusLabel := self newLabel.
	statusLabel label: ''.
]

{ #category : 'initialization' }
GbxToolMemoryLoggerPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Memory Logger';
		initialExtent: 700 @ 500.
]

{ #category : 'accessing' }
GbxToolMemoryLoggerPresenter >> logger: aLogger [
	logger := aLogger.
	self refresh.
]

{ #category : 'updating' }
GbxToolMemoryLoggerPresenter >> refresh [
	messageText ifNil: [ ^ self ].
	logger ifNil: [
		messageText text: '(no logger attached)'.
		^ self ].
	messageText text: logger messagesAsText.
	statusLabel label: logger logCount asString, ' messages total'.
]
