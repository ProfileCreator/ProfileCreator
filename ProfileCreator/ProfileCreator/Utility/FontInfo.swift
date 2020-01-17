//
//  FontInfo.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

struct FontInformation {

    var descriptions = [FontDescription]()
    let format: CTFontFormat
    let formatString: String
    var uti: CFString {
        switch self.format {
        case .openTypeTrueType,
             .openTypePostScript:
            return "public.opentype-font" as CFString
        case .trueType:
            return "public.truetype-font" as CFString
        default:
            return kUTTypeFont
        }
    }

    func descriptions(forLanguage language: FontTableName.LanguageID) -> [FontDescription] {
        return self.descriptions.filter { $0.language == language }
    }

    func descriptions(forLanguage language: FontTableName.LanguageID, platform: FontTableName.PlatformIdentifier) -> [FontDescription] {
        return self.descriptions.filter { $0.platformIdentifier == platform && $0.language == language }
    }

    init?(data: Data) throws {

        guard let fontDataProvider = CGDataProvider(data: data as CFData) else { return nil }
        guard let font = CGFont(fontDataProvider) else { return nil }
        guard let fontTable = font.table(for: UInt32(kCTFontTableName)) as Data? else { return nil }

        let ctFont = CTFontCreateWithGraphicsFont(font, 0.0, nil, nil)
        let ctFontDescriptor = CTFontCopyFontDescriptor(ctFont)

        if
            let ctFontFormatRaw = CTFontDescriptorCopyAttribute(ctFontDescriptor, kCTFontFormatAttribute) as? UInt32,
            let ctFontFormat = CTFontFormat(rawValue: ctFontFormatRaw) {

            self.format = ctFontFormat

            switch ctFontFormat {
            case .trueType:
                self.formatString = "TrueType"
            case .openTypeTrueType:
                self.formatString = "OpenType containing TrueType data"
            case .openTypePostScript:
                self.formatString = "OpenType containing PostScript data"
            case .postScript:
                self.formatString = "PostScript"
            case .bitmap:
                self.formatString = "Bitmap"
            case .unrecognized:
                self.formatString = NSLocalizedString("Unknown", comment: "")
            }
        } else {
            self.format = .unrecognized
            self.formatString = NSLocalizedString("Unknown", comment: "")
        }

        var loc: CFIndex = 0

        // Format
        let format = fontTable.fontTableNameValue(atOffset: loc)
        loc += MemoryLayout.size(ofValue: format)

        // Count
        let count = fontTable.fontTableNameValue(atOffset: loc)
        loc += MemoryLayout.size(ofValue: count)

        // StringOffset
        let stringOffset = fontTable.fontTableNameValue(atOffset: loc)
        loc += MemoryLayout.size(ofValue: stringOffset)

        for _ in 0..<count {

            // PlatformID
            let platformIDRaw = fontTable.fontTableNameValue(atOffset: loc)
            loc += MemoryLayout.size(ofValue: platformIDRaw)

            // PlatformSpecificID
            let platformSpecificIDRaw = fontTable.fontTableNameValue(atOffset: loc)
            loc += MemoryLayout.size(ofValue: platformSpecificIDRaw)

            // LanguageID
            let languageIDRaw = fontTable.fontTableNameValue(atOffset: loc)
            loc += MemoryLayout.size(ofValue: languageIDRaw)

            // NameID
            let nameIDRaw = fontTable.fontTableNameValue(atOffset: loc)
            loc += MemoryLayout.size(ofValue: nameIDRaw)

            // Length
            let length = fontTable.fontTableNameValue(atOffset: loc)
            loc += MemoryLayout.size(ofValue: length)

            // Offset
            let offset = fontTable.fontTableNameValue(atOffset: loc)
            loc += MemoryLayout.size(ofValue: offset)

            // String
            let encoding: String.Encoding
            if platformIDRaw == 0 || 3 <= platformSpecificIDRaw {
                encoding = .utf16
            } else {
                encoding = .utf8
            }

            guard let string = fontTable.fontTableString(atOffset: (Int(offset + stringOffset)), length: Int(length), encoding: encoding) else {
                //Log.shared.debug(message: "Failed to get string for platformID: \(platformIDRaw), platfomrSpecificID: \(platformSpecificIDRaw), languageID: \(languageIDRaw), nameID: \(nameIDRaw)", category: String(describing: self))
                continue
            }

            guard let platformIdentifier = FontTableName.PlatformIdentifier(rawValue: platformIDRaw) else {
                //Log.shared.debug(message: "Failed to get platformIdentifier from platformIDRaw: \(platformIDRaw)", category: String(describing: self))
                //Log.shared.debug(message: "platformIdentifierString: \(string)", category: String(describing: self))
                continue
            }

            guard let language = FontTableName.LanguageID(rawValue: languageIDRaw) else {
                //Log.shared.debug(message: "Failed to get language from languageIDRaw: \(languageIDRaw)", category: String(describing: self))
                //Log.shared.debug(message: "languageString: \(string)", category: String(describing: self))
                continue
            }

            guard let nameID = FontTableName.NameID(rawValue: nameIDRaw) else {
                //Log.shared.debug(message: "Failed to get nameID from nameIDRaw: \(nameIDRaw)", category: String(describing: self))
                //Log.shared.debug(message: "nameIDString: \(string)", category: String(describing: self))
                continue
            }

            var fontDescriptionIndex: Int?
            var fontDescription: FontDescription
            if let index = self.descriptions.index(where: { $0.platformIdentifier == platformIdentifier && $0.platformSpecificID == platformSpecificIDRaw && $0.language == language }) {
                fontDescriptionIndex = index
                fontDescription = self.descriptions[index]
            } else {
                fontDescription = FontDescription(platformIdentifier: platformIdentifier, platformSpecificID: platformSpecificIDRaw, language: language)
            }

            switch nameID {
            case .copyright:
                fontDescription.copyright = string
            case .family:
                fontDescription.family = string
            case .subfamily:
                fontDescription.subfamily = string
            case .uniqueSubfamilyIdentification:
                fontDescription.uniqueSubfamilyIdentification = string
            case .fullName:
                fontDescription.fullName = string
            case .version:
                fontDescription.version = string
            case .postScriptName:
                fontDescription.postScriptName = string
            case .trademark:
                fontDescription.trademark = string
            case .manufacturer:
                fontDescription.manufacturer = string
            case .designer:
                fontDescription.designer = string
            case .description:
                fontDescription.description = string
            case .vendorURL:
                fontDescription.vendorURL = string
            case .designerURL:
                fontDescription.designerURL = string
            case .license:
                fontDescription.license = string
            case .licenseURL:
                fontDescription.licenseURL = string
            case .reserved:
                fontDescription.reserved = string
            case .familyPreferred:
                fontDescription.familyPreferred = string
            case .subfamilyPreferred:
                fontDescription.subfamilyPreferred = string
            case .fullNameCompatible:
                fontDescription.fullNameCompatible = string
            case .sampleText:
                fontDescription.sampleText = string
            case .postScriptNameCID:
                fontDescription.postScriptNameCID = string
            case .familyWWS:
                fontDescription.familyWWS = string
            case .subfamilyWWS:
                fontDescription.subfamilyWWS = string
            case .backgroundPaletteLight:
                fontDescription.backgroundPaletteLight = string
            case .backgroundPaletteDark:
                fontDescription.backgroundPaletteDark = string
            case .postStriptNamePrefixVariations:
                fontDescription.postStriptNamePrefixVariations = string
            }

            if let index = fontDescriptionIndex {
                self.descriptions[index] = fontDescription
            } else {
                self.descriptions.append(fontDescription)
            }
        }
    }
}

