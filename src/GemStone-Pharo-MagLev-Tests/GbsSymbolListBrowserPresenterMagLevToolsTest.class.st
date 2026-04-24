Class {
	#name : 'GbsSymbolListBrowserPresenterMagLevToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'tests' }
GbsSymbolListBrowserPresenterMagLevToolsTest >> testBrowseRubyLoadPathReportUsesSessionRuntimeFacade [
	| presenter mockSession |
	presenter := CoreTestableGbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: mockSession materializationProfile class equals: GbsShallowMaterializationProfile.
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib' 'app/models') ].
		self fail ].

	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseRubyLoadPathReport.
	self assert: (presenter lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (presenter lastInfoMessage includesSubstring: 'lib')
]
