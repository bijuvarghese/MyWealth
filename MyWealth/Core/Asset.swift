//
//  Asset.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//


import SwiftUI
import SwiftData
import Charts

@Model
final class Asset {
    var name: String?
    var amount: Double?
    var currency: CurrencyType?
    var category: CategoryType?
    var lastUpdated: Date?
    
    init(name: String, amount: Double, currency: CurrencyType, category: CategoryType, lastUpdated: Date? = Date()) {
        self.name = name
        self.amount = amount
        self.currency = currency
        self.category = category
        self.lastUpdated = lastUpdated
    }

    var displayName: String {
        name ?? ""
    }

    var displayAmount: Double {
        amount ?? 0
    }

    var displayCurrency: CurrencyType {
        currency ?? .none
    }

    var displayCategory: CategoryType {
        category ?? .others
    }
    
    enum CurrencyType: String, Codable, CaseIterable, Identifiable {
        case aed = "AED"
        case afn = "AFN"
        case all = "ALL"
        case amd = "AMD"
        case ang = "ANG"
        case aoa = "AOA"
        case ars = "ARS"
        case aud = "AUD"
        case awg = "AWG"
        case azn = "AZN"
        case bam = "BAM"
        case bbd = "BBD"
        case bdt = "BDT"
        case bgn = "BGN"
        case bhd = "BHD"
        case bif = "BIF"
        case bmd = "BMD"
        case bnd = "BND"
        case bob = "BOB"
        case brl = "BRL"
        case bsd = "BSD"
        case btc = "BTC"
        case btn = "BTN"
        case bwp = "BWP"
        case byn = "BYN"
        case byr = "BYR"
        case bzd = "BZD"
        case cad = "CAD"
        case cdf = "CDF"
        case chf = "CHF"
        case clf = "CLF"
        case clp = "CLP"
        case cnh = "CNH"
        case cny = "CNY"
        case cop = "COP"
        case crc = "CRC"
        case cuc = "CUC"
        case cup = "CUP"
        case cve = "CVE"
        case czk = "CZK"
        case djf = "DJF"
        case dkk = "DKK"
        case dop = "DOP"
        case dzd = "DZD"
        case egp = "EGP"
        case ern = "ERN"
        case etb = "ETB"
        case eur = "EUR"
        case fjd = "FJD"
        case fkp = "FKP"
        case gbp = "GBP"
        case gel = "GEL"
        case ggp = "GGP"
        case ghs = "GHS"
        case gip = "GIP"
        case gmd = "GMD"
        case gnf = "GNF"
        case gtq = "GTQ"
        case gyd = "GYD"
        case hkd = "HKD"
        case hnl = "HNL"
        case hrk = "HRK"
        case htg = "HTG"
        case huf = "HUF"
        case idr = "IDR"
        case ils = "ILS"
        case imp = "IMP"
        case inr = "INR"
        case iqd = "IQD"
        case irr = "IRR"
        case isk = "ISK"
        case jep = "JEP"
        case jmd = "JMD"
        case jod = "JOD"
        case jpy = "JPY"
        case kes = "KES"
        case kgs = "KGS"
        case khr = "KHR"
        case kmf = "KMF"
        case kpw = "KPW"
        case krw = "KRW"
        case kwd = "KWD"
        case kyd = "KYD"
        case kzt = "KZT"
        case lak = "LAK"
        case lbp = "LBP"
        case lkr = "LKR"
        case lrd = "LRD"
        case lsl = "LSL"
        case ltl = "LTL"
        case lvl = "LVL"
        case lyd = "LYD"
        case mad = "MAD"
        case mdl = "MDL"
        case mga = "MGA"
        case mkd = "MKD"
        case mmk = "MMK"
        case mnt = "MNT"
        case mop = "MOP"
        case mru = "MRU"
        case mur = "MUR"
        case mvr = "MVR"
        case mwk = "MWK"
        case mxn = "MXN"
        case myr = "MYR"
        case mzn = "MZN"
        case nad = "NAD"
        case ngn = "NGN"
        case nio = "NIO"
        case nok = "NOK"
        case npr = "NPR"
        case nzd = "NZD"
        case omr = "OMR"
        case pab = "PAB"
        case pen = "PEN"
        case pgk = "PGK"
        case php = "PHP"
        case pkr = "PKR"
        case pln = "PLN"
        case pyg = "PYG"
        case qar = "QAR"
        case ron = "RON"
        case rsd = "RSD"
        case rub = "RUB"
        case rwf = "RWF"
        case sar = "SAR"
        case sbd = "SBD"
        case scr = "SCR"
        case sdg = "SDG"
        case sek = "SEK"
        case sgd = "SGD"
        case shp = "SHP"
        case sle = "SLE"
        case sll = "SLL"
        case sos = "SOS"
        case srd = "SRD"
        case std = "STD"
        case stn = "STN"
        case svc = "SVC"
        case syp = "SYP"
        case szl = "SZL"
        case thb = "THB"
        case tjs = "TJS"
        case tmt = "TMT"
        case tnd = "TND"
        case top = "TOP"
        case tryCurrency = "TRY"
        case ttd = "TTD"
        case twd = "TWD"
        case tzs = "TZS"
        case uah = "UAH"
        case ugx = "UGX"
        case usd = "USD"
        case uyu = "UYU"
        case uzs = "UZS"
        case ves = "VES"
        case vnd = "VND"
        case vuv = "VUV"
        case wst = "WST"
        case xaf = "XAF"
        case xag = "XAG"
        case xau = "XAU"
        case xcd = "XCD"
        case xcg = "XCG"
        case xdr = "XDR"
        case xof = "XOF"
        case xpf = "XPF"
        case yer = "YER"
        case zar = "ZAR"
        case zmk = "ZMK"
        case zmw = "ZMW"
        case zwl = "ZWL"
        case none = ""

