//
//  FontInfo.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import CoreText
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

    func descriptions(forLanguages language: [FontTableName.LanguageID]) -> [FontDescription] {
        self.descriptions.filter { language.contains($0.language) }
    }

    func descriptions(forLanguage language: FontTableName.LanguageID, platform: FontTableName.PlatformIdentifier) -> [FontDescription] {
        self.descriptions.filter { $0.platformIdentifier == platform && $0.language == language }
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
            @unknown default:
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
            var encoding: String.Encoding

            // Use UTF-16 if
            // Platform ID is Unicode OR Platform specific ID is Unicode 2.0 or above
            // OR
            // Platform ID is Microsoft AND Platform specific ID is Unicode
            if (platformIDRaw == FontTableName.PlatformIdentifier.unicode.rawValue || FontTableName.PlatformSpecificID.Unicode.unicode2_0_bmp_only.rawValue <= platformSpecificIDRaw) ||
                (platformIDRaw == FontTableName.PlatformIdentifier.microsoft.rawValue && platformSpecificIDRaw == FontTableName.PlatformSpecificID.Microsoft.unicodeBMP.rawValue) {
                encoding = .utf16
            } else {
                encoding = .utf8
            }

            guard let string = fontTable.fontTableString(atOffset: (Int(offset + stringOffset)), length: Int(length), encoding: encoding) else {
                // Log.shared.debug(message: "Failed to get string for platformID: \(platformIDRaw), platfomrSpecificID: \(platformSpecificIDRaw), languageID: \(languageIDRaw), nameID: \(nameIDRaw)", category: String(describing: self))
                continue
            }

            guard let platformIdentifier = FontTableName.PlatformIdentifier(rawValue: platformIDRaw) else {
                // Log.shared.debug(message: "Failed to get platformIdentifier from platformIDRaw: \(platformIDRaw)", category: String(describing: self))
                // Log.shared.debug(message: "platformIdentifierString: \(string)", category: String(describing: self))
                continue
            }

            guard let language = FontTableName.LanguageID(rawValue: languageIDRaw) else {
                // Log.shared.debug(message: "Failed to get language from languageIDRaw: \(languageIDRaw)", category: String(describing: self))
                // Log.shared.debug(message: "languageString: \(string)", category: String(describing: self))
                continue
            }

            guard let nameID = FontTableName.NameID(rawValue: nameIDRaw) else {
                // Log.shared.debug(message: "Failed to get nameID from nameIDRaw: \(nameIDRaw)", category: String(describing: self))
                // Log.shared.debug(message: "nameIDString: \(string)", category: String(describing: self))
                continue
            }

            var fontDescriptionIndex: Int?
            var fontDescription: FontDescription
            if let index = self.descriptions.firstIndex(where: { $0.platformIdentifier == platformIdentifier && $0.platformSpecificID == platformSpecificIDRaw && $0.language == language }) {
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

        // Sticking the Microsoft Windows language IDs in here too since they are
        // non-overlapping with the Macintosh language IDs
        case ar_sa = 1_025
        case bg_bg = 1_026
        case ca_es = 1_027
        case zh_tw = 1_028
        case cs_cz = 1_029
        case da_dk = 1_030
        case de_de = 1_031
        case el_gr = 1_032
        case en_us = 1_033
        case es_es_tradnl = 1_034
        case fi_fi = 1_035
        case fr_fr = 1_036
        case he_il = 1_037
        case hu_hu = 1_038
        case is_is = 1_039
        case it_it = 1_040
        case ja_jp = 1_041
        case ko_kr = 1_042
        case nl_nl = 1_043
        case nb_no = 1_044
        case pl_pl = 1_045
        case pt_br = 1_046
        case rm_ch = 1_047
        case ro_ro = 1_048
        case ru_ru = 1_049
        case hr_hr = 1_050
        case sk_sk = 1_051
        case sq_al = 1_052
        case sv_se = 1_053
        case th_th = 1_054
        case tr_tr = 1_055
        case ur_pk = 1_056
        case id_id = 1_057
        case uk_ua = 1_058
        case be_by = 1_059
        case sl_si = 1_060
        case et_ee = 1_061
        case lv_lv = 1_062
        case lt_lt = 1_063
        case tg_cyrl_tj = 1_064
        case fa_ir = 1_065
        case vi_vn = 1_066
        case hy_am = 1_067
        case az_latn_az = 1_068
        case eu_es = 1_069
        case wen_de = 1_070
        case mk_mk = 1_071
        case st_za = 1_072
        case ts_za = 1_073
        case tn_za = 1_074
        case ven_za = 1_075
        case xh_za = 1_076
        case zu_za = 1_077
        case af_za = 1_078
        case ka_ge = 1_079
        case fo_fo = 1_080
        case hi_in = 1_081
        case mt_mt = 1_082
        case se_no = 1_083
        case gd_gb = 1_084
        case yi = 1_085
        case ms_my = 1_086
        case kk_kz = 1_087
        case ky_kg = 1_088
        case sw_ke = 1_089
        case tk_tm = 1_090
        case uz_latn_uz = 1_091
        case tt_ru = 1_092
        case bn_in = 1_093
        case pa_in = 1_094
        case gu_in = 1_095
        case or_in = 1_096
        case ta_in = 1_097
        case te_in = 1_098
        case kn_in = 1_099
        case ml_in = 1_100
        case as_in = 1_101
        case mr_in = 1_102
        case sa_in = 1_103
        case mn_mn = 1_104
        case bo_cn = 1_105
        case cy_gb = 1_106
        case km_kh = 1_107
        case lo_la = 1_108
        case my_mm = 1_109
        case gl_es = 1_110
        case kok_in = 1_111
        case mni = 1_112
        case sd_in = 1_113
        case syr_sy = 1_114
        case si_lk = 1_115
        case chr_us = 1_116
        case iu_cans_ca = 1_117
        case am_et = 1_118
        case tmz = 1_119
        case ks_arab_in = 1_120
        case ne_np = 1_121
        case fy_nl = 1_122
        case ps_af = 1_123
        case fil_ph = 1_124
        case dv_mv = 1_125
        case bin_ng = 1_126
        case fuv_ng = 1_127
        case ha_latn_ng = 1_128
        case ibb_ng = 1_129
        case yo_ng = 1_130
        case quz_bo = 1_131
        case nso_za = 1_132
        case ig_ng = 1_136
        case kr_ng = 1_137
        case gaz_et = 1_138
        case ti_er = 1_139
        case gn_py = 1_140
        case haw_us = 1_141
        case la = 1_142
        case so_so = 1_143
        case ii_cn = 1_144
        case pap_an = 1_145
        case ug_arab_cn = 1_152
        case mi_nz = 1_153
        case ar_iq = 2_049
        case zh_cn = 2_052
        case de_ch = 2_055
        case en_gb = 2_057
        case es_mx = 2_058
        case fr_be = 2_060
        case it_ch = 2_064
        case nl_be = 2_067
        case nn_no = 2_068
        case pt_pt = 2_070
        case ro_md = 2_072
        case ru_md = 2_073
        case sr_latn_cs = 2_074
        case sv_fi = 2_077
        case ur_in = 2_080
        case az_cyrl_az = 2_092
        case ga_ie = 2_108
        case ms_bn = 2_110
        case uz_cyrl_uz = 2_115
        case bn_bd = 2_117
        case pa_pk = 2_118
        case mn_mong_cn = 2_128
        case bo_bt = 2_129
        case sd_pk = 2_137
        case tzm_latn_dz = 2_143
        case ks_deva_in = 2_144
        case ne_in = 2_145
        case quz_ec = 2_155
        case ti_et = 2_163
        case ar_eg = 3_073
        case zh_hk = 3_076
        case de_at = 3_079
        case en_au = 3_081
        case es_es = 3_082
        case fr_ca = 3_084
        case sr_cyrl_cs = 3_098
        case quz_pe = 3_179
        case ar_ly = 4_097
        case zh_sg = 4_100
        case de_lu = 4_103
        case en_ca = 4_105
        case es_gt = 4_106
        case fr_ch = 4_108
        case hr_ba = 4_122
        case ar_dz = 5_121
        case zh_mo = 5_124
        case de_li = 5_127
        case en_nz = 5_129
        case es_cr = 5_130
        case fr_lu = 5_132
        case bs_latn_ba = 5_146
        case ar_mo = 6_145
        case en_ie = 6_153
        case es_pa = 6_154
        case fr_mc = 6_156
        case ar_tn = 7_169
        case en_za = 7_177
        case es_do = 7_178
        case fr_029 = 7_180
        case ar_om = 8_193
        case en_jm = 8_201
        case es_ve = 8_202
        case fr_re = 8_204
        case ar_ye = 9_217
        case en_029 = 9_225
        case es_co = 9_226
        case fr_cg = 9_228
        case ar_sy = 10_241
        case en_bz = 10_249
        case es_pe = 10_250
        case fr_sn = 10_252
        case ar_jo = 11_265
        case en_tt = 11_273
        case es_ar = 11_274
        case fr_cm = 11_276
        case ar_lb = 12_289
        case en_zw = 12_297
        case es_ec = 12_298
        case fr_ci = 12_300
        case ar_kw = 13_313
        case en_ph = 13_321
        case es_cl = 13_322
        case fr_ml = 13_324
        case ar_ae = 14_337
        case en_id = 14_345
        case es_uy = 14_346
        case fr_ma = 14_348
        case ar_bh = 15_361
        case en_hk = 15_369
        case es_py = 15_370
        case fr_ht = 15_372
        case ar_qa = 16_385
        case en_in = 16_393
        case es_bo = 16_394
        case en_my = 17_417
        case es_sv = 17_418
        case en_sg = 18_441
        case es_hn = 18_442
        case es_ni = 19_466
        case es_pr = 20_490
        case es_us = 21_514
        case es_419 = 58_378
        case fr_015 = 58_380
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
