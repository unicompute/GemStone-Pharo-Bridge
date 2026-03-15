Class {
	#name : 'GbxSegmentTool',
	#superclass : 'SpPresenter',
	#instVars : [
		'brain',
		'session',
		'segmentList',
		'infoText',
		'refreshButton',
		'compactButton',
		'deleteButton',
		'inspectButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxSegmentTool class >> openOn: aSession [
	"Open the segment tool on a session"
	^ GbxSegmentToolBrain openOn: aSession
]

{ #category : 'layout' }
GbxSegmentTool >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: (SpBoxLayout newHorizontal
			add: refreshButton width: 100;
			add: compactButton width: 100;
			add: deleteButton width: 100;
			add: inspectButton width: 100;
			yourself) height: 35;
		add: segmentList;
		add: infoText;
		yourself
]

{ #category : 'initialization' }
GbxSegmentTool >> initializePresenters [
	refreshButton := self newButton
		label: 'Refresh';
		action: [ self refresh ].
	
	compactButton := self newButton
		label: 'Compact';
		action: [ self compact ].
	
	deleteButton := self newButton
		label: 'Delete';
		action: [ self delete ].
	
	inspectButton := self newButton
		label: 'Inspect';
		action: [ self inspect ].
	
	segmentList := self newList.
	segmentList
		addColumn: (SpStringTableColumn title: 'Name' evaluated: [ :item | item name ]);
		addColumn: (SpStringTableColumn title: 'Size' evaluated: [ :item | item size asString ]);
		addColumn: (SpStringTableColumn title: '% Full' evaluated: [ :item | item percentFull asString ]);
		whenActivatedDo: [ :selection | self selectSegment: selection selectedItem ].
	
	infoText := self newText.
	infoText beReadOnly.
]

{ #category : 'initialization' }
GbxSegmentTool >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Segment Tool';
		initialExtent: 600 @ 500.
]

{ #category : 'actions' }
GbxSegmentTool >> compact [
	"Compact the selected segment"
	brain ifNotNil: [
		brain compactSegment.
	].
]

{ #category : 'actions' }
GbxSegmentTool >> delete [
	"Delete the selected segment"
	brain ifNotNil: [
		brain deleteSegment.
	].
]

{ #category : 'actions' }
GbxSegmentTool >> inspect [
	"Inspect the selected segment"
	brain selectedSegment ifNotNil: [ :seg |
		seg proxy ifNotNil: [ :proxy |
			GbsInspector inspect: seg proxy session: session.
		].
	].
]

{ #category : 'accessing' }
GbxSegmentTool >> refresh [
	"Refresh the segment list"
	brain ifNotNil: [
		brain refreshSegments.
	].
]

{ #category : 'accessing' }
GbxSegmentTool >> selectSegment: aSegmentHolder [
	"Select a segment and show its info"
	brain ifNotNil: [
		brain selectedSegment: aSegmentHolder.
		infoText text: brain showSegmentInfo.
	].
]

{ #category : 'accessing' }
GbxSegmentTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxSegmentTool >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxSegmentTool >> brain [
	^ brain
]

{ #category : 'accessing' }
GbxSegmentTool >> brain: aBrain [
	brain := aBrain
]

{ #category : 'updating' }
GbxSegmentTool >> updateSegments: aCollection [
	"Update the segment list with new data"
	segmentList items: aCollection.
	segmentList selectIndex: 1.
	segmentList selectedItem ifNotNil: [ :item |
		self selectSegment: item.
	].
]
