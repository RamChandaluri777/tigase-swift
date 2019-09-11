//
// XMPPSrvRecord.swift
//
// TigaseSwift
// Copyright (C) 2016 "Tigase, Inc." <office@tigase.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. Look for COPYING file in the top folder.
// If not, see http://www.gnu.org/licenses/.
//

import Foundation

/**
 Class holds informations for single SRV record of DNS entries
 */
open class XMPPSrvRecord: Codable, Equatable, CustomStringConvertible {
    
    public static func == (lhs: XMPPSrvRecord, rhs: XMPPSrvRecord) -> Bool {
        return lhs.port == rhs.port && lhs.target == rhs.target && lhs.directTls == rhs.directTls && lhs.weight == rhs.weight && lhs.priority == rhs.priority;
    }
    
    var isValid: Bool {
        guard let invalid = self.invalid else {
            return true;
        }
        return Date().compare(invalid) == .orderedDescending;
    }
    
    let port:Int;
    let weight:Int;
    let priority:Int;
    let target:String;
    let directTls: Bool;
    fileprivate var invalid: Date?;

    open var description: String {
        return "[port: \(String(describing: port)), weight: \(weight), priority: \(String(describing: priority)), target: \(target), directTls: \(directTls), isValid: \(isValid)]";
    }
    
    init(port:Int, weight:Int, priority:Int, target:String, directTls: Bool, invalid: Date? = nil) {
        self.port = port;
        self.weight = weight;
        self.priority = priority;
        self.target = target;
        self.directTls = directTls;
        self.invalid = invalid;
    }
    
    func markAsInvalid(for period: TimeInterval) {
        self.invalid = Date().addingTimeInterval(period);
    }
}

open class XMPPSrvResult: Codable {
    
    public let domain: String;
    fileprivate(set) var records: [XMPPSrvRecord];
    public var hasValid: Bool {
        return records.firstIndex(where: { (rec) -> Bool in
            return rec.isValid == true;
        }) != nil;
    }
    
    init(domain: String, records: [XMPPSrvRecord]) {
        self.domain = domain;
        self.records = records;
    }
    
    func record() -> XMPPSrvRecord? {
        return records.first { (rec) -> Bool in
            return rec.isValid;
        }
    }
    
    func update(fromQuery records: [XMPPSrvRecord]) -> Bool {
        var tmp = self.records;
        var changed: Bool = false;
        let count = tmp.count;
        tmp = tmp.filter { (rec) -> Bool in
            return records.contains(rec);
        };
        changed = changed || (count != tmp.count);
        
        records.forEach { (rec) in
            guard let found = tmp.first(where: { (oldRec) -> Bool in
                return oldRec == rec;
            }) else {
                changed = true;
                tmp.append(rec);
                return;
            }
            if rec.invalid != nil {
                found.invalid = rec.invalid;
                changed = true;
            }
        }
//        tmp.append(contentsOf: records.filter({ (rec) -> Bool in
//            return !tmp.contains(rec);
//        }));
//        changed = changed || (count != tmp.count);
 
        self.records = tmp.sorted(by: { (a,b) -> Bool in
            if (a.priority < b.priority) {
                return true;
            } else if (a.priority > b.priority) {
                return false;
            } else {
                return a.weight > b.weight;
            }
        });
        return changed;
    }
    
    func markAsInvalid(record: XMPPSrvRecord, for period: TimeInterval) {
        guard let found = self.records.first(where: { (rec) -> Bool in
            return rec == record;
        }) else {
            return;
        }
        found.markAsInvalid(for: period);
    }
}
