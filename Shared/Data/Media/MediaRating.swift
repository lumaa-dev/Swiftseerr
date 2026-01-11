// Made by Lumaa
#if canImport(DeclaredAgeRange)
import Foundation
import DeclaredAgeRange

struct MediaRating {
    static let mappings: [String: [String: Int]] = [
        "AR": [
            "ATP": 0,
            "+13": 13,
            "+16": 16,
            "+18": 18,
            "C": 18
        ],
        "AU": [
            "G": 0,
            "PG": 0,
            "M": 0,
            "MA 15+": 15,
            "R 18+": 18,
            "X 18+": 18,
            "P": 0,
            "C": 0,
            "AV 15+": 15
        ],
        "BS": [
            "A": 0,
            "B": 18,
            "T": 15,
            "C": 18
        ],
        "BB": [
            "GA": 0,
            "PG": 0,
            "PG-13": 13,
            "R": 18,
            "A": 18
        ],
        "BE": [
            "AL/TOUS": 0
        ],
        "BR": [
            "ER": 0,
            "L": 0,
            "AL": 0,
            "A10": 10,
            "A12": 12,
            "A14": 14,
            "A16": 16,
            "A18": 18
        ],
        "BG": [
            "A": 0,
            "B": 0,
            "C": 12,
            "C+": 14,
            "D+": 16,
            "D": 16,
            "X": 18
        ],
        "KH": [
            "G": 0,
            "NC15": 15,
            "R18": 18
        ],
        "CA": [
            "G": 0,
            "PG": 0,
            "14A": 14,
            "18A": 18,
            "R": 18,
            "C": 0,
            "C8": 8,
            "14+": 14,
            "18+": 18
        ],
        "CL": [
            "TE": 0,
            "F": 0,
            "R": 0,
            "A": 18,
            "I": 0,
            "I7": 7,
            "I10": 10,
            "I12": 12
        ],
        "CO": [
            "T": 0,
            "X": 18,
            "PTA": 0,
            "ADULTOS": 18
        ],
        "CK": [
            "G": 0,
            "PG": 15,
            "MA": 15,
            "R18": 18
        ],
        "CR": [
            "TP": 0,
            "TP7": 7,
            "TP12": 12
        ],
        "DK": [
            "A": 0,
            "F": 0
        ],
        "EE": [
            "PERE": 0,
            "L": 0
        ],
        "FJ": [
            "G": 0,
            "Y": 13,
            "A": 18,
            "R": 18
        ],
        "FI": [
            "S/T": 0,
            "K7": 7,
            "K12": 12,
            "K16": 16,
            "K18": 18
        ],
        "FR": [
            "TP": 0,
            "X": 18,
            "-10": 10,
            "-12": 12,
            "-16": 16,
            "-18": 18
        ],
        "GH": [
            "U": 0,
            "PG": 12
        ],
        "GR": [
            "UNRESTRICTED": 0,
            "K": 0,
            "K8": 8,
            "K12": 12,
            "K16": 16,
            "K18": 18
        ],
        "HK": [
            "I": 0,
            "II A": 8,
            "II B": 13,
            "III": 18,
            "PG": 0,
            "M": 18
        ],
        "HU": [
            "KN": 0,
            "X": 18,
            "GY": 0
        ],
        "IS": [
            "L": 0
        ],
        "IN": [
            "U": 0,
            "UA": 0,
            "UA 7+": 7,
            "UA 13+": 13,
            "UA 16+": 16,
            "A": 18,
            "S": 18
        ],
        "ID": [
            "SU": 0,
            "P": 0,
            "A": 0,
            "R": 13,
            "BO": 0,
            "D": 18,
            "A7+": 7,
            "R13+": 13,
            "D18+": 18
        ],
        "IQ": [
            "G": 0,
            "PG 13": 13,
            "PG 15": 15
        ],
        "IE": [
            "G": 4,
            "PG": 8
        ],
        "IT": [
            "T": 0,
            "BA": 0,
            "VM14": 14,
            "VM18": 18
        ],
        "JM": [
            "G": 0,
            "PG": 0,
            "PG-13": 13,
            "T-16": 16,
            "A-18": 18
        ],
        "JP": [
            "G": 0,
            "PG12": 12,
            "R15+": 15,
            "R18+": 18
        ],
        "KZ": [
            "K": 0,
            "EA": 0,
            "BA6": 6,
            "BA12": 12,
            "BA14": 14,
            "BA16": 16,
            "BA18": 18,
            "NA21": 21
        ],
        "KE": [
            "GE": 0,
            "PG": 10
        ],
        "KW": [
            "G": 0,
            "PG": 0,
            "PG-12": 12,
            "PG-15": 15,
            "R-15": 15,
            "R-18": 18
        ],
        "LV": [
            "U": 0
        ],
        "LB": [
            "G": 0,
            "PG": 0,
            "PG13": 13,
            "PG16": 16,
            "18+": 18
        ],
        "LT": [
            "V": 0,
            "N-7": 7,
            "N-13": 13,
            "N-16": 16,
            "N-18": 18,
            "S": 18
        ],
        "MY": [
            "U": 0,
            "P12": 12,
            "13": 13,
            "16": 16,
            "18": 18
        ],
        "MV": [
            "G": 0,
            "PG": 0,
            "18+R": 18,
            "PU": 0
        ],
        "MT": [
            "U": 0,
            "PG": 0,
            "12A": 12
        ],
        "MU": [
            "U": 0,
            "PG": 12,
            "18R": 18
        ],
        "MX": [
            "AA": 0,
            "A": 0,
            "B": 12,
            "B-15": 15,
            "C": 18,
            "D": 18
        ],
        "NL": [
            "AL": 0
        ],
        "NZ": [
            "G": 0,
            "PG": 0,
            "M": 16,
            "RP13": 13,
            "RP16": 16,
            "RP18": 18,
            "R16": 16,
            "R18": 18
        ],
        "NG": [
            "G": 0,
            "PG": 12,
            "12A": 12,
            "RE": 18
        ],
        "NO": [
            "A": 0
        ],
        "PH": [
            "G": 0,
            "PG": 13,
            "R-13": 13,
            "R-16": 16,
            "R-18": 18,
            "X": 18,
            "SPG": 18
        ],
        "PT": [
            "A": 0,
            "M/18- P": 18,
            "4": 4,
            "6": 6,
            "10": 10,
            "12": 12,
            "16": 16
        ],
        "QA": [
            "G": 0,
            "PG-13": 13,
            "PG-15": 15
        ],
        "RO": [
            "AG": 0,
            "AP-12": 12,
            "N-15": 15,
            "IM-18": 18,
            "IM-18-XXX": 18,
            "AP": 0,
            "12": 12,
            "15": 15,
            "18": 18
        ],
        "SA": [
            "G": 0,
            "PG12": 12,
            "PG15": 15,
            "R18": 18
        ],
        "SG": [
            "G": 0,
            "PG": 13,
            "PG13": 13,
            "NC16": 16,
            "M18": 18,
            "R21": 21
        ],
        "ZA": [
            "A": 0,
            "PG": 7,
            "7–9PG": 7,
            "10–12PG": 10,
            "X18": 18,
            "XX": 18
        ],
        "KR": [
            "ALL": 0
        ],
        "TH": [
            "G": 0,
            "P": 0,
            "C": 0,
            "T": 13,
            "A": 18,
            "13": 13,
            "15": 15,
            "18": 18,
            "20": 20
        ],
        "AE": [
            "G": 0,
            "PG13": 13,
            "PG15": 15,
            "18+": 18,
            "21+": 21
        ],
        "GB": [
            "UC": 0,
            "U": 0,
            "PG": 8,
            "12A": 12,
            "12": 12,
            "R18": 18,
            "15": 15,
            "18": 18
        ],
        "US": [
            "G": 0,
            "PG": 8,
            "PG-13": 13,
            "R": 17,
            "NC-17": 18,
            "TV-Y": 0,
            "TV-Y7": 7,
            "TV-G": 0,
            "TV-PG": 8,
            "TV-14": 14,
            "TV-MA": 17
        ],
        "VE": [
            "A": 0,
            "AA": 0,
            "B": 12,
            "C": 16,
            "D": 18,
            "TODO USUARIO": 0,
            "SUPERVISADO": 0,
            "ADULTO": 18
        ],
        "VN": [
            "P": 0,
            "K": 0,
            "T13": 13,
            "T16": 16,
            "T18": 18
        ]
    ]

    static func find(for media: MediaItem) -> Int? {
        if let normalizedRating = media.rating?.uppercased(), let normalizedCountry = Locale.current.region?.identifier {
            for (key, value) in Self.mappings {
                if key == normalizedCountry {
                    print("[MediaRating] \(normalizedCountry) uses \(normalizedRating) which is \(value[normalizedRating] ?? -1)")
                    return value[normalizedRating]
                }
            }
        } else if var rating = media.rating {
            print("[MediaRating] Using normal rating which is \(rating)")
            rating.replace(/\++/, with: "") // remove all + in "13+" or "+13" for example
            return Int(rating)
        }
        return nil
    }

    static func defineDefault(_ default: Int) {
        let oldDefault: Int = UserDefaults.standard.integer(forKey: "ageCheck")
        if oldDefault < `default` {
            UserDefaults.standard.set(`default`, forKey: "ageCheck")
        }
    }

    static func prepareAsk(for age: Int) -> Bool {
        return UserDefaults.standard.integer(forKey: "ageCheck") < age
    }
}
#endif
