"
Headless tests for the VW-style transaction conflict report: GbsSession>>transactionConflicts parses the
server-side flattened conflict text into a dictionary of conflict-kind -> array of OOPs, and
GbsCommitConflictError carries it.
"
Class {
	#name : 'GbsTransactionConflictReportCoreTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'private' }
GbsTransactionConflictReportCoreTest >> sessionReturningConflictText: aString [
	| session |
	session := CoreMockGbsSession new.
	session stubs at: #fetchRemoteCommandBody put: [ :body :lits :oops :ctx | aString ].
	^ session
]

{ #category : 'tests' }
GbsTransactionConflictReportCoreTest >> testParsesConflictKindsAndOops [
	| session report |
	session := self sessionReturningConflictText: 'Write-Write	1001 1002', String lf, 'Read-Write	2001'.
	report := session transactionConflicts.
	self assert: (report at: #'Write-Write') equals: #(1001 1002).
	self assert: (report at: #'Read-Write') equals: #(2001).
	self assert: report size equals: 2
]

{ #category : 'tests' }
GbsTransactionConflictReportCoreTest >> testEmptyTextGivesEmptyReport [
	| session |
	session := self sessionReturningConflictText: ''.
	self assert: session transactionConflicts isEmpty
]

{ #category : 'tests' }
GbsTransactionConflictReportCoreTest >> testIndexObjectMarker [
	| session report |
	session := self sessionReturningConflictText: 'Write-Write	1001 index 1002'.
	report := session transactionConflicts.
	self assert: ((report at: #'Write-Write') includes: #indexObject).
	self assert: ((report at: #'Write-Write') includes: 1001).
	self assert: ((report at: #'Write-Write') includes: 1002)
]

{ #category : 'tests' }
GbsTransactionConflictReportCoreTest >> testFetchErrorGivesEmptyReport [
	| session |
	session := CoreMockGbsSession new.
	session stubs at: #fetchRemoteCommandBody put: [ :body :lits :oops :ctx | self error: 'boom' ].
	self assert: session transactionConflicts isEmpty
]

{ #category : 'tests' }
GbsTransactionConflictReportCoreTest >> testCommitConflictErrorCarriesConflicts [
	| error |
	error := GbsCommitConflictError new.
	self deny: error hasConflicts.
	self assert: error conflicts isEmpty.
	error conflicts: (Dictionary new at: #'Write-Write' put: #(1001); yourself).
	self assert: error hasConflicts.
	self assert: (error conflictKinds includes: #'Write-Write')
]

{ #category : 'tests' }
GbsTransactionConflictReportCoreTest >> testConflictKindsExcludesEmptySets [
	| error |
	error := GbsCommitConflictError new.
	error conflicts: (Dictionary new
		at: #'Write-Write' put: #(1001);
		at: #'Read-Write' put: #();
		yourself).
	self assert: (error conflictKinds includes: #'Write-Write').
	self deny: (error conflictKinds includes: #'Read-Write')
]
