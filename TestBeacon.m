
beaconType=2;
unicast=20;

nComp=1;
nUnicast=[21 23 2 16 9 27];
nCnt=numel(nUnicast);

beacon=Beacon(beaconType,unicast,nCnt,nComp,nUnicast);
data=beacon.serialize();

b=Beacon.decodeBeacon(data)


