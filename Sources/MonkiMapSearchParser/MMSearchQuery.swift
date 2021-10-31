//
//  MMSearchQuery.swift
//  MonkiMapSearchParser
//
//  Created by Rémi Bardon on 19/10/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation

// MARK: - Search queries

public struct MMSearchQuery: Hashable {
	
	public let filters: [MMSearchFilter]
	
	public init(filters: [MMSearchFilter]) {
		self.filters = filters
	}
	
	public init(_ filters: MMSearchFilter...) {
		self.init(filters: filters)
	}
	
}

// MARK: String conversions

extension MMSearchQuery: CustomStringConvertible {
	
	public var description: String {
		return self.filters.map(String.init(describing:)).joined(separator: " ")
	}
	
}

// MARK: Debug string conversions

extension MMSearchQuery: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		return self.filters.map(String.init(reflecting:)).joined(separator: " ")
	}
	
}

// MARK: - Search filters

public indirect enum MMSearchFilter: Hashable {
	
	case word(String)
	case quotedString(String)
	case isDraft(ExtendedBoolToken)
	case kind(String)
	case category(String)
	case creator(UserToken)
	case imagesCount(RangeToken<UInt8>)
	case creation(RangeToken<DateToken>)
	case propertiesCount(kind: String, range: RangeToken<UInt8>)
	case hasProperty(kind: String, id: String, Bool)
	
}

// MARK: String conversions

extension MMSearchFilter: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case .word(let string):
			return string
		case .quotedString(let string):
			return "\"\(string)\""
		case .isDraft(let token):
			return "draft:\(token)"
		case .kind(let kind):
			return "kind:\(kind)"
		case .category(let category):
			return "category:\(category)"
		case .creator(let creator):
			return "creator:\(creator)"
		case .imagesCount(let range):
			return "images:\(range)"
		case .creation(let range):
			return "created:\(range)"
		case let .propertiesCount(kind: kind, range: range):
			return "properties:\(kind):\(range)"
		case let .hasProperty(kind: kind, id: id, bool):
			return "properties:\(kind)/\(id):\(bool)"
		}
	}
	
}

// MARK: Debug string conversions

extension MMSearchFilter: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		switch self {
		case .word(let string):
			return ".word(\(string))"
		case .quotedString(let string):
			return ".quotedString(\(string))"
		case .isDraft(let token):
			return ".isDraft(\(token))"
		case .kind(let kind):
			return ".kind(\(kind))"
		case .category(let category):
			return ".category(\(category))"
		case .creator(let creator):
			return ".creator(\(creator))"
		case .imagesCount(let range):
			return ".imagesCount(\(range))"
		case .creation(let range):
			return ".creation(\(range))"
		case let .propertiesCount(kind: kind, range: range):
			return ".propertiesCount(\(kind),\(range))"
		case let .hasProperty(kind: kind, id: id, bool):
			return ".hasProperty(\(kind),\(id),\(bool))"
		}
	}
	
}

// MARK: - Search tokens

public enum ExtendedBoolToken: Hashable {
	case bool(Bool), only
}

public enum UserToken: Hashable {
	case userId(String), username(String)
}

public struct DateToken: Hashable {
	
	public let stringValue: String
	public let dateValue: Date
	
	public init?(string: String) {
		self.stringValue = string
		
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withFullDate]
		guard let date = formatter.date(from: "2021-01-01") else { return nil }
		self.dateValue = date
	}
	
}

public enum RangeToken<T>: Hashable where T: Hashable {
	case equalTo(T)
	case lessThan(T), greaterThan(T)
	case lessThanOrEqualTo(T), greaterThanOrEqualTo(T)
	case between(T, and: T)
}

// MARK: String conversions

extension ExtendedBoolToken: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case .bool(true):
			return "true"
		case .bool(false):
			return "false"
		case .only:
			return "only"
		}
	}
	
}

extension UserToken: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case .userId(let userId):
			return "\(userId)"
		case .username(let username):
			return "@\(username)"
		}
	}
	
}

extension DateToken: CustomStringConvertible {
	
	public var description: String {
		return self.stringValue
	}
	
}

extension DateToken: ExpressibleByStringLiteral {
	
	public init(stringLiteral value: StringLiteralType) {
		guard let dateToken = Self(string: value) else {
			preconditionFailure("Invalid date literal")
		}
		
		self = dateToken
	}
	
}

extension RangeToken: CustomStringConvertible {
	
	// swiftlint:disable identifier_name
	public var description: String {
		switch self {
		case .equalTo(let n):
			return "\(n)"
		case .lessThan(let n):
			return "<\(n)"
		case .greaterThan(let n):
			return ">\(n)"
		case .lessThanOrEqualTo(let n):
			return "<=\(n)"
		case .greaterThanOrEqualTo(let n):
			return ">=\(n)"
		case let .between(x, and: y):
			return "\(x)..\(y)"
		}
	}
	// swiftlint:enable identifier_name
	
}

// MARK: Debug string conversions

extension ExtendedBoolToken: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		switch self {
		case .bool(true):
			return ".bool(true)"
		case .bool(false):
			return ".bool(false)"
		case .only:
			return ".only"
		}
	}
	
}

extension UserToken: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		switch self {
		case .userId(let userId):
			return ".userId(\(userId))"
		case .username(let username):
			return ".username(\(username))"
		}
	}
	
}

extension DateToken: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		return ".date(\(self.stringValue))"
	}
	
}

extension RangeToken: CustomDebugStringConvertible {
	
	// swiftlint:disable identifier_name
	public var debugDescription: String {
		switch self {
		case .equalTo(let n):
			return ".eq(\(n))"
		case .lessThan(let n):
			return ".lt(\(n))"
		case .greaterThan(let n):
			return ".gt(\(n))"
		case .lessThanOrEqualTo(let n):
			return ".le(\(n))"
		case .greaterThanOrEqualTo(let n):
			return ".ge(\(n))"
		case let .between(x, and: y):
			return ".between(\(x),\(y))"
		}
	}
	// swiftlint:enable identifier_name
	
}
