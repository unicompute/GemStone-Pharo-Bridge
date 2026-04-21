| source |

source := [ '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/micro_bootstrap_reload.st' asFileReference contents ]
	on: Error
	do: [ :ex |
		Transcript show: 'LOAD_ERROR: ', ex messageText; cr.
		nil ].

source ifNotNil: [ Smalltalk compiler evaluate: source ].
Smalltalk snapshot: true andQuit: true.
