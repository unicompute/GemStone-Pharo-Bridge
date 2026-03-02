Class {
	#name : 'GbsSessionManagerTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsSessionManagerTest >> testDateAndTimeSerialization [

  | pharoDate serializedArray |
  "1. Setup: Create a specific DateAndTime in Pharo""Feb 20, 2026 at 13:42:46 with 0 offset"
  pharoDate := DateAndTime
                 year: 2026
                 month: 2
                 day: 20
                 hour: 13
                 minute: 42
                 second: 46
                 offset: 0 hours.

  "2. Execute: Convert it to the bridge format (This will fail MNU)"
  serializedArray := pharoDate asGemStonePrimitiveArray.

  "3. Assertions: Check that it decomposed into a standard Array"
  self assert: ( serializedArray isKindOf: Array ).
  self assert: serializedArray size equals: 7.

  "4. Assertions: Verify the exact data layout expected by the server"
  self assert: ( serializedArray at: 1 ) equals: 2026. "Year"
  self assert: ( serializedArray at: 2 ) equals: 2. "Month"
  self assert: ( serializedArray at: 3 ) equals: 20. "Day"
  self assert: ( serializedArray at: 4 ) equals: 13. "Hour"
  self assert: ( serializedArray at: 5 ) equals: 42. "Minute"
  self assert: ( serializedArray at: 6 ) equals: 46. "Second"
  self assert: ( serializedArray at: 7 ) equals: 0 "Offset in seconds"
]

{ #category : 'tests' }
GbsSessionManagerTest >> testFastConnectorRegistryMapping [
    | sessionManager registry |
    
    "1. Setup"
    sessionManager := GbsSessionManager new.
    sessionManager initializeFastConnectors.
    
    "2. Fetch the registry (This will initially fail because it doesn't exist)"
    registry := sessionManager fastConnectorRegistry.
    
    "3. Assertions: Verify registry exists"
    self assert: registry isNotNil.
    self assert: (registry isKindOf: Dictionary).
    
    "4. Assertions: Verify Client -> Server mapping"
    self assert: (registry at: #ByteString) equals: #String.
    self assert: (registry at: #Array) equals: #Array.
    self assert: (registry at: #DateAndTime) equals: #DateTime.
    
    "5. Assertions: Verify Server -> Client mapping"
    self assert: (registry at: #String) equals: #ByteString.
    self assert: (registry at: #DateTime) equals: #DateAndTime.
]

{ #category : 'tests' }
GbsSessionManagerTest >> testWideStringSerialization [
    | pharoWideString serializedBytes |
    
    "1. Setup: Create a WideString (an emoji forces Pharo to use WideString)"
    pharoWideString := 'Hello 🌍'.
    
    "2. Execute: Convert it to the bridge format (This will fail MNU)"
    serializedBytes := pharoWideString asGemStoneUTF8Bytes.
    
    "3. Assertions: Check that it decomposed into a standard ByteArray"
    self assert: (pharoWideString isKindOf: WideString).
    self assert: (serializedBytes isKindOf: ByteArray).
    
    "4. Assertions: Verify the exact UTF-8 byte layout expected by the server"
    "The word 'Hello ' is 6 bytes. The '🌍' emoji is 4 bytes in UTF-8: 240 159 140 141"
    self assert: serializedBytes size equals: 10.
    self assert: (serializedBytes copyFrom: 7 to: 10) asArray equals: #(240 159 140 141).
]
