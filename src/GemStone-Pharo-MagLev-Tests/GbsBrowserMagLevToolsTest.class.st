Class {
	#name : 'GbsBrowserMagLevToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'tests' }
GbsBrowserMagLevToolsTest >> testBrowseObjectLogBrowserOpensStructuredLog [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'ObjectLogEntry objectLog') ifTrue: [
			^ { { 1. 2. 'Failure'. 88. '2026-01-01T10:00:00Z'. 'debug'. true. nil. nil } } ].
		self fail ].
	browser session: session.

	self assert: browser browseObjectLogBrowser.
	self assert: browser lastInfoMessage equals: 'ObjectLog'.
	self assert: browser lastObjectLog notNil.
	self assert: browser lastObjectLog browserRows size equals: 1
]

{ #category : 'tests' }
GbsBrowserMagLevToolsTest >> testBrowseObjectLogReportUsesFacade [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'ObjectLogEntry objectLog') ifTrue: [
			^ { { 1. 4. 'Entry saved'. 1234. '2026-01-01T10:00:00Z'. 'runtime'. true. nil. nil } } ].
		self fail ].
	browser session: session.

	self assert: browser browseObjectLogReport.
	self assert: (browser lastInfoMessage includesSubstring: 'ObjectLog').
	self assert: (browser lastInfoMessage includesSubstring: 'Entry saved')
]

{ #category : 'tests' }
GbsBrowserMagLevToolsTest >> testBrowseRubyLoadPathReportUsesRuntimeReport [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	browser session: session.

	self assert: browser browseRubyLoadPathReport.
	self assert: (browser lastInfoMessage includesSubstring: 'Ruby Runtime').
	self assert: (browser lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (browser lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbsBrowserMagLevToolsTest >> testBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default transientLoadedFeatures: 1'
			ifTrue: [ ^ #('json' 'set') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	browser session: session.

	self assert: browser browseRubyLoadedFeaturesReport.
	self assert: (browser lastInfoMessage includesSubstring: 'Loaded Features').
	self assert: (browser lastInfoMessage includesSubstring: 'json')
]

{ #category : 'tests' }
GbsBrowserMagLevToolsTest >> testBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default persistentLoadedFeatures: 1'
			ifTrue: [ ^ #('bigdecimal') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	browser session: session.

	self assert: browser browseRubyPersistentLoadedFeaturesReport.
	self assert: (browser lastInfoMessage includesSubstring: 'Persistent Loaded Features').
	self assert: (browser lastInfoMessage includesSubstring: 'bigdecimal')
]

{ #category : 'tests' }
GbsBrowserMagLevToolsTest >> testBrowseRubyRuntimeProvenanceActionChooserExecutesSelectedAction [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'RubyContext default requireFileNamed: ''app/models/invoice.rb'' env: 1')
			ifTrue: [ ^ 'required' ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	browser session: session.
	browser enqueueChooseAnswer: 1.

	self assert: browser browseRubyRuntimeProvenanceActionChooser.
	self assert: (browser lastInfoMessage includesSubstring: 'Executed require app/models/invoice.rb => ''required''').
	self assert: (browser lastInfoMessage includesSubstring: 'Ruby Runtime Provenance')
]

{ #category : 'tests' }
GbsBrowserMagLevToolsTest >> testBrowseRubyRuntimeProvenanceBrowserOpensStructuredGraph [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	browser session: session.

	self assert: browser browseRubyRuntimeProvenanceBrowser.
	self assert: browser lastInfoMessage equals: 'Ruby Runtime Provenance'.
	self assert: browser lastProvenanceGraph notNil.
	self assert: browser lastProvenanceGraph browserRows size > 0
]

{ #category : 'tests' }
GbsBrowserMagLevToolsTest >> testBrowseRubyRuntimeProvenanceGraphUsesRuntimeReport [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	browser session: session.

	self assert: browser browseRubyRuntimeProvenanceGraph.
	self assert: (browser lastInfoMessage includesSubstring: 'Ruby Runtime Provenance').
	self assert: (browser lastInfoMessage includesSubstring: 'Transient Feature -> app/models/invoice.rb')
]

{ #category : 'tests' }
GbsBrowserMagLevToolsTest >> testBrowseTopLevelAutoloadRegistrationsReportUsesRuntimeReport [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:')
			ifTrue: [ ^ { #('DemoConst' nil false nil 'demo/persistent_file' true true) } ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	browser session: session.

	self assert: browser browseTopLevelAutoloadRegistrationsReport.
	self assert: (browser lastInfoMessage includesSubstring: 'Autoload Registrations').
	self assert: (browser lastInfoMessage includesSubstring: 'DemoConst -> demo/persistent_file [Pending] {Transient+Persistent}')
]
