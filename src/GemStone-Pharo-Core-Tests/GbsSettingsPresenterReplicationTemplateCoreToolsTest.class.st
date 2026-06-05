"
Headless tests for the replication-policy template picker and diff view added to GbsSettingsPresenter.
Exercise the logic methods (template application, policy-from-controls, diff text) without opening a window.
"
Class {
	#name : 'GbsSettingsPresenterReplicationTemplateCoreToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsSettingsPresenterReplicationTemplateCoreToolsTest >> testTemplateNamesIncludeBuiltInTemplates [
	| presenter names |
	presenter := GbsSettingsPresenter new.
	names := presenter replicationTemplateNames.
	self assert: (names includes: 'default').
	self assert: (names includes: 'production').
	self assert: (names includes: 'migration').
	self assert: (names includes: 'debug')
]

{ #category : 'tests' }
GbsSettingsPresenterReplicationTemplateCoreToolsTest >> testApplyMigrationTemplateUpdatesReplicationControls [
	| presenter policy |
	presenter := GbsSettingsPresenter new.
	presenter applyReplicationTemplateNamed: #migration.

	policy := presenter currentReplicationPolicyFromPresenters.
	self assert: policy storeTraversalTransport equals: 'binaryRequired'.
	self assert: policy storeDirtyOnCommit.
	self assert: policy defaultFaultPolicy equals: 'lazy'.
	self assert: policy blockReplicationPolicy equals: 'replicate'.
	self assert: policy freeOopAllocationBatchSize equals: 2000
]

{ #category : 'tests' }
GbsSettingsPresenterReplicationTemplateCoreToolsTest >> testApplyProductionTemplateUpdatesReplicationControls [
	| presenter policy |
	presenter := GbsSettingsPresenter new.
	presenter applyReplicationTemplateNamed: #production.

	policy := presenter currentReplicationPolicyFromPresenters.
	self assert: policy storeTraversalTransport equals: 'binary'.
	self assert: policy storeDirtyOnCommit.
	self assert: policy asyncSignalPollingEnabled.
	self assert: policy serverMapMode equals: 'weak'
]

{ #category : 'tests' }
GbsSettingsPresenterReplicationTemplateCoreToolsTest >> testReplicationDiffTextReportsTemplateChanges [
	| presenter diff |
	presenter := GbsSettingsPresenter new.
	presenter applyReplicationTemplateNamed: #migration.

	diff := presenter replicationDiffText.
	self assert: (diff isKindOf: String).
	self assert: (diff includesSubstring: 'storeTraversalTransport').
	self assert: (diff includesSubstring: 'binaryRequired')
]

{ #category : 'tests' }
GbsSettingsPresenterReplicationTemplateCoreToolsTest >> testApplyTemplateWithNilNameIsNoOp [
	| presenter |
	presenter := GbsSettingsPresenter new.
	self assert: (presenter applyReplicationTemplateNamed: nil) isNil
]
