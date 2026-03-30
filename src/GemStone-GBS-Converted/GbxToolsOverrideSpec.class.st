Class {
	#name : 'GbxToolsOverrideSpec',
	#superclass : 'GbxAbstractOverrideSpec',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxToolsOverrideSpec class >> overridesPackageName [
	^ 'GbsToolsOverrides'
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> playgroundExtendedMenuCommandsOverrideSource [
	^ 'extendedMenuCommands

	^ StPlaygroundMenuExtensionCommand allCommands
		reject: [ :each | each name beginsWith: ''GbsPlayground'' ]'
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> playgroundExtendedMenuCommandsSource [
	^ 'extendedMenuCommands

	^ StPlaygroundMenuExtensionCommand allCommands'
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> playgroundMenuActionsOverrideSource [
	^ 'menuActionsFor: aCodePresenter

	^ CmCommandGroup forSpec
		beRoot;
		register: ((CmCommandGroup named: ''Extra'') asSpecGroup
			beDisplayedAsGroup;
			register: (StEvaluateCommand forSpecContext: self);
			yourself);
		register: (aCodePresenter rootCommandsGroup name: ''Code'');
		in: [ :this | self addMenuEditionCommandsTo: this presenter: aCodePresenter ];
		in: [ :this | self addMenuCommandsTo: this ];
		register: ((CmCommandGroup named: ''Playground'') asSpecGroup
			register: ((CmCommandGroup named: ''Base options'') asSpecGroup
				beDisplayedAsGroup;
				in: [ :this | self addToolbarCommandsTo: this ];
				yourself);
			register: ((CmCommandGroup named: ''Miscelaneous options'') asSpecGroup
				beDisplayedAsGroup;
				register: (StShowLineNumbersCommand forSpecContext: self);
				yourself);
			yourself);
		register: ((CmCommandGroup named: ''GemStone'') asSpecGroup
			beDisplayedAsGroup;
			register: (GbsPlaygroundMenuDoItCommand forSpecContext: self);
			register: (GbsPlaygroundMenuPrintItCommand forSpecContext: self);
			register: (GbsPlaygroundMenuInspectItCommand forSpecContext: self);
			register: (GbsPlaygroundMenuDebugItCommand forSpecContext: self);
			register: (GbsPlaygroundMenuFileItInCommand forSpecContext: self);
			yourself);
		yourself'
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> playgroundMenuActionsSource [
	^ 'menuActionsFor: aCodePresenter

	^ CmCommandGroup forSpec
		beRoot;
		register: ((CmCommandGroup named: ''Extra'') asSpecGroup
			beDisplayedAsGroup;
			register: (StEvaluateCommand forSpecContext: self);
			yourself);
		register: (aCodePresenter rootCommandsGroup name: ''Code'');
		in: [ :this | self addMenuEditionCommandsTo: this presenter: aCodePresenter ];
		in: [ :this | self addMenuCommandsTo: this ];
		register: ((CmCommandGroup named: ''Playground'') asSpecGroup
			register: ((CmCommandGroup named: ''Base options'') asSpecGroup
				beDisplayedAsGroup;
				in: [ :this | self addToolbarCommandsTo: this ];
				yourself);
			register: ((CmCommandGroup named: ''Miscelaneous options'') asSpecGroup
				beDisplayedAsGroup;
				register: (StShowLineNumbersCommand forSpecContext: self);
				yourself);
			yourself);
		yourself'
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> spec832 [
	<version: '8.3.2'>
	^ self spec93
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> spec911 [
	<version: '9.1.1'>
	^ self spec93
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> spec921 [
	<version: '9.2.1'>
	^ self spec93
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> spec93 [
	<version: '9.3'>
	^ GbxOverrideSet
		destinationPackageName: self overridesPackageName
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: (OrderedCollection new
				add: (GbxMethodOverride
							behavior: StPlaygroundPagePresenter
							selector: #menuActionsFor:
							from: self playgroundMenuActionsSource
							to: self playgroundMenuActionsOverrideSource);
				add: (GbxMethodOverride
							behavior: StPlaygroundPagePresenter class
							selector: #extendedMenuCommands
							from: self playgroundExtendedMenuCommandsSource
							to: self playgroundExtendedMenuCommandsOverrideSource);
				yourself)
]
