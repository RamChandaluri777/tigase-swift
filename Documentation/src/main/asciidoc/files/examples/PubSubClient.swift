import Foundation
import TigaseSwift

class PubSubClient: EventHandler {

    var client: XMPPClient;
    var pubsubJid: BareJID!;
    let nodeName = "test-node1";

    var errorHandler: ((ErrorCondition?,PubSubErrorCondition?)->Void)? = { (errorCondition,pubsubErrorCondition) in
        print("received error: ", errorCondition, pubsubErrorCondition);
    };

    init() {
        Log.initialize();

        client = XMPPClient();

        registerModules();

        print("Notifying event bus that we are interested in SessionEstablishmentSuccessEvent" +
            " which is fired after client is connected");
        client.eventBus.register(handler: self, for: SessionEstablishmentModule.SessionEstablishmentSuccessEvent.TYPE);
        print("Notifying event bus that we are interested in DisconnectedEvent" +
            " which is fired after client is connected");
        client.eventBus.register(handler: self, for: SocketConnector.DisconnectedEvent.TYPE);
        print("Notifying event bus that we are interested in ContactPresenceChangedEvent");
        client.eventBus.register(handler: self, for: PresenceModule.ContactPresenceChanged.TYPE);
        print("Notifying event bus that we are interedted in PubSubModule.NotificationReceivedEvent");
        client.eventBus.register(handler: self, for: PubSubModule.NotificationReceivedEvent.TYPE)

        setCredentials(userJID: "sender@domain.com", password: "Pa$$w0rd");

        pubsubJid = BareJID("pubsub." + client.sessionObject.userBareJid!.domain);

        print("Connecting to server..")
        client.login();
        print("Started async processing..");
    }

    func registerModules() {
        print("Registering modules required for authentication and session establishment");
        _ = client.modulesManager.register(AuthModule());
        _ = client.modulesManager.register(StreamFeaturesModule());
        _ = client.modulesManager.register(SaslModule());
        _ = client.modulesManager.register(ResourceBinderModule());
        _ = client.modulesManager.register(SessionEstablishmentModule());

        print("Registering module for handling presences..");
        _ = client.modulesManager.register(PresenceModule());
        print("Registering module for handling messages..");
        _ = client.modulesManager.register(MessageModule());
        print("Registering module for handling pubsub protocol..");
        _ = client.modulesManager.register(PubSubModule());
}

    func setCredentials(userJID: String, password: String) {
        let jid = BareJID(userJID);
        client.connectionConfiguration.setUserJID(jid);
        client.connectionConfiguration.setUserPassword(password);
    }

    /// Processing received events
    func handle(event: Event) {
        switch (event) {
        case is SessionEstablishmentModule.SessionEstablishmentSuccessEvent:
            sessionEstablished();
        case is SocketConnector.DisconnectedEvent:
            print("Client is disconnected.");
        case let cpc as PresenceModule.ContactPresenceChanged:
            contactPresenceChanged(cpc);
        case let psne as PubSubModule.NotificationReceivedEvent:
            pubsubNotificationReceived(psne);
        default:
            print("unsupported event", event);
        }
    }

    /// Called when session is established
    func sessionEstablished() {
        print("Now we are connected to server and session is ready..");

        let presenceModule: PresenceModule = client.modulesManager.getModule(PresenceModule.ID)!;
        print("Setting presence to DND...");
        presenceModule.setPresence(show: Presence.Show.dnd, status: "Do not distrub me!", priority: 2);
        self.createPubSubNode();
    }

    func contactPresenceChanged(_ cpc: PresenceModule.ContactPresenceChanged) {
        print("We got notified that", cpc.presence.from, "changed presence to", cpc.presence.show);
    }

    func createPubSubNode() {
        let pubsubModule: PubSubModule = client.modulesManager.getModule(PubSubModule.ID)!;
        pubsubModule.createNode(at: pubsubJid, node: nodeName, onSuccess: { (stanza) in
            print("node", self.nodeName, "created at", self.pubsubJid);
            self.publishItem();
        }, onError: self.errorHandler);
    }

    func publishItem() {
        let pubsubModule: PubSubModule = client.modulesManager.getModule(PubSubModule.ID)!;

        let payload = Element(name: "message-body", cdata: "Sample item");

        pubsubModule.publishItem(at: pubsubJid, to: nodeName, payload: payload, onSuccess: { (stanza,node,id) in
            print("published item with id", id, "on node", node, "at", self.pubsubJid);
            self.retrieveItems();
        }, onError: self.errorHandler);
    }

    func retrieveItems() {
        let pubsubModule: PubSubModule = client.modulesManager.getModule(PubSubModule.ID)!;

        pubsubModule.retriveItems(from: pubsubJid, for: nodeName, onSuccess: { (stanza, node, items, rsm) in
            print("retrieved", items.count, " items from", stanza.from, "node", node, "items = ", items);
            self.deletePubSubNode()
        }, onError: self.errorHandler);
    }

    func deletePubSubNode() {
        let pubsubModule: PubSubModule = client.modulesManager.getModule(PubSubModule.ID)!;
        pubsubModule.deleteNode(from: pubsubJid, node: nodeName, onSuccess: { (stanza) in
            print("node", self.nodeName, "deleted from", self.pubsubJid);
        }, onError: self.errorHandler);
    }

    func pubsubNotificationReceived(_ event: PubSubModule.NotificationReceivedEvent) {
        print("received notification event from pubsub node", event.nodeName, "at", event.message.from, "action", event.itemType, "with item id", event.itemId, "and payload", event.payload?.stringValue);
    }
}
