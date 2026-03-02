Class {
	#name : 'GbsSessionParametersEditor',
	#superclass : 'SpPresenter',
	#instVars : [
		'nameField',
		'stoneField',
		'userField',
		'passField',
		'gsRemCheck',
		'hostUserField',
		'hostPassField',
		'serviceField',
		'hostRemCheck',
		'netObjField',
		'x509Button',
		'model',
		'btnOk',
		'btnCancel',
		'acceptBlock'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'layout' }
GbsSessionParametersEditor >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: (SpBoxLayout newHorizontal add: 'Config Name:' width: 80; add: nameField; yourself) height: 30;
		add: (SpBoxLayout newVertical
			borderWidth: 10;
			add: (self newLabel label: 'GemStone repository') asPresenter; 
			add: stoneField;
			add: (self newLabel label: 'GemStone username'); add: userField;
			add: (self newLabel label: 'GemStone password'); add: passField;
			add: gsRemCheck;
			yourself);
		add: (SpBoxLayout newVertical
			borderWidth: 10;
			add: (self newLabel label: 'Host connection') asPresenter;
			add: hostUserField;
			add: (self newLabel label: 'Host password'); add: hostPassField;
			add: (self newLabel label: 'Gem Service'); add: serviceField;
			add: hostRemCheck;
			yourself);
		add: (SpBoxLayout newHorizontal add: 'gemnetobject:' width: 80; add: netObjField; yourself) height: 30;
		add: x509Button height: 30;
		
		"Footer: Buttons"
		add: (SpBoxLayout newHorizontal
				add: btnOk;
				add: btnCancel;
				spacing: 10;
				yourself) height: 40;
		yourself
]

{ #category : 'actions' }
GbsSessionParametersEditor >> doAccept [
	self updateModel.
	acceptBlock ifNotNil: [ acceptBlock value ].
	self delete.
]

{ #category : 'initialization' }
GbsSessionParametersEditor >> initializePresenters [
	nameField := self newTextInput placeholder: 'Configuration Name'.
	stoneField := self newTextInput text: 'gs64stone'.
	userField := self newTextInput.
	passField := self newTextInput bePassword.
	gsRemCheck := self newCheckBox label: 'Remember'.
	
	hostUserField := self newTextInput.
	hostPassField := self newTextInput bePassword.
	serviceField := self newTextInput text: 'gemnetobject'.
	hostRemCheck := self newCheckBox label: 'Remember'.
	
	netObjField := self newTextInput.
	x509Button := self newButton label: 'X509...'; icon: (self iconNamed: #smallConfiguration); action: [ self openX509Settings ].

	"Explicit OK/Cancel Buttons"
	btnOk := self newButton label: 'OK'; icon: (self iconNamed: #smallOk); action: [ self doAccept ].
	btnCancel := self newButton label: 'Cancel'; icon: (self iconNamed: #smallCancel); action: [ self delete ].
]

{ #category : 'initialization' }
GbsSessionParametersEditor >> initializeWindow: aWindow [
	aWindow 
		title: 'GemStone Session Parameters Editor';
		initialExtent: 400@600.
]

{ #category : 'accessing' }
GbsSessionParametersEditor >> onAccept: aBlock [
	acceptBlock := aBlock.
]

{ #category : 'actions' }
GbsSessionParametersEditor >> openX509Settings [
	| editor dialog |
	editor := GbsX509ParametersEditor new.
	editor setModel: model.
	
	dialog := editor asModalWindow.
	dialog title: 'X509 GemStone Session Parameters'.
	
	dialog addDefaultButton: 'OK' do: [ :w | 
		editor updateModel. 
		w close ].
		
	dialog addButton: 'Cancel' do: [ :w | w close ].
	
	dialog open.
]

{ #category : 'accessing' }
GbsSessionParametersEditor >> setModel: aParam [
	model := aParam.
	nameField text: model name.
	stoneField text: model gemStoneName.
	userField text: (model username ifNil: ['']).
	passField text: (model password ifNil: ['']).
	gsRemCheck state: model gsRemember.
	hostUserField text: (model hostUsername ifNil: ['']).
	hostPassField text: (model hostPassword ifNil: ['']).
	serviceField text: model gemService.
	hostRemCheck state: model hostRemember.
	netObjField text: (model netObject ifNil: ['']).
]

{ #category : 'actions' }
GbsSessionParametersEditor >> updateModel [
	model name: nameField text.
	model gemStoneName: stoneField text.
	model username: userField text.
	model password: passField text.
	model gsRemember: gsRemCheck state.
	model hostUsername: hostUserField text.
	model hostPassword: hostPassField text.
	model gemService: serviceField text.
	model hostRemember: hostRemCheck state.
	model netObject: netObjField text.
]
