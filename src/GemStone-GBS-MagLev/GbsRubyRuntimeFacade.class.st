Class {
	#name : 'GbsRubyRuntimeFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRubyRuntimeFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> appendRuntimeReportOn: aStream namespace: aNamespaceMirror selectedConstant: aConstantMirror selectedAutoload: anAutoloadMirror [
	(self
		reportForNamespace: aNamespaceMirror
		selectedConstant: aConstantMirror
		selectedAutoload: anAutoloadMirror)
			appendOn: aStream
]

{ #category : 'actions' }
GbsRubyRuntimeFacade >> clearPersistentLoadedFeatures [
	^ session clearPersistentRubyLoadedFeatures
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> loadPath [
	^ session rubyLoadPath ifNil: [ #() ]
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> loadPathEntries [
	^ self report loadPathEntries
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> loadPathSection [
	^ self report loadPathSection
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> loadPathReportText [
	^ self loadPathSection text
]

{ #category : 'actions' }
GbsRubyRuntimeFacade >> loadFileNamed: aString [
	^ session rubyLoadFileNamed: aString
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> loadedFeatures [
	^ session rubyLoadedFeatures ifNil: [ #() ]
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> loadedFeatureEntries [
	^ self report loadedFeatureEntries
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> loadedFeaturesSection [
	^ self report loadedFeaturesSection
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> loadedFeaturesReportText [
	^ self loadedFeaturesSection text
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> objectSpaceDiagnostics [
	^ session objectSpaceDiagnostics
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> persistentLoadedFeatures [
	^ session rubyPersistentLoadedFeatures ifNil: [ #() ]
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> persistentLoadedFeatureEntries [
	^ self report persistentLoadedFeatureEntries
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> persistentLoadedFeaturesSection [
	^ self report persistentLoadedFeaturesSection
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> persistentLoadedFeaturesReportText [
	^ self persistentLoadedFeaturesSection text
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> provenanceGraph [
	^ self report provenanceGraph
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> provenanceActions [
	^ self provenanceGraph actions
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> provenanceGraphText [
	^ self provenanceGraph text
]

{ #category : 'actions' }
GbsRubyRuntimeFacade >> executeProvenanceAction: anAction [
	anAction ifNil: [ ^ nil ].
	^ anAction executeUsing: self
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> autoloadRegistrationsSectionForNamespace: aNamespaceMirror [
	^ (self
		reportForNamespace: aNamespaceMirror
		selectedConstant: nil
		selectedAutoload: nil) autoloadRegistrationsSection
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> autoloadRegistrationEntriesForNamespace: aNamespaceMirror [
	^ (self
		reportForNamespace: aNamespaceMirror
		selectedConstant: nil
		selectedAutoload: nil) autoloadRegistrationEntries
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> autoloadRegistrationsReportTextForNamespace: aNamespaceMirror [
	^ (self autoloadRegistrationsSectionForNamespace: aNamespaceMirror) text
]

{ #category : 'actions' }
GbsRubyRuntimeFacade >> requireFileNamed: aString [
	^ session rubyRequireFileNamed: aString
]

{ #category : 'actions' }
GbsRubyRuntimeFacade >> requireRelativeFileNamed: aString relativeTo: aBasePath [
	^ session
		rubyRequireRelativeFileNamed: aString
		relativeTo: aBasePath
]

{ #category : 'actions' }
GbsRubyRuntimeFacade >> loadRelativeFileNamed: aString relativeTo: aBasePath [
	^ session
		rubyLoadRelativeFileNamed: aString
		relativeTo: aBasePath
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> resolvedRelativePath: aString relativeTo: aBasePath [
	^ session
		rubyResolvedRelativePath: aString
		relativeTo: aBasePath
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> report [
	^ self
		reportForNamespace: nil
		selectedConstant: nil
		selectedAutoload: nil
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> reportSections [
	^ self report sections
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> reportForNamespace: aNamespaceMirror selectedConstant: aConstantMirror selectedAutoload: anAutoloadMirror [
	^ (GbsRubyRuntimeReport on: session)
		namespace: aNamespaceMirror;
		selectedConstant: aConstantMirror;
		selectedAutoload: anAutoloadMirror;
		yourself
]

{ #category : 'querying' }
GbsRubyRuntimeFacade >> reportSectionsForNamespace: aNamespaceMirror selectedConstant: aConstantMirror selectedAutoload: anAutoloadMirror [
	^ (self
		reportForNamespace: aNamespaceMirror
		selectedConstant: aConstantMirror
		selectedAutoload: anAutoloadMirror) sections
]

{ #category : 'printing' }
GbsRubyRuntimeFacade >> reportText [
	^ self report text
]

{ #category : 'accessing' }
GbsRubyRuntimeFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsRubyRuntimeFacade >> session: aSession [
	session := aSession
]
