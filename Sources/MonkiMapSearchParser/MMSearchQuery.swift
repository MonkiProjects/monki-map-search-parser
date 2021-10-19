//
//  MMSearchQuery.swift
//  MonkiMapSearchParser
//
//  Created by Rémi Bardon on 19/10/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import Foundation

public struct MMSearchQuery: Hashable {
	
	public let filters: [MMSearchFilter]
	
	public init(filters: [MMSearchFilter]) {
		self.filters = filters
	}
	
	public init(_ filters: MMSearchFilter...) {
		self.init(filters: filters)
	}
	
}

public indirect enum MMSearchFilter: Hashable {
	
	case isDraft(ExtendedBoolToken)
	case kind(String)
	case category(String)
	case creator(UserToken)
	case imagesCount(RangeToken<UInt8>)
	case creation(RangeToken<DateToken>)
	case propertiesCount(kind: String, range: RangeToken<UInt8>)
	case hasProperty(kind: String, id: String, Bool)
	
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
	
}

extension MMSearchQuery: CustomStringConvertible {
	
	public var description: String {
		return self.filters.map(String.init(describing:)).joined(separator: " ")
	}
	
}

extension MMSearchFilter: CustomStringConvertible {
	
	public var description: String {
		switch self {
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

extension MMSearchFilter.ExtendedBoolToken: CustomStringConvertible {
	
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

extension MMSearchFilter.UserToken: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case .userId(let userId):
			return "\(userId)"
		case .username(let username):
			return "@\(username)"
		}
	}
	
}
extension MMSearchFilter.DateToken: CustomStringConvertible {
	
	public var description: String {
		return self.stringValue
	}
	
}

extension MMSearchFilter.DateToken: ExpressibleByStringLiteral {
	
	public init(stringLiteral value: StringLiteralType) {
		self.init(string: value)!
	}
	
}

extension MMSearchFilter.RangeToken: CustomStringConvertible {
	
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
		case .between(let x, and: let y):
			return "\(x)..\(y)"
		}
	}
	
}
