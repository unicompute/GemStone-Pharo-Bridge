Class {
	#name : 'GbsMethodQueryResultsPresenterTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testNormalizeReferencesFromMultilineStringWritesTranscript [
	| presenter raw normalized |
	presenter := GbsMethodQueryResultsPresenter new.
	raw := 'Object>>size', Character lf asString, 'Behavior>>new'.
	normalized := presenter normalizeReferences: raw.

	Transcript
		show: 'GbsMethodQueryResultsPresenterTest normalize multiline rawCount=2 normalizedCount=';
		show: normalized size asString;
		show: ' first=';
		show: (normalized ifEmpty: [ '<empty>' ] ifNotEmpty: [ normalized first asString ]);
		cr.

	self assert: normalized size equals: 2.
	self assert: (normalized includes: 'Object>>size').
	self assert: (normalized includes: 'Behavior>>new')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testNormalizeReferencesFromTabbedRowsWritesTranscript [
	| presenter rows normalized |
	presenter := GbsMethodQueryResultsPresenter new.
	rows := {
		'1', Character tab asString, 'Object', Character tab asString, 'size'.
		'2', Character tab asString, 'Behavior', Character tab asString, 'new'
	}.
	normalized := presenter normalizeReferences: rows.

	Transcript
		show: 'GbsMethodQueryResultsPresenterTest normalize tabbed rowCount=';
		show: rows size asString;
		show: ' normalizedCount=';
		show: normalized size asString;
		show: ' values=';
		show: normalized printString;
		cr.

	self assert: normalized size equals: 2.
	self assert: (normalized includes: 'Object>>size').
	self assert: (normalized includes: 'Behavior>>new')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testClassicLauncherQueryOrganizerParsesRowsWritesTranscript [
	| session results |
	session := MockGbsSession new.
	session stubs
		at: #executeAndFetch
		put: [ :script |
			'Object>>size', Character lf asString, 'Behavior>>new' ].

	results := GbsClassicLauncher
		queryOrganizerMethodsFor: 'size'
		mode: 'implementors'
		inSession: session.

	Transcript
		show: 'GbsMethodQueryResultsPresenterTest launcher query resultsCount=';
		show: results size asString;
		show: ' values=';
		show: results printString;
		cr.

	self assert: results size equals: 2.
	self assert: (results includes: 'Object>>size').
	self assert: (results includes: 'Behavior>>new')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testQueryResultsTitleIncludesSessionAndCount [
	| presenter session title |
	presenter := GbsMethodQueryResultsPresenter new.
	session := GbsSession new.
	session sessionId: 7.
	presenter session: session.

	title := presenter
		queryResultsTitleForSelector: 'size'
		modePrefix: 'Implementors of '
		count: 71.

	self assert: title equals: 'Session 7 Implementors of size (71)'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testQueryResultsTitleWithoutSessionId [
	| presenter title |
	presenter := GbsMethodQueryResultsPresenter new.
	presenter session: Object new.

	title := presenter
		queryResultsTitleForSelector: 'size'
		modePrefix: 'Senders of '
		count: 3.

	self assert: title equals: 'Senders of size (3)'
]
