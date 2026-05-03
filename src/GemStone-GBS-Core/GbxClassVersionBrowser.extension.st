Extension { #name : 'GbxClassVersionBrowser' }

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> classHistory [
	^ classHistory
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> classHistory: aClassHistoryFacade [
	classHistory := aClassHistoryFacade
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> canMigrateInstances [
	^ classHistory notNil and: [ classHistory canMigrateInstances ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> getClassList [
	classHistory ifNil: [ ^ #() ].
	^ classHistory holders
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> impactSummaryForPlan: aMigrationPlan [
	aMigrationPlan ifNil: [ ^ '0 instances across 0 classes' ].
	^ aMigrationPlan impactSummaryString
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> latestHolder [
	classHistory ifNil: [ ^ nil ].
	^ classHistory latestHolder
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> makeCurrentIn: aDictionaryOrName [
	classHistory ifNil: [ ^ nil ].
	^ classHistory makeCurrentIn: aDictionaryOrName
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> oldVersionHolders [
	classHistory ifNil: [ ^ #() ].
	^ classHistory oldVersionHolders
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> previewMigrationTo: aClassOrHolder allowAbort: aBoolean [
	classHistory ifNil: [ ^ GbsMigrationPlan new ].
	^ classHistory previewMigrationTo: aClassOrHolder allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> previewMigrationToLatestAllowAbort: aBoolean [
	| latest |
	latest := self latestHolder.
	latest ifNil: [ ^ GbsMigrationPlan new ].
	^ self previewMigrationTo: latest allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> previewOldVersionsToLatestAllowAbort: aBoolean [
	classHistory ifNil: [ ^ GbsMigrationPlan new ].
	^ classHistory previewOldVersionsToLatestAllowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> removeOldVersionBindingsFrom: aDictionaryOrName [
	classHistory ifNil: [ ^ #() ].
	^ classHistory removeOldVersionBindingsFrom: aDictionaryOrName
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> selectedHolder [
	classHistory ifNil: [ ^ nil ].
	^ classHistory selectedHolder
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> migrateInstancesTo: aClassOrHolder allowAbort: aBoolean [
	classHistory ifNil: [ ^ 0 ].
	^ classHistory migrateInstancesTo: aClassOrHolder allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbxClassVersionBrowser >> executePreviewPlan: aMigrationPlan allowAbort: aBoolean [
	classHistory ifNil: [ ^ 0 ].
	^ classHistory executePreviewPlan: aMigrationPlan allowAbort: aBoolean
]
