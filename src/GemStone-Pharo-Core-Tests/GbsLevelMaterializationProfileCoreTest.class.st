"
Headless tests for GbsLevelMaterializationProfile depth gating -- the fault-level / faultLevelRpc depth
transition logic. A level profile materializes referents only while the current traversal depth is below
maxLevel, so faultToLevel: 1 vs 2 vs 3 produces different materialization depths.
"
Class {
	#name : 'GbsLevelMaterializationProfileCoreTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsLevelMaterializationProfileCoreTest >> testMaxLevelDefaultsToOneAndFloorsAtOne [
	self assert: GbsLevelMaterializationProfile new maxLevel equals: 1.
	self assert: (GbsLevelMaterializationProfile maxLevel: nil) maxLevel equals: 1.
	self assert: (GbsLevelMaterializationProfile maxLevel: 0) maxLevel equals: 1.
	self assert: (GbsLevelMaterializationProfile maxLevel: 5) maxLevel equals: 5
]

{ #category : 'tests' }
GbsLevelMaterializationProfileCoreTest >> testLevelOneAdmitsDepthZeroOnly [
	"maxLevel 1: referents are admitted only while traversal depth < 1, i.e. at depth 0. Since the root's
	direct elements are checked at the root's depth (0), at toLevel: 1 the root and its direct children
	materialize while grandchildren (checked at depth 1) stay proxies."
	| profile |
	profile := GbsLevelMaterializationProfile maxLevel: 1.
	self assert: (profile shouldMaterializeCollectionClassNamed: 'Array' depth: 0).
	self deny: (profile shouldMaterializeCollectionClassNamed: 'Array' depth: 1).
	self deny: (profile shouldMaterializeCollectionClassNamed: 'Array' depth: 2)
]

{ #category : 'tests' }
GbsLevelMaterializationProfileCoreTest >> testLevelTwoAdmitsOneMoreDepth [
	"maxLevel 2 admits referents at depth 0 and 1, one depth deeper than maxLevel 1."
	| profile |
	profile := GbsLevelMaterializationProfile maxLevel: 2.
	self assert: (profile shouldMaterializeCollectionClassNamed: 'OrderedCollection' depth: 0).
	self assert: (profile shouldMaterializeCollectionClassNamed: 'OrderedCollection' depth: 1).
	self deny: (profile shouldMaterializeCollectionClassNamed: 'OrderedCollection' depth: 2).
	self deny: (profile shouldMaterializeCollectionClassNamed: 'OrderedCollection' depth: 3)
]

{ #category : 'tests' }
GbsLevelMaterializationProfileCoreTest >> testDeeperLevelMaterializesMoreDepth [
	"Each higher fault level admits one more depth of referents -- the core fault-level transition."
	| level3 |
	level3 := GbsLevelMaterializationProfile maxLevel: 3.
	self assert: (level3 shouldMaterializeCollectionClassNamed: 'Set' depth: 2).
	self deny: (level3 shouldMaterializeCollectionClassNamed: 'Set' depth: 3).
	"And the boundary moves with maxLevel:"
	self assert: ((GbsLevelMaterializationProfile maxLevel: 4) shouldMaterializeCollectionClassNamed: 'Set' depth: 3)
]

{ #category : 'tests' }
GbsLevelMaterializationProfileCoreTest >> testUnknownCollectionNotMaterializedEvenWithinLevel [
	"The level gate only admits depth; the underlying deep profile still restricts to known collection
	classes, so an unknown class is not materialized even at depth 0 within maxLevel."
	| profile |
	profile := GbsLevelMaterializationProfile maxLevel: 3.
	self deny: (profile shouldMaterializeCollectionClassNamed: 'SomeDomainClass' depth: 0)
]
