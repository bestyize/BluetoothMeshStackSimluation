classdef NetworkPDU<handle
    properties
        ivi % 1 bit %
        nid % 7 bit %
        ctl % 1 bit %
        ttl % 7 bit %
        seq % 3 byte %
        src % 2 byte %
        dst % 2 byte %
        transportPDU % 1-16 byte %
        netMIC % 4-8 byte %
    end
    
    methods
        function obj=NetworkPDU(ttl,seq,src,dst)
            obj.ivi=1;
            obj.nid=1;
            obj.ctl=0;
            obj.ttl=ttl;
            obj.seq=seq;
            obj.src=src;
            obj.dst=dst;
            obj.transportPDU=zeros(16,1);
            obj.netMIC=zeros(4,1);
        end
        % networkPDU serializable%
        function [networkPDU]=serialize(obj)
            iviBinary=de2bi(obj.ivi,1,'left-msb');
            nidBinary=de2bi(obj.nid,7,'left-msb');
            ctlBinary=de2bi(obj.ctl,1,'left-msb');
            ttlBinary=de2bi(obj.ttl,7,'left-msb');
            networkPDU=buildNetworkPDU(obj,iviBinary,nidBinary,ctlBinary,ttlBinary,obj.seq,obj.src,obj.dst,obj.transportPDU,obj.netMIC)';
        end
        
        
        % networkPDU serializable%
        function networkPDU=buildNetworkPDU(~,iviBinary,nidBinary,ctlBinary,ttlBinary,seq,src,dst,transportPDU,netMIC)
            iviNID=bi2de([iviBinary nidBinary],'left-msb');
            ctlTTL=bi2de([ctlBinary ttlBinary],'left-msb');
            seqBinary=de2bi(seq,24,'left-msb');
            seq=[bi2de(seqBinary(1:8),'left-msb');bi2de(seqBinary(9:16),'left-msb');bi2de(seqBinary(17:24),'left-msb')];
            % SRC
            srcBinary=de2bi(src,16,'left-msb');
            src=[bi2de(srcBinary(1:8),'left-msb');bi2de(srcBinary(9:16),'left-msb')];
            % SRC
            dstBinary=de2bi(dst,16,'left-msb');
            dst=[bi2de(dstBinary(1:8),'left-msb');bi2de(dstBinary(9:16),'left-msb')];
            networkPDU=[iviNID;ctlTTL;seq;src;dst;transportPDU;netMIC];
        end
        
        function [result]=toString(obj)
            result=sprintf("ivi:%d,nid:%d,ctl:%d,ttl:%d,seq:%d,src:%d,dst:%d",obj.ivi,obj.nid,obj.ctl,obj.ttl,obj.seq,obj.src,obj.dst);
        end
    end
    
    methods(Static)
        function [networkPDU]=decodeNetworkPDU(networkPayload)
            pdu=NetworkPDU(127,1,0,0);
            ctlTtlBinary=de2bi(networkPayload(2),8,'left-msb');
            decodeTtl=bi2de(ctlTtlBinary(2:8),'left-msb');
            pdu.ttl=decodeTtl;
            %decodeSeq=networkPayload(5)+networkPayload(4)*256+networkPayload(3)*256*256;
            decodeSeq=uint16(networkPayload(5))+uint16(networkPayload(4))*256+uint16(networkPayload(4))*256*256;
            pdu.seq=decodeSeq;
            decodeSrc=uint16(networkPayload(7))+uint16(networkPayload(6))*256;
            pdu.src=decodeSrc;
            decodeDst=uint16(networkPayload(9))+uint16(networkPayload(8))*256;
            pdu.dst=decodeDst;
            networkPDU=pdu;
        end
    end
    
end
