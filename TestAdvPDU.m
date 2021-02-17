adva=[0x12 0x34 0x56 0x56 0x34 0x12];
advType=0x2A;
advPdu=[1,2,3,4,5,6,7];
len=numel([advType advPdu]);

advPDU=AdvPDU(adva,len,advType,advPdu);

data=advPDU.serialize();

adv=AdvPDU.decodeAdvPDU(data)