Class {
	#name : 'GbsX509ParametersEditor',
	#superclass : 'SpPresenter',
	#instVars : [
		'displayUserField',
		'caCertField',
		'certField',
		'keyField',
		'netldiHostField',
		'netldiPortField',
		'dirArgField',
		'extraArgsField',
		'logArgField',
		'model'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'layout' }
GbsX509ParametersEditor >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: (self newLabel label: 'X509 GemStone Session Parameters') expand: false;
		add: (SpGridLayout new
			beColumnNotHomogeneous;
			add: 'Display username' at: 1@1; add: displayUserField at: 2@1;
			add: 'caCert' at: 1@2; add: caCertField at: 2@2;
			add: 'cert' at: 1@3; add: certField at: 2@3;
			add: 'privateKey' at: 1@4; add: keyField at: 2@4;
			add: 'netldiHostOrIp' at: 1@5; add: netldiHostField at: 2@5;
			add: 'netldiNameOrPort' at: 1@6; add: netldiPortField at: 2@6;
			add: 'dirArg' at: 1@7; add: dirArgField at: 2@7;
			add: 'extraGemArgs' at: 1@8; add: extraArgsField at: 2@8;
			add: 'logArg' at: 1@9; add: logArgField at: 2@9;
			yourself);
		yourself
]

{ #category : 'initialization' }
GbsX509ParametersEditor >> initializePresenters [
	displayUserField := self newTextInput.
	caCertField := self newTextInput.
	certField := self newTextInput.
	keyField := self newTextInput.
	netldiHostField := self newTextInput.
	netldiPortField := self newTextInput.
	dirArgField := self newTextInput.
	extraArgsField := self newTextInput.
	logArgField := self newTextInput.
]

{ #category : 'accessing' }
GbsX509ParametersEditor >> setModel: aParam [
	model := aParam.
	displayUserField text: (model displayUsername ifNil: ['']).
	caCertField text: (model caCert ifNil: ['']).
	certField text: (model cert ifNil: ['']).
	keyField text: (model privateKey ifNil: ['']).
	netldiHostField text: (model netldiHostOrIp ifNil: ['']).
	netldiPortField text: (model netldiNameOrPort ifNil: ['']).
	dirArgField text: (model dirArg ifNil: ['']).
	extraArgsField text: (model extraGemArgs ifNil: ['']).
	logArgField text: (model logArg ifNil: ['']).
]

{ #category : 'actions' }
GbsX509ParametersEditor >> updateModel [
	model displayUsername: displayUserField text.
	model caCert: caCertField text.
	model cert: certField text.
	model privateKey: keyField text.
	model netldiHostOrIp: netldiHostField text.
	model netldiNameOrPort: netldiPortField text.
	model dirArg: dirArgField text.
	model extraGemArgs: extraArgsField text.
	model logArg: logArgField text.
]
