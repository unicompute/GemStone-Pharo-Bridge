Class {
	#name : 'GbxToolReplicatorManagerPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'manager',
		'replicatorList',
		'refreshButton',
		'statusLabel'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxToolReplicatorManagerPresenter class >> openOn: aManager [
	| presenter |
	presenter := self new.
	presenter open.
	presenter manager: aManager.
	^ presenter
]

{ #category : 'layout' }
GbxToolReplicatorManagerPresenter >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 4;
		add: (SpBoxLayout newHorizontal
			spacing: 4;
			add: refreshButton width: 80;
			add: statusLabel;
			yourself) height: 30;
		add: replicatorList;
		yourself
]

{ #category : 'initialization' }
GbxToolReplicatorManagerPresenter >> initializePresenters [
	replicatorList := self newList.
	replicatorList display: [ :item | item asString ].

	refreshButton := self newButton
		label: 'Refresh';
		action: [ self refresh ].

	statusLabel := self newLabel.
	statusLabel label: ''.
]

{ #category : 'initialization' }
GbxToolReplicatorManagerPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Replication Map';
		initialExtent: 500 @ 400.
]

{ #category : 'accessing' }
GbxToolReplicatorManagerPresenter >> manager: aManager [
	manager := aManager.
	self refresh.
]

{ #category : 'updating' }
GbxToolReplicatorManagerPresenter >> refresh [
	| items |
	replicatorList ifNil: [ ^ self ].
	manager ifNil: [ replicatorList items: #(). ^ self ].
	items := manager replicatorRegistry associations asSortedCollection: [ :a :b | a key <= b key ].
	replicatorList items: (items collect: [ :assoc | assoc key, '  ->  ', assoc value name ]).
	statusLabel label: 'Default: ', manager defaultReplicatorClass name,
		' | ', items size asString, ' registered'.
]
