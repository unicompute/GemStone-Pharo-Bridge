Class {
	#name : 'GbxServerMapToolTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbxServerMapToolTest >> testAuditReportsDuplicateOopsDuplicateNamesAndInvalidNodes [
	| tool first second invalid audit |
	tool := GbxServerMapTool new.
	first := Dictionary new
		at: #name put: 'alpha';
		at: #oop put: 10;
		yourself.
	second := Dictionary new
		at: #name put: 'alpha';
		at: #oop put: 10;
		yourself.
	invalid := Dictionary new
		at: #name put: '';
		at: #oop put: 0;
		yourself.

	tool instVarNamed: 'nodes' put: (Dictionary new
		at: #first put: first;
		at: #second put: second;
		at: #invalid put: invalid;
		yourself).
	tool segments: (OrderedCollection with: first with: second with: invalid).
	tool rootNode: first.

	audit := tool audit.

	self assert: (audit at: #nodeCount) equals: 3.
	self assert: (audit at: #segmentCount) equals: 3.
	self assert: (audit at: #issueCount) equals: 4.
	self assert: (audit at: #rootNode) equals: 'alpha'.
	self assert: (audit at: #status) equals: 'issues found'.
	self assert: (audit at: #duplicateNames) asArray equals: #('alpha').
	self assert: (audit at: #missingNames) size equals: 1.
	self assert: (audit at: #invalidOops) size equals: 1.
	self assert: ((audit at: #duplicateOops) first at: #oop) equals: 10
]

{ #category : 'tests' }
GbxServerMapToolTest >> testBuildFromServerReplacesStaleState [
	| session tool stale |
	session := MockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script |
		'beta|30', String lf, 'alpha|10', String lf ].

	tool := GbxServerMapTool on: session.
	stale := Dictionary new
		at: #name put: 'stale';
		at: #oop put: 999;
		yourself.
	tool instVarNamed: 'nodes' put: (Dictionary new at: 'stale' put: stale; yourself).
	tool segments: (OrderedCollection with: stale).
	tool rootNode: stale.

	tool buildFromServer.

	self deny: (tool nodes includesKey: 'stale').
	self assert: tool nodes size equals: 2.
	self assert: (tool rootNode at: #name) equals: 'alpha'.
	self assert: (tool segments collect: [ :each | each at: #oop ]) asArray equals: #(10 30)
]

{ #category : 'tests' }
GbxServerMapToolTest >> testParseSegmentsSortsByOopAndSetsRootNode [
	| tool |
	tool := GbxServerMapTool new.

	tool parseSegments: 'beta|30', String lf, 'alpha|10', String lf, 'gamma|20', String lf.

	self assert: tool nodes size equals: 3.
	self assert: (tool rootNode at: #name) equals: 'alpha'.
	self assert: (tool segments collect: [ :each | each at: #oop ]) asArray equals: #(10 20 30)
]