        var id: String { rawValue }
    }
    
    enum CategoryType: String, Codable, CaseIterable, Identifiable {
        case stocks = "Stocks"
        case realEstate = "Real Estate"
        case crypto = "Crypto"
        case bank = "Bank Deposits"
        case mutualFunds = "Mutual Funds"
        case gold = "Gold"
        case cars = "Cars"
        case others = "Others"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .stocks: "chart.line.uptrend.xyaxis"
            case .realEstate: "house.fill"
            case .crypto: "bitcoinsign.circle"
            case .bank: "banknote"
            case .mutualFunds: "chart.pie"
            case .gold: "rectangle.stack.fill"
            case .cars: "car.fill"
            case .others: "tray.full"
            }
        }
    }
}

@Model
final class AssetValueSnapshot {
    var assetIdentifier: String? = nil
    var assetName: String? = nil
    var amount: Double? = nil
    var currencyCode: String? = nil
    var categoryName: String? = nil
    var recordedAt: Date? = nil

    init(
        assetIdentifier: String,
        assetName: String,
        amount: Double,
        currencyCode: String,
        categoryName: String,
        recordedAt: Date = Date()
    ) {
        self.assetIdentifier = assetIdentifier
        self.assetName = assetName
        self.amount = amount
        self.currencyCode = currencyCode
        self.categoryName = categoryName
        self.recordedAt = recordedAt
    }

    var displayAssetIdentifier: String {
        assetIdentifier ?? ""
    }

    var displayAssetName: String {
        assetName ?? ""
    }

    var displayAmount: Double {
        amount ?? 0
    }

    var displayCurrencyCode: String {
        currencyCode ?? ""
    }

    var displayCategoryName: String {
        categoryName ?? ""
    }

    var displayRecordedAt: Date {
        recordedAt ?? .distantPast
    }
}

@Model
final class NetWorthSnapshot {
    var amount: Double? = nil
    var currencyCode: String? = nil
    var recordedAt: Date? = nil

    init(amount: Double, currencyCode: String, recordedAt: Date = Date()) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.recordedAt = recordedAt
    }

    var displayAmount: Double {
        amount ?? 0
    }

    var displayCurrencyCode: String {
        currencyCode ?? ""
    }

    var displayRecordedAt: Date {
        recordedAt ?? .distantPast
    }
}
