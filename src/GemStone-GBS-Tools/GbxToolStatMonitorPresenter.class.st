Class {
	#name : 'GbxToolStatMonitorPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'tool',
		'statsText'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxToolStatMonitorPresenter class >> openOn: aTool [
	^ self new
		tool: aTool;
		open
]

{ #category : 'layout' }
GbxToolStatMonitorPresenter >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: statsText;
		yourself
]

{ #category : 'initialization' }
GbxToolStatMonitorPresenter >> initializePresenters [
	statsText := self newText.
	statsText editable: false.
]

{ #category : 'initialization' }
GbxToolStatMonitorPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Stat Monitor';
		initialExtent: 600 @ 400
]

{ #category : 'actions' }
GbxToolStatMonitorPresenter >> refresh [
	tool refresh.
	statsText text: tool stats printString
]

{ #category : 'accessing' }
GbxToolStatMonitorPresenter >> tool: aTool [
	tool := aTool.
	self refresh
]
