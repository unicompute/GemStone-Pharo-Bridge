Class {
	#name : 'TestableGbsBrowser',
	#superclass : 'GbsBrowser',
	#instVars : [
		'lastInfoMessage',
		'lastProtocolSelected',
		'lastCompileSource',
		'compileSpyEnabled'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'testing' }
TestableGbsBrowser >> enableCompileSpy [
	compileSpyEnabled := true
]

{ #category : 'actions' }
TestableGbsBrowser >> compileMethod: newSource [
	compileSpyEnabled ifTrue: [
		lastCompileSource := newSource.
		^ #compiled
	].
	^ super compileMethod: newSource
]

{ #category : 'testing' }
TestableGbsBrowser >> runSuperCompileMethod: newSource [
	^ super compileMethod: newSource
]

{ #category : 'ui' }
TestableGbsBrowser >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'actions' }
TestableGbsBrowser >> protocolSelected: protocolName [
	lastProtocolSelected := protocolName
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastProtocolSelected [
	^ lastProtocolSelected
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastCompileSource [
	^ lastCompileSource
]
