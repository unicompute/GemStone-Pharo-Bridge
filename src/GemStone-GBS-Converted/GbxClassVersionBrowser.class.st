Class {
	#name : 'GbxClassVersionBrowser',
	#superclass : 'GbxBrowser',
	#instVars : [
		'classHistory'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxClassVersionBrowser >> classHistory [
	^ classHistory
]

{ #category : 'accessing' }
GbxClassVersionBrowser >> classHistory: aClassHistoryFacade [
	classHistory := aClassHistoryFacade
]

{ #category : 'testing' }
GbxClassVersionBrowser >> canMigrateInstances [
	^ classHistory notNil and: [ classHistory canMigrateInstances ]
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> getClassList [
	classHistory ifNil: [ ^ #() ].
	^ classHistory holders
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> impactSummaryForPlan: aMigrationPlan [
	aMigrationPlan ifNil: [ ^ '0 instances across 0 classes' ].
	^ aMigrationPlan impactSummaryString
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> latestHolder [
	classHistory ifNil: [ ^ nil ].
	^ classHistory latestHolder
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> makeCurrentIn: aDictionaryOrName [
	classHistory ifNil: [ ^ nil ].
	^ classHistory makeCurrentIn: aDictionaryOrName
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> oldVersionHolders [
	classHistory ifNil: [ ^ #() ].
	^ classHistory oldVersionHolders
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> previewMigrationTo: aClassOrHolder allowAbort: aBoolean [
	classHistory ifNil: [ ^ GbsMigrationPlan new ].
	^ classHistory previewMigrationTo: aClassOrHolder allowAbort: aBoolean
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> previewMigrationToLatestAllowAbort: aBoolean [
	| latest |
	latest := self latestHolder.
	latest ifNil: [ ^ GbsMigrationPlan new ].
	^ self previewMigrationTo: latest allowAbort: aBoolean
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> previewOldVersionsToLatestAllowAbort: aBoolean [
	classHistory ifNil: [ ^ GbsMigrationPlan new ].
	^ classHistory previewOldVersionsToLatestAllowAbort: aBoolean
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> removeOldVersionBindingsFrom: aDictionaryOrName [
	classHistory ifNil: [ ^ #() ].
	^ classHistory removeOldVersionBindingsFrom: aDictionaryOrName
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> selectedHolder [
	classHistory ifNil: [ ^ nil ].
	^ classHistory selectedHolder
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> migrateInstancesTo: aClassOrHolder allowAbort: aBoolean [
	classHistory ifNil: [ ^ 0 ].
	^ classHistory migrateInstancesTo: aClassOrHolder allowAbort: aBoolean
]

{ #category : 'private-class functions' }
GbxClassVersionBrowser >> executePreviewPlan: aMigrationPlan allowAbort: aBoolean [
	classHistory ifNil: [ ^ 0 ].
	^ classHistory executePreviewPlan: aMigrationPlan allowAbort: aBoolean
]
