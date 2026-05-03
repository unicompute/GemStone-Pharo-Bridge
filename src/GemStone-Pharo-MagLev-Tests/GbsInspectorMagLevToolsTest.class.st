Class {
	#name : 'GbsInspectorMagLevToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'tests' }
GbsInspectorMagLevToolsTest >> testBrowseRubyLoadPathReportUsesRuntimeReport [
	| inspector session |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: session materializationProfile class equals: GbsShallowMaterializationProfile.
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].

	inspector instVarNamed: 'session' put: session.

	self assert: inspector browseRubyLoadPathReport.
	self assert: (inspector lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (inspector lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbsInspectorMagLevToolsTest >> testBrowseMaglevFinalizerRegistryReportUsesDiagnosticsFacade [
	| inspector session |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ GbsProxy oop: 9001 session: session ].
		(script includesSubstring: 'findReferencesInMemory') ifTrue: [
			^ { GbsProxy oop: 9101 session: session } ].
		self fail ].

	inspector instVarNamed: 'session' put: session.

	self assert: inspector browseMaglevFinalizerRegistryReport.
	self assert: (inspector lastInfoMessage includesSubstring: 'MagLev Finalizer Registry oop=9001 Referencers').
	self assert: (inspector lastInfoMessage includesSubstring: 'oop=9101')
]
