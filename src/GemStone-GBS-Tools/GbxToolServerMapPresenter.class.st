Class {
	#name : 'GbxToolServerMapPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'tool',
		'nodeList',
		'fetchButton',
		'statusLabel'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxToolServerMapPresenter class >> openOn: aTool [
	| presenter |
	presenter := self new.
	presenter open.
	presenter tool: aTool.
	^ presenter
]

{ #category : 'layout' }
GbxToolServerMapPresenter >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 4;
		add: (SpBoxLayout newHorizontal
			spacing: 4;
			add: fetchButton width: 120;
			add: statusLabel;
			yourself) height: 30;
		add: nodeList;
		yourself
]

{ #category : 'initialization' }
GbxToolServerMapPresenter >> initializePresenters [
	nodeList := self newList.
	nodeList display: [ :item | item asString ].

	fetchButton := self newButton
		label: 'Fetch from Server';
		action: [
			[ tool buildFromServer. self refresh ]
				on: Error
				do: [ :ex | statusLabel label: 'Error: ', ex messageText ] ].

	statusLabel := self newLabel.
	statusLabel label: 'Not yet fetched.'.
]

{ #category : 'initialization' }
GbxToolServerMapPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Server Map';
		initialExtent: 500 @ 400.
]

{ #category : 'updating' }
GbxToolServerMapPresenter >> refresh [
	| items |
	nodeList ifNil: [ ^ self ].
	tool ifNil: [ nodeList items: #(). ^ self ].
	items := tool nodes associations asSortedCollection: [ :a :b | a key <= b key ].
	nodeList items: (items collect: [ :assoc |
		| node oop |
		node := assoc value.
		oop := node at: #oop ifAbsent: [ nil ].
		assoc key, ' (oop: ', (oop ifNil: [ '<invalid>' ] ifNotNil: [ oop asString ]), ')' ]).
	statusLabel label: items size asString, ' segments'.
]

{ #category : 'accessing' }
GbxToolServerMapPresenter >> tool: aTool [
	tool := aTool.
	self refresh.
]
