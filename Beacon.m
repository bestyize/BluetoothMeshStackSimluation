classdef Beacon
    properties
        beaconType % 2 Byte 0:Unprovisioned Device Beacon,1:Secure Network Beacon,2 Neighbor Address Exchange Beacon%
        unicast % 2 Byte ,0b00XX XXXX XXXX XXXX%
        nCnt % 7 bit %
        Comp % 1 bit %
        nUnicast % 0-24 Byte %
    end
    
    methods
        function obj=Beacon(beaconType,unicast,nCnt,Comp,nUnicast)
            obj.beaconType=beaconType;
            obj.unicast=unicast;
            obj.nCnt=nCnt;
            obj.Comp=Comp;
            obj.nUnicast=nUnicast;
        end
        
        %beacon serializable%
        function [beacon]=serialize(obj)
            nCntBinary=de2bi(obj.nCnt,7,'left-msb');
            CompBinary=de2bi(obj.Comp,1,'left-msb');
            nCntComp=bi2de([nCntBinary CompBinary],'left-msb');
            beaconTypeBinary=de2bi(obj.beaconType,16,'left-msb');
            beaconTypeArr=[bi2de(beaconTypeBinary(1:8),'left-msb');bi2de(beaconTypeBinary(9:16),'left-msb')];
            unicastBinary=de2bi(obj.unicast,16,'left-msb');
            unicastArr=[bi2de(unicastBinary(1:8),'left-msb');bi2de(unicastBinary(9:16),'left-msb')];
            n=numel(obj.nUnicast);
            addressList=zeros(2*n,1);
            for k=1:1:n
                uniBinary=de2bi(obj.nUnicast(k),16,'left-msb');
                addressList(2*k-1)=bi2de(uniBinary(1:8),'left-msb');
                addressList(2*k)=bi2de(uniBinary(9:16),'left-msb');
            end
            beacon=[beaconTypeArr;unicastArr;nCntComp;addressList]';
        end
        
        function [result]=toString(obj)
            result=sprintf("beacon:{beaconType:%d,unicast=%d,nCnt=%d,Comp=%d}",obj.beaconType,obj.unicast,obj.nCnt,obj.Comp);
        end
        
    end
    
    methods(Static)
        %Beacon decode%
        function [beacon]=decodeBeacon(beaconPayload)
            pdu=Beacon(0,0,0,0,0);
            pdu.beaconType=unin16(beaconPayload(2))+uint16(beaconPayload(1))*256;
            pdu.unicast=uint16(beaconPayload(4))+uint16(beaconPayload(3))*256;
            nCntComp=beaconPayload(5);
            nCntCompBinary=de2bi(nCntComp,8,'left-msb');
            nCnt=bi2de(nCntCompBinary(1:7),'left-msb');
            Comp=bi2de(nCntCompBinary(7:8),'left-msb');
            pdu.nCnt=nCnt;
            pdu.Comp=Comp;
            
            addressListBinary=beaconPayload(6:nCnt*2+5);
            addressList=zeros(1,nCnt);
            for k=1:1:nCnt
                addressList(k)=uint16(addressListBinary(2*k))+uint16(addressListBinary(2*k-1))*256;
            end
            pdu.nUnicast=addressList;
            beacon=pdu;
        end
    end
end