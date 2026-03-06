Extension { #name : 'StPlaygroundPagePresenter' }

{ #category : '*GemStone-GBS-Tools-playground' }
StPlaygroundPagePresenter class >> extendedMenuCommands [

	^ StPlaygroundMenuExtensionCommand allCommands
		reject: [ :each | each name beginsWith: 'GbsPlayground' ]
]

{ #category : '*GemStone-GBS-Tools-playground' }
StPlaygroundPagePresenter >> menuActionsFor: aCodePresenter [

	^ CmCommandGroup forSpec
		beRoot;
		register: ((CmCommandGroup named: 'Extra') asSpecGroup
			beDisplayedAsGroup;
			register: (StEvaluateCommand forSpecContext: self);
			yourself);
		register: (aCodePresenter rootCommandsGroup name: 'Code');
		in: [ :this | self addMenuEditionCommandsTo: this presenter: aCodePresenter ];
		in: [ :this | self addMenuCommandsTo: this ];
		register: ((CmCommandGroup named: 'Playground') asSpecGroup
			register: ((CmCommandGroup named: 'Base options') asSpecGroup
				beDisplayedAsGroup;
				in: [ :this | self addToolbarCommandsTo: this ];
				yourself);
			register: ((CmCommandGroup named: 'Miscelaneous options') asSpecGroup
				beDisplayedAsGroup;
				register: (StShowLineNumbersCommand forSpecContext: self);
				yourself);
			yourself);
		register: ((CmCommandGroup named: 'GemStone') asSpecGroup
			beDisplayedAsGroup;
			register: (GbsPlaygroundMenuDoItCommand forSpecContext: self);
			register: (GbsPlaygroundMenuPrintItCommand forSpecContext: self);
			register: (GbsPlaygroundMenuInspectItCommand forSpecContext: self);
			register: (GbsPlaygroundMenuDebugItCommand forSpecContext: self);
			register: (GbsPlaygroundMenuFileItInCommand forSpecContext: self);
			yourself);
		yourself
]
