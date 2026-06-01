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
		'netldiHostField',
		'netldiPortField',
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
			add: (self newLabel label: 'Host username'); add: hostUserField;
			add: (self newLabel label: 'Host password'); add: hostPassField;
			add: (self newLabel label: 'Gem service'); add: serviceField;
			add: (self newLabel label: 'NetLDI host/IP'); add: netldiHostField;
			add: (self newLabel label: 'NetLDI name/port'); add: netldiPortField;
			add: hostRemCheck;
			yourself);
		add: (SpBoxLayout newHorizontal add: 'Net object:' width: 80; add: netObjField; yourself) height: 30;
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
	self validationErrorMessage ifNotNil: [ :message |
		self inform: message.
		^ false ].
	acceptBlock ifNotNil: [ acceptBlock value ].
	self delete.
	^ true
]

{ #category : 'private' }
GbsSessionParametersEditor >> normalizedTextFrom: aTextInput [
	^ (aTextInput text ifNil: [ '' ]) asString trimBoth
]

{ #category : 'private' }
GbsSessionParametersEditor >> optionalTextFrom: aTextInput [
	| text |
	text := self normalizedTextFrom: aTextInput.
	^ text isEmpty ifTrue: [ nil ] ifFalse: [ text ]
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
	netldiHostField := self newTextInput placeholder: 'optional host or IP'.
	netldiPortField := self newTextInput placeholder: 'optional name or port'.
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
		initialExtent: 430@680.
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
	netldiHostField text: (model netldiHostOrIp ifNil: ['']).
	netldiPortField text: (model netldiNameOrPort ifNil: ['']).
	hostRemCheck state: model hostRemember.
	netObjField text: (model netObject ifNil: ['']).
]

{ #category : 'actions' }
GbsSessionParametersEditor >> updateModel [
	model name: (self normalizedTextFrom: nameField).
	model gemStoneName: (self normalizedTextFrom: stoneField).
	model username: (self normalizedTextFrom: userField).
	model password: passField text.
	model gsRemember: gsRemCheck state.
	model hostUsername: (self optionalTextFrom: hostUserField).
	model hostPassword: hostPassField text.
	model gemService: serviceField text.
	model netldiHostOrIp: (self optionalTextFrom: netldiHostField).
	model netldiNameOrPort: (self optionalTextFrom: netldiPortField).
	model hostRemember: hostRemCheck state.
	model netObject: (self optionalTextFrom: netObjField).
	model normalizeConnectionFields
]

{ #category : 'validation' }
GbsSessionParametersEditor >> validationErrorMessage [
	| messages |
	model ifNil: [ ^ 'No GemStone session configuration is loaded.' ].
	messages := OrderedCollection new.
	(model name ifNil: [ '' ]) isEmpty ifTrue: [
		messages add: 'Configuration name is required.' ].
	messages addAll: model loginValidationMessages.
	^ model validationMessageFrom: messages
]
