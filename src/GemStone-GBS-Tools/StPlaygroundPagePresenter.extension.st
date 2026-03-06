Extension { #name : 'StPlaygroundPagePresenter' }

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
			register: (self gsBlockCommandNamed: 'GS-Do it' do: [ GbsPlaygroundActions gsDoItIn: self ]);
			register: (self gsBlockCommandNamed: 'GS-Print it' do: [ GbsPlaygroundActions gsPrintItIn: self ]);
			register: (self gsBlockCommandNamed: 'GS-Inspect it' do: [ GbsPlaygroundActions gsInspectItIn: self ]);
			register: (self gsBlockCommandNamed: 'GS-Debug it' do: [ GbsPlaygroundActions gsDebugItIn: self ]);
			register: (self gsBlockCommandNamed: 'GS-File it in' do: [ GbsPlaygroundActions gsFileItInIn: self ]);
			yourself);
		yourself
]

{ #category : '*GemStone-GBS-Tools-playground' }
StPlaygroundPagePresenter >> gsBlockCommandNamed: aName do: aBlock [
	^ (CmBlockCommand new
		context: self;
		name: aName;
		block: aBlock;
		yourself)
]
