Class {
	#name : 'GbxTrippyMagLevToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'tests' }
GbxTrippyMagLevToolsTest >> testBrowseRubyLoadPathReportUsesRuntimeReport [
	| trippy session |
	trippy := CoreTestableGbxTrippy new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: session materializationProfile class equals: GbsShallowMaterializationProfile.
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].

	trippy session: session.

	self assert: trippy browseRubyLoadPathReport.
	self assert: (trippy lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (trippy lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbxTrippyMagLevToolsTest >> testBrowseMaglevFinalizerRegistryReportUsesDiagnosticsFacade [
	| trippy session |
	trippy := CoreTestableGbxTrippy new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ GbsProxy oop: 9001 session: session ].
		(script includesSubstring: 'findReferencesInMemory') ifTrue: [
			^ { GbsProxy oop: 9101 session: session } ].
		self fail ].

	trippy session: session.

	self assert: trippy browseMaglevFinalizerRegistryReport.
	self assert: (trippy lastInfoMessage includesSubstring: 'MagLev Finalizer Registry oop=9001 Referencers').
	self assert: (trippy lastInfoMessage includesSubstring: 'oop=9101')
]
