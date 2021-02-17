pdu=NetworkPDU(127,1000,20,30)
payload=pdu.serialize();

realPdu=NetworkPDU.decodeNetworkPDU(payload);
realPdu.seq