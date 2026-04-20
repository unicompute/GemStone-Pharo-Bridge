Class {
	#name : 'GbsRubyLoadPathEntry',
	#superclass : 'GbsRubyRuntimeEntry',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRubyLoadPathEntry class >> path: aString [
	^ self
		kind: #loadPath
		value: aString
]

{ #category : 'accessing' }
GbsRubyLoadPathEntry >> path [
	^ self value
]

{ #category : 'querying' }
GbsRubyLoadPathEntry >> basename [
	| pathString |
	pathString := self path ifNil: [ ^ nil ].
	^ pathString asString copyAfterLast: $/
]

{ #category : 'querying' }
GbsRubyLoadPathEntry >> extension [
	| baseName |
	baseName := self basename.
	baseName ifNil: [ ^ nil ].
	(baseName includes: $.) ifFalse: [ ^ nil ].
	^ baseName copyAfterLast: $.
]

{ #category : 'querying' }
GbsRubyLoadPathEntry >> directoryPath [
	| pathString |
	pathString := self path ifNil: [ ^ nil ].
	(pathString asString includes: $/) ifFalse: [ ^ nil ].
	^ pathString asString copyUpToLast: $/
]

{ #category : 'testing' }
GbsRubyLoadPathEntry >> isAbsolutePath [
	| pathString |
	pathString := self path ifNil: [ ^ false ].
	^ pathString asString beginsWith: '/'
]

{ #category : 'testing' }
GbsRubyLoadPathEntry >> isRelativePath [
	^ self path notNil and: [ self isAbsolutePath not ]
]

{ #category : 'querying' }
GbsRubyLoadPathEntry >> pathComponents [
	| pathString |
	pathString := self path ifNil: [ ^ #() ].
	^ (pathString asString findTokens: '/') asArray
]

{ #category : 'querying' }
GbsRubyLoadPathEntry >> provenanceLabel [
	^ self isAbsolutePath
		ifTrue: [ 'Absolute Load Path' ]
		ifFalse: [ 'Relative Load Path' ]
]

{ #category : 'querying' }
GbsRubyLoadPathEntry >> provenanceLinks [
	^ { GbsRubyRuntimeProvenanceLink
		source: self provenanceLabel
		target: (self path ifNil: [ '(nil)' ])
		kind: #loadPath
		entry: self }
]

{ #category : 'querying' }
GbsRubyLoadPathEntry >> rootComponent [
	| parts |
	parts := self pathComponents.
	parts ifEmpty: [ ^ nil ].
	^ parts first
]