struct FontDescription {

    let platformIdentifier: FontTableName.PlatformIdentifier
    let platformSpecificID: UInt16
    let language: FontTableName.LanguageID

    var copyright: String?
    var family: String?
    var subfamily: String?
    var uniqueSubfamilyIdentification: String?
    var fullName: String?
    var version: String?
    var postScriptName: String?
    var trademark: String?
    var manufacturer: String?
    var designer: String?
    var description: String?
    var vendorURL: String?
    var designerURL: String?
    var license: String?
    var licenseURL: String?
    var reserved: String?
    var familyPreferred: String?
    var subfamilyPreferred: String?
    var fullNameCompatible: String?
    var sampleText: String?
    var postScriptNameCID: String?
    var familyWWS: String?
    var subfamilyWWS: String?
    var backgroundPaletteLight: String?
    var backgroundPaletteDark: String?
    var postStriptNamePrefixVariations: String?

    init(platformIdentifier: FontTableName.PlatformIdentifier, platformSpecificID: UInt16, language: FontTableName.LanguageID) {
        self.platformIdentifier = platformIdentifier
        self.platformSpecificID = platformSpecificID
        self.language = language

        self.copyright = nil
        self.family = nil
        self.subfamily = nil
        self.uniqueSubfamilyIdentification = nil
        self.fullName = nil
        self.version = nil
        self.postScriptName = nil
        self.trademark = nil
        self.manufacturer = nil
        self.designer = nil
        self.description = nil
        self.vendorURL = nil
        self.designerURL = nil
        self.license = nil
        self.licenseURL = nil
        self.reserved = nil
        self.familyPreferred = nil
        self.subfamilyPreferred = nil
        self.fullNameCompatible = nil
        self.sampleText = nil
        self.postScriptNameCID = nil
        self.familyWWS = nil
        self.subfamilyWWS = nil
        self.backgroundPaletteLight = nil
        self.backgroundPaletteDark = nil
        self.postStriptNamePrefixVariations = nil
    }
}

enum FontTableName {
    enum PlatformIdentifier: UInt16 {
        case unicode = 0
        case macintosh = 1
        case reserved = 2
        case microsoft = 3
        case custom = 4
    }

