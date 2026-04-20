Class {
	#name : 'GciStandaloneTest',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GciStandaloneTest class >> runPrintTest [

  | init login stringOop size cBuffer fetched resultString aGciStandaloneTest |
  "1. Initialize & Login (Just like C)"
  aGciStandaloneTest := self new.
  init := aGciStandaloneTest gciInit.
  login := aGciStandaloneTest gciLogin: 'DataCurator' pass: 'swordfish'.

  "2. Execute Test B exactly"
  stringOop := aGciStandaloneTest gciExecute: '( 1 + 1 ) printString' context: 20 env: 0.

  stringOop = 20 ifTrue: [
      aGciStandaloneTest gciLogout.
      ^ 'Error: GemStone returned OOP 20 (nil)'
      ].
  stringOop = 1 ifTrue: [
      aGciStandaloneTest gciLogout.
      ^ 'Error: GemStone Compile Error'
      ].

  "3. Fetch Size & Allocate C-buffer (Just like C malloc)"
  size := aGciStandaloneTest gciFetchSize: stringOop.
  cBuffer := ExternalAddress allocate: size + 1.

  "4. Fetch Bytes & Null Terminate"
  fetched := aGciStandaloneTest
               gciFetchBytes: stringOop
               startingAt: 1
               into: cBuffer
               size: size.
  cBuffer unsignedByteAt: size + 1 put: 0.

  resultString := cBuffer readString.
  cBuffer free.

  "5. Cleanup"
  aGciStandaloneTest gciLogout.

  ^ 'FINAL PRINT RESULT: "' , resultString , '"'
]

{ #category : 'running' }
GciStandaloneTest class >> runTest [

  | init login result aGciStandaloneTest |
  "1. Initialize"
  aGciStandaloneTest := self new.
  init := aGciStandaloneTest gciInit.
  init ifFalse: [ ^ 'Init failed' ].

  "2. Login"
  login := aGciStandaloneTest gciLogin: 'DataCurator' pass: 'swordfish'.
  login ifFalse: [ ^ 'Login failed' ].

  "3. Execute '1+1'"
  result := aGciStandaloneTest gciExecute: '1+1' context: 20 env: 0.

  "4. Clean up"
  aGciStandaloneTest gciLogout.

  ^ 'Success! Result OOP: ' , result asString
]

{ #category : 'ffi' }
GciStandaloneTest >> ffiLibraryName [
    "Point directly to your legacy C-library"
    ^ '/Users/tariq/GemStone64Bit3.7.4.3-arm64.Darwin/lib/libgcirpc-3.7.4.3-64.dylib'
]

{ #category : 'ffi' }
GciStandaloneTest >> gciExecute: string context: ctx env: env [
    "String correctly maps to const char*, and we stay on the main thread"
    ^ self ffiCall: #(uint64 GciExecuteStr_(String string, uint64 ctx, ushort env)) options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GciStandaloneTest >> gciFetchBytes: anOop startingAt: startIndex into: aBuffer size: maxSize [
    ^ self ffiCall: #(int64 GciFetchBytes_(int64 anOop, int64 startIndex, void* aBuffer, int64 maxSize)) 
           options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GciStandaloneTest >> gciFetchSize: anOop [
    ^ self ffiCall: #(int64 GciFetchSize_(int64 anOop)) options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GciStandaloneTest >> gciInit [
    "optNonThreaded FORCES the call onto the main VM thread"
    ^ self ffiCall: #(bool GciInit()) options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GciStandaloneTest >> gciLogin: user pass: pass [
    "optNonThreaded ensures Login happens on the EXACT same thread as Init"
    ^ self ffiCall: #(bool GciLogin(String user, String pass)) options: #( + optNonThreaded )
]

{ #category : 'accessing' }
GciStandaloneTest >> gciLogout [
    ^ self ffiCall: #(void GciLogout()) options: #( + optNonThreaded )
]

{ #category : 'running' }
GciStandaloneTest >> runPrintTest [
	^ self class runPrintTest
]

{ #category : 'running' }
GciStandaloneTest >> runTest [
	^ self class runTest
]
