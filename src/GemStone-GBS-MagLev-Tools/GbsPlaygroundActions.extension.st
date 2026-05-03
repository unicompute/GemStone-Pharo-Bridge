Extension { #name : 'GbsPlaygroundActions' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsPlaygroundActions class >> gsBrowseRubyLoadPathReportIn: aPlaygroundPresenter [
	| activeSession |
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ false ].
	self inform: activeSession rubyRuntime loadPathReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsPlaygroundActions class >> gsBrowseRubyLoadedFeaturesReportIn: aPlaygroundPresenter [
	| activeSession |
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ false ].
	self inform: activeSession rubyRuntime loadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsPlaygroundActions class >> gsBrowseRubyPersistentLoadedFeaturesReportIn: aPlaygroundPresenter [
	| activeSession |
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ false ].
	self inform: activeSession rubyRuntime persistentLoadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsPlaygroundActions class >> gsBrowseTopLevelAutoloadRegistrationsReportIn: aPlaygroundPresenter [
	| activeSession |
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ false ].
	self inform: (activeSession rubyRuntime
		autoloadRegistrationsReportTextForNamespace: activeSession topLevelNamespaceMirror).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsPlaygroundActions class >> gsBrowseMaglevFinalizerRegistryReportIn: aPlaygroundPresenter [
	| activeSession |
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ false ].
	self inform: activeSession objectSpaceDiagnostics finalizerRegistryReport text.
	^ true
]
