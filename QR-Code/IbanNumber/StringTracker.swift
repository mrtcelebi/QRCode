//
//  StringUtils.swift
//  QR-Code
//
//  Created by Murat Celebi on 10.05.2021.
//

import Foundation

class StringTracker {
    var frameIndex: Int64 = 0

    typealias StringObservation = (lastSeen: Int64, count: Int64)
    
    var seenStrings = [String: StringObservation]()
    var bestCount = Int64(0)
    var bestString = ""

    func logFrame(strings: [String]) {
        for string in strings {
            if seenStrings[string] == nil {
                seenStrings[string] = (lastSeen: Int64(0), count: Int64(-1))
            }
            seenStrings[string]?.lastSeen = frameIndex
            seenStrings[string]?.count += 1
            print("Seen \(string) \(seenStrings[string]?.count ?? 0) times")
        }
    
        var obsoleteStrings = [String]()

        // Go through strings and prune any that have not been seen in while.
        // Also find the (non-pruned) string with the greatest count.
        for (string, obs) in seenStrings {
            // Remove previously seen text after 30 frames (~1s).
            if obs.lastSeen < frameIndex - 30 {
                obsoleteStrings.append(string)
            }
            
            // Find the string with the greatest count.
            let count = obs.count
            if !obsoleteStrings.contains(string) && count > bestCount {
                bestCount = Int64(count)
                bestString = string
            }
        }
        // Remove old strings.
        for string in obsoleteStrings {
            seenStrings.removeValue(forKey: string)
        }
        
        frameIndex += 1
    }
    
    func getStableString() -> String? {
        // Require the recognizer to see the same string at least 10 times.
        if bestCount >= 10 {
            return bestString
        } else {
            return nil
        }
    }
    
    func reset(string: String) {
        seenStrings.removeValue(forKey: string)
        bestCount = 0
        bestString = ""
    }
}

// MARK: - Character Extension
extension Character {
    
	func getSimilarCharacterIfNotIn(allowedChars: String) -> Character {
		let conversionTable = [
			"s": "S",
			"S": "5",
			"5": "S",
			"o": "O",
			"Q": "O",
			"O": "0",
			"0": "O",
			"l": "I",
			"I": "1",
			"1": "I",
			"B": "8",
			"8": "B"
		]
		// Allow a maximum of two substitutions to handle 's' -> 'S' -> '5'.
		let maxSubstitutions = 2
		var current = String(self)
		var counter = 0
		while !allowedChars.contains(current) && counter < maxSubstitutions {
			if let altChar = conversionTable[current] {
				current = altChar
				counter += 1
			} else {
				// Doesn't match anything in our table. Give up.
				break
			}
		}
		
		return current.first!
	}
}

// MARK: - String Extension
extension String {
    
    var pattern: String {
            #"""
            (?x)                    # Verbose regex, allows comments
            \b(?:\TR?)?             # Potential international prefix, may have -
            (\w{2})                 # Capture xx
            [\ -./]?                # Potential separator
            (\w{4})                 # Capture xxxx
            [\ -./]?                # Potential separator
            (\w{4})                 # Capture xxxx
            [\ -./]?                # Potential separator
            (\w{4})                 # Capture xxxx
            [\ -./]?                # Potential separator
            (\w{4})                 # Capture xxxx
            [\ -./]?                # Potential separator
            (\w{4})                 # Capture xxxx
            [\ -./]?                # Potential separator
            (\w{2})\b               # Capture xx
            """#
    }
    
	func extractIbanNumber() -> (Range<String.Index>, String)? {
        
		guard let range = self.range(of: pattern, options: .regularExpression, range: nil, locale: nil) else {
			// No phone number found.
			return nil
		}
		
		// Potential number found. Strip out punctuation, whitespace and country
		// prefix.
		var ibanNumberDigits = ""
		let substring = String(self[range])
		let nsrange = NSRange(substring.startIndex..., in: substring)
		do {
			// Extract the characters from the substring.
			let regex = try NSRegularExpression(pattern: pattern, options: [])
			if let match = regex.firstMatch(in: substring, options: [], range: nsrange) {
				for rangeInd in 1 ..< match.numberOfRanges {
					let range = match.range(at: rangeInd)
					let matchString = (substring as NSString).substring(with: range)
					ibanNumberDigits += matchString as String
				}
			}
		} catch {
			print("Error \(error) when creating pattern")
		}
		
		// Must be exactly 24 digits.
		guard ibanNumberDigits.count == 24 else {
			return nil
		}
		
		var result = ""
		let allowedChars = "0123456789"
		for var char in ibanNumberDigits {
			char = char.getSimilarCharacterIfNotIn(allowedChars: allowedChars)
			guard allowedChars.contains(char) else {
				return nil
			}
			result.append(char)
		}
		return (range, result)
	}
    
    // Validate IbanNumber
    func isValidIbanNumber() -> Bool {
        
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
    }
}
