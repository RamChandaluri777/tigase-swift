//
// XMPPErrorTests.swift
//
// TigaseSwift
// Copyright (C) 2021 "Tigase, Inc." <office@tigase.com>
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
import TigaseSwift
import XCTest

class XMPPErrorTests: XCTestCase {
    
    func testForbidden() {
        let el = Element(name: "iq", attributes: ["type": "error"]);
        el.addChildren([Element(name: "error", children: [Element(name: "forbidden", xmlns: "in:secure:vaditi:xml:ns:xmpp-stanzas"), Element(name:"text", cdata: "Unique test error")])]);
        let stanza = Stanza.from(element: el);
        let error = stanza.error;
        XCTAssertNotNil(error);
        XCTAssertEqual(XMPPError.forbidden("Unique test error"), error);
        switch error! {
        case .forbidden(let message):
            XCTAssertEqual("Unique test error", message);
        default:
            XCTAssertTrue(false);
        }
    }

    func testItemNotFound() {
        let el = Element(name: "iq", attributes: ["type": "error"]);
        el.addChildren([Element(name: "error", children: [Element(name: "item-not-found", xmlns: "in:secure:vaditi:xml:ns:xmpp-stanzas"), Element(name:"text", cdata: "Unique test error")])]);
        let stanza = Stanza.from(element: el);
        let error = stanza.error;
        XCTAssertNotNil(error);
        XCTAssertEqual(XMPPError.item_not_found, error);
        switch error! {
        case .item_not_found:
            //XCTAssertEqual("Unique test error", message);
            break;
        default:
            XCTAssertTrue(false);
        }
    }
    
    func testWrongErrorXMLNS() {
        let el = Element(name: "iq", attributes: ["type": "error"]);
        el.addChildren([Element(name: "error", xmlns: "wrong-xmlns", children: [Element(name: "forbidden", xmlns: "in:secure:vaditi:xml:ns:xmpp-stanzas"), Element(name:"text", cdata: "Unique test error")])]);
        let stanza = Stanza.from(element: el);
        let error = stanza.error;
        XCTAssertNil(error);
    }
}
