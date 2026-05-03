Class {
	#name : 'GbsStructuredValueInspectorPresenterMagLevToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'tests' }
GbsStructuredValueInspectorPresenterMagLevToolsTest >> testBrowseRubyLoadPathReportUsesConfiguredBlock [
	| presenter informed |
	presenter := GbsStructuredValueInspectorPresenter new.
	presenter
		propertyAt: #loadPathReportBlock put: [ '$LOAD_PATH', String cr, String cr, 'lib' ];
		propertyAt: #informBlock put: [ :message | informed := message ].

	presenter browseRubyLoadPathReport.

	self assert: informed equals: '$LOAD_PATH', String cr, String cr, 'lib'
]
