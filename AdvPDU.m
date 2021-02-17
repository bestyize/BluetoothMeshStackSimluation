classdef AdvPDU
    properties
        advA% 6 Byte %
        len% 1 Byte %
        adType% 1 Byte 0x29:PB-ADV 0x2A:Message 0x2B:Mesh Beacon%
        pdu% 0-29 Byte,maybe beacon or network pdu%
    end
    
    methods
        function obj=AdvPDU(advA,len,adType,pdu)
            obj.advA=advA;
            obj.len=len;
            obj.adType=adType;
            obj.pdu=pdu;
        end
        %Seriallize adv PDU%
        function [advPDU]=serialize(obj)
            advPDU=[obj.advA';obj.len;obj.adType;obj.pdu']';
        end
    end
    
    methods(Static)
        function [advPDU]=decodeAdvPDU(advData)
            advAddress=advData(1:6);
            len=advData(7);
            adType=advData(8);
            pdu=advData(9:7+len);
            adv=AdvPDU(advAddress,len,adType,pdu);
            advPDU=adv;
        end
       
        
    end
    
    
end