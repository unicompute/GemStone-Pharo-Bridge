Class {
	#name : 'GbsStructuredValueInspectorPresenterCoreToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsStructuredValueInspectorPresenterCoreToolsTest >> testBrowseObjectsInMemoryReportDelegatesPromptedRange [
	| presenter informed requestedRange answers |
	presenter := GbsStructuredValueInspectorPresenter new.
	answers := OrderedCollection with: '2' with: '5'.
	presenter
		propertyAt: #requestInputBlock put: [ :prompt :default | answers removeFirst ];
		propertyAt: #objectsInMemoryReportBlock put: [ :start :limit |
			requestedRange := { start. limit }.
			'Objects In Memory', String cr, String cr, 'oop=9201' ];
		propertyAt: #informBlock put: [ :message | informed := message ].

	presenter browseObjectsInMemoryReport.

	self assert: requestedRange equals: #(2 5).
	self assert: informed equals: 'Objects In Memory', String cr, String cr, 'oop=9201'
]

{ #category : 'tests' }
GbsStructuredValueInspectorPresenterCoreToolsTest >> testBrowsePromptedSessionStateKeyDelegatesParsedKey [
	| presenter requestedKey |
	presenter := GbsStructuredValueInspectorPresenter new.

	presenter propertyAt: #requestInputBlock put: [ :prompt :default | '21' ].
	presenter propertyAt: #sessionStateBlock put: [ :key | requestedKey := key ].

	presenter browsePromptedSessionStateKey.

	self assert: requestedKey equals: 21
]

{ #category : 'tests' }
GbsStructuredValueInspectorPresenterCoreToolsTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| presenter informed |
	presenter := GbsStructuredValueInspectorPresenter new.

	presenter propertyAt: #requestInputBlock put: [ :prompt :default | 'abc' ].
	presenter propertyAt: #informBlock put: [ :message | informed := message ].
	presenter propertyAt: #sessionStateBlock put: [ :key | self fail ].

	presenter browsePromptedSessionStateKey.

	self assert: informed equals: 'Enter a numeric session state key.'
]

{ #category : 'tests' }
GbsStructuredValueInspectorPresenterCoreToolsTest >> testBrowsePromptedSessionStateKeysReportDelegatesParsedKeys [
	| presenter informed keys |
	presenter := GbsStructuredValueInspectorPresenter new.
	presenter
		propertyAt: #requestInputBlock put: [ :prompt :default | '19, 21' ];
		propertyAt: #sessionStateKeysReportBlock put: [ :parsedKeys |
			keys := parsedKeys.
			'Session State', String cr, String cr, 'Key 19' ];
		propertyAt: #informBlock put: [ :message | informed := message ].

	presenter browsePromptedSessionStateKeysReport.

	self assert: keys equals: #(19 21).
	self assert: informed equals: 'Session State', String cr, String cr, 'Key 19'
]

{ #category : 'tests' }
GbsStructuredValueInspectorPresenterCoreToolsTest >> testBrowseStaleTypedWrapperLifecycleReportUsesConfiguredBlock [
	| presenter informed |
	presenter := GbsStructuredValueInspectorPresenter new.
	presenter
		propertyAt: #staleTypedWrapperReportBlock put: [ 'Typed Wrapper Lifecycle', String cr, String cr, 'stale' ];
		propertyAt: #informBlock put: [ :message | informed := message ].

	presenter browseStaleTypedWrapperLifecycleReport.

	self assert: informed equals: 'Typed Wrapper Lifecycle', String cr, String cr, 'stale'
]

{ #category : 'tests' }
GbsStructuredValueInspectorPresenterCoreToolsTest >> testBrowseTypedWrapperLifecycleReportUsesConfiguredBlock [
	| presenter informed |
	presenter := GbsStructuredValueInspectorPresenter new.
	presenter
		propertyAt: #typedWrapperLifecycleReportBlock put: [ 'Typed Wrapper Lifecycle', String cr, String cr, 'ok' ];
		propertyAt: #informBlock put: [ :message | informed := message ].

	presenter browseTypedWrapperLifecycleReport.

	self assert: informed equals: 'Typed Wrapper Lifecycle', String cr, String cr, 'ok'
]

{ #category : 'tests' }
GbsStructuredValueInspectorPresenterCoreToolsTest >> testBrowseReferencersDelegatesReferencersBlockWithSelectedRow [
	| presenter fakeTable selected |
	presenter := GbsStructuredValueInspectorPresenter new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: { 'users'. 'aDictionary(...)' }.

	presenter instVarNamed: 'table' put: fakeTable.
	presenter propertyAt: #referencersBlock put: [ :row | selected := row ].

	presenter browseReferencersForSelectedEntry.

	self assert: selected equals: { 'users'. 'aDictionary(...)' }
]

{ #category : 'tests' }
GbsStructuredValueInspectorPresenterCoreToolsTest >> testMenuIncludesSessionStateActionWhenConfigured [
	| presenter |
	presenter := GbsStructuredValueInspectorPresenter new.
	presenter propertyAt: #sessionStateBlock put: [ :key | ].

	self assert: presenter canBrowseSessionState
]
