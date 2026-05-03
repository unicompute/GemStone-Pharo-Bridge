Class {
	#name : 'GbsMethodQueryResultsPresenterMagLevToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'tests' }
GbsMethodQueryResultsPresenterMagLevToolsTest >> testBrowseRubyLoadPathReportUsesRuntimeReport [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseRubyLoadPathReport.
	self assert: (presenter lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (presenter lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterMagLevToolsTest >> testBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default transientLoadedFeatures: 1'
			ifTrue: [ ^ #('json' 'set') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseRubyLoadedFeaturesReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Loaded Features').
	self assert: (presenter lastInfoMessage includesSubstring: 'json')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterMagLevToolsTest >> testBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default persistentLoadedFeatures: 1'
			ifTrue: [ ^ #('bigdecimal') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseRubyPersistentLoadedFeaturesReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Persistent Loaded Features').
	self assert: (presenter lastInfoMessage includesSubstring: 'bigdecimal')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterMagLevToolsTest >> testBrowseTopLevelAutoloadRegistrationsReportUsesRuntimeReport [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:')
			ifTrue: [ ^ { #('DemoConst' nil false nil 'demo/persistent_file' true true) } ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseTopLevelAutoloadRegistrationsReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Autoload Registrations').
	self assert: (presenter lastInfoMessage includesSubstring: 'DemoConst -> demo/persistent_file [Pending] {Transient+Persistent}')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterMagLevToolsTest >> testBrowseRubyRuntimeProvenanceGraphUsesRuntimeReport [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseRubyRuntimeProvenanceGraph.
	self assert: (presenter lastInfoMessage includesSubstring: 'Ruby Runtime Provenance').
	self assert: (presenter lastInfoMessage includesSubstring: 'Transient Feature -> app/models/invoice.rb')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterMagLevToolsTest >> testBrowseRubyRuntimeProvenanceBrowserOpensStructuredGraph [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseRubyRuntimeProvenanceBrowser.
	self assert: presenter lastInfoMessage equals: 'Ruby Runtime Provenance'.
	self assert: presenter lastProvenanceGraph notNil.
	self assert: presenter lastProvenanceGraph browserRows size > 0
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterMagLevToolsTest >> testBrowseRubyRuntimeProvenanceActionChooserExecutesSelectedAction [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
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
	presenter session: session.
	presenter enqueueChooseAnswer: 1.

	self assert: presenter browseRubyRuntimeProvenanceActionChooser.
	self assert: (presenter lastInfoMessage includesSubstring: 'Executed require app/models/invoice.rb => ''required''').
	self assert: (presenter lastInfoMessage includesSubstring: 'Ruby Runtime Provenance')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterMagLevToolsTest >> testBrowseMaglevFinalizerRegistryReportUsesDiagnosticsReport [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ GbsProxy oop: 9191 session: session ].
		(script includesSubstring: 'findReferencesInMemory')
			ifTrue: [ ^ { GbsProxy oop: 9292 session: session } ].
		self fail ].
	presenter session: session.

	self assert: presenter browseMaglevFinalizerRegistryReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'MagLev Finalizer Registry oop=9191 Referencers').
	self assert: (presenter lastInfoMessage includesSubstring: 'oop=9292')
]
