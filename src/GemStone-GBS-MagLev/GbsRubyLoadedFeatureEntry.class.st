Class {
	#name : 'GbsRubyLoadedFeatureEntry',
	#superclass : 'GbsRubyRuntimeEntry',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRubyLoadedFeatureEntry class >> feature: aString [
	^ self
		kind: #loadedFeature
		value: aString
]

{ #category : 'instance creation' }
GbsRubyLoadedFeatureEntry class >> feature: aString persistent: aBoolean [
	^ self
		kind: #loadedFeature
		value: aString
		persistent: aBoolean
]

{ #category : 'accessing' }
GbsRubyLoadedFeatureEntry >> feature [
	^ self value
]

{ #category : 'querying' }
GbsRubyLoadedFeatureEntry >> basename [
	| featureString |
	featureString := self feature ifNil: [ ^ nil ].
	^ featureString asString copyAfterLast: $/
]

{ #category : 'querying' }
GbsRubyLoadedFeatureEntry >> extension [
	| baseName |
	baseName := self basename.
	baseName ifNil: [ ^ nil ].
	(baseName includes: $.) ifFalse: [ ^ nil ].
	^ baseName copyAfterLast: $.
]

{ #category : 'querying' }
GbsRubyLoadedFeatureEntry >> directoryPath [
	| featureString |
	featureString := self feature ifNil: [ ^ nil ].
	(featureString asString includes: $/) ifFalse: [ ^ nil ].
	^ featureString asString copyUpToLast: $/
]

{ #category : 'printing' }
GbsRubyLoadedFeatureEntry >> displayString [
	^ self isPersistent
		ifTrue: [ self feature asString, ' [persistent]' ]
		ifFalse: [ super displayString ]
]

{ #category : 'testing' }
GbsRubyLoadedFeatureEntry >> isAbsolutePath [
	| featureString |
	featureString := self feature ifNil: [ ^ false ].
	^ featureString asString beginsWith: '/'
]

{ #category : 'testing' }
GbsRubyLoadedFeatureEntry >> isRelativePath [
	^ self feature notNil and: [ self isAbsolutePath not ]
]

{ #category : 'testing' }
GbsRubyLoadedFeatureEntry >> isRubySource [
	^ (self extension ifNil: [ '' ]) asLowercase = 'rb'
]

{ #category : 'querying' }
GbsRubyLoadedFeatureEntry >> pathComponents [
	| featureString |
	featureString := self feature ifNil: [ ^ #() ].
	^ (featureString asString findTokens: '/') asArray
]

{ #category : 'querying' }
GbsRubyLoadedFeatureEntry >> provenanceLabel [
	^ self isPersistent
		ifTrue: [ 'Persistent Feature' ]
		ifFalse: [ 'Transient Feature' ]
]

{ #category : 'querying' }
GbsRubyLoadedFeatureEntry >> provenanceLinks [
	^ { GbsRubyRuntimeProvenanceLink
		source: self provenanceLabel
		target: (self feature ifNil: [ '(nil)' ])
		kind: (self isPersistent
			ifTrue: [ #persistentLoadedFeature ]
			ifFalse: [ #loadedFeature ])
		entry: self }
]

{ #category : 'querying' }
GbsRubyLoadedFeatureEntry >> provenanceActionsUsing: aRuntimeFacade [
	self feature ifNil: [ ^ #() ].
	^ {
		self requireAction.
		self loadAction }
]

{ #category : 'querying' }
GbsRubyLoadedFeatureEntry >> rootComponent [
	| parts |
	parts := self pathComponents.
	parts ifEmpty: [ ^ nil ].
	^ parts first
]