    // swiftlint:disable nesting
    enum PlatformSpecificID {
        enum Macintosh: UInt16 {
            case roman = 0
            case japanese = 1
            case traditionalChinese = 2
            case korean = 3
            case arabic = 4
            case hebrew = 5
            case greek = 6
            case russian = 7
            case rSymbol = 8
            case devanagari = 9
            case gurmukhi = 10
            case gujarati = 11
            case oriya = 12
            case bengali = 13
            case tamil = 14
            case telugu = 15
            case kannada = 16
            case malayalam = 17
            case sinhalese = 18
            case burmese = 19
            case khmer = 20
            case thai = 21
            case laotian = 22
            case georgian = 23
            case armenian = 24
            case simplifiedChinese = 25
            case tibetan = 26
            case mongolian = 27
            case geez = 28
            case slavic = 29
            case vietnamese = 30
            case sindhi = 31
            case uninterpreted = 32
        }

        enum Unicode: UInt16 {
            case unicode1_0 = 0
            case unicode1_1 = 1
            case iso10646 = 2
            case unicode2_0_bmp_only = 3
            case unicode2_0_non_bmp_allowed = 4
            case unicode_variation_sequences = 5
            case unicode_full_coverage
        }

        enum Microsoft: UInt16 {
            case symbol = 0
            case unicodeBMP = 1
            case shiftJIS = 2
            case prc = 3
            case big5 = 4
            case wansung = 5
            case johab = 6
            case reserved7 = 7
            case reserved8 = 8
            case reserved9 = 9
            case unicodeUCS_4 = 10
        }
    }
    // swiftlint:enable nesting

    enum LanguageID: UInt16 {
        case english = 0
        case french = 1
        case german = 2
        case italian = 3
        case dutch = 4
        case swedish = 5
        case spanish = 6
        case danish = 7
        case portuguese = 8
        case norwegian = 9
        case hebrew = 10
        case japanese = 11
        case arabic = 12
        case finnish = 13
        case greek = 14
        case icelandic = 15
        case maltese = 16
        case turkish = 17
        case croatian = 18
        case chinese_traditional = 19
        case urdu = 20
        case hindi = 21
        case thai = 22
        case korean = 23
        case lithuanian = 24
        case polish = 25
        case hungarian = 26
        case estonian = 27
        case latvian = 28
        case sami = 29
        case faroese = 30
        case farsi_persian = 31
        case russian = 32
        case chinese_simplified = 33
        case flemish = 34
        case irish_gaelic = 35
        case albanian = 36
        case romanian = 37
        case czech = 38
        case slovak = 39
        case slovenian = 40
        case yiddish = 41
        case serbian = 42
        case macedonian = 43
        case bulgarian = 44
        case ukrainian = 45
        case byelorussian = 46
        case uzbek = 47
        case kazakh = 48
        case azerbaijani_cyrillic_script = 49
        case azerbaijani_arabic_script = 50
        case armenian = 51
        case georgian = 52
        case moldavian = 53
        case kirghiz = 54
        case tajiki = 55
        case turkmen = 56
        case mongolian_mongolian_script = 57
        case mongolian_cyrillic_script = 58
        case pashto = 59
        case kurdish = 60
        case kashmiri = 61
        case sindhi = 62
        case tibetan = 63
        case nepali = 64
        case sanskrit = 65
        case marathi = 66
        case bengali = 67
        case assamese = 68
        case gujarati = 69
        case punjabi = 70
        case oriya = 71
        case malayalam = 72
        case kannada = 73
        case tamil = 74
        case telugu = 75
        case sinhalese = 76
        case burmese = 77
        case khmer = 78
        case lao = 79
        case vietnamese = 80
        case indonesian = 81
        case tagalog = 82
        case malay_roman_script = 83
        case malay_arabic_script = 84
        case amharic = 85
        case tigrinya = 86
        case galla = 87
        case somali = 88
        case swahili = 89
        case kinyarwanda_ruanda = 90
        case rundi = 91
        case nyanja_chewa = 92
        case malagasy = 93
        case esperanto = 94
        case welsh = 128
        case basque = 129
        case catalan = 130
        case latin = 131
        case quechua = 132
        case guarani = 133
        case aymara = 134
        case tatar = 135
        case uighur = 136
        case dzongkha = 137
        case javanese_roman_script = 138
        case sundanese_roman_script = 139
        case galician = 140
        case afrikaans = 141
        case breton = 142
        case inuktitut = 143
        case scottish_gaelic = 144
        case manx_gaelic = 145
        case irish_gaelic_with_dot_above = 146
        case tongan = 147
        case greek_polytonic = 148
        case greenlandic = 149
        case azerbaijani_roman_script = 150
    }

    enum NameID: UInt16 {
        case copyright = 0
        case family = 1
        case subfamily = 2
        case uniqueSubfamilyIdentification = 3
        case fullName = 4
        case version = 5
        case postScriptName = 6
        case trademark = 7
        case manufacturer = 8
        case designer = 9
        case description = 10
        case vendorURL = 11
        case designerURL = 12
        case license = 13
        case licenseURL = 14
        case reserved = 15
        case familyPreferred = 16
        case subfamilyPreferred = 17
        case fullNameCompatible = 18
        case sampleText = 19
        case postScriptNameCID = 20
        case familyWWS = 21
        case subfamilyWWS = 22
        case backgroundPaletteLight = 23
        case backgroundPaletteDark = 24
        case postStriptNamePrefixVariations = 25
    }
}
