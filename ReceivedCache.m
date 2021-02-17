classdef ReceivedCache <handle
    %Cache ���н��յ��Ĳ��ظ����ݰ�����������
    %   �˴���ʾ��ϸ˵��
    
    properties
        maxSize int32;
        cachedPacketList;
    end
    
    methods
        %���캯������ʼ��Cache�Ĵ�С%
        function obj = ReceivedCache(maxSize)
            obj.maxSize=maxSize;
            obj.cachedPacketList=[CachedPacket(0,0,-1)];
        end
        
        %�ж��Ƿ���ܹ������ݰ�%
        function [result]=isPacketInCache(obj,packet)
            [~,cachedPacketListSize]=size(obj.cachedPacketList);
            %�޴�ľ����ѵ��������Ҫ�ӻ������ݰ������Ϸ�ȡ���ݣ�������һ��ʼ��%
            %��Ϊ���浽�ڵ�����ݰ��������ǰ���ʱ��˳���ŵģ��Ӻ���ǰ�����Ͽ���ʵ��ʱ�临�Ӷ�ΪO(1)%
            %����ǰ���ʵ�ֵ�ʱ�临�Ӷ�ΪO(N),���һ����Ͼ���N ������֮���ڷ���200������ÿ��20�����ݰ��������%
            %����ʱ���26.402s���ٵ���4.166s%
            %���˴Ӻ���ǰ�����⣬���ǻ����Դ����ƻ���ռ䳤�������֣����泤�����õ���һЩ%
            for k=cachedPacketListSize:-1:1  
                if(obj.cachedPacketList(k).src==packet.src&&obj.cachedPacketList(k).seq==packet.seq)
                    result=1;
                    return;
                end
            end
            result=0;
        end
        
        %�򻺴���������ݰ�%
        function addPacketToCache(obj,packet)
            [~,cachedPacketListSize]=size(obj.cachedPacketList);
            if(cachedPacketListSize>=obj.maxSize)
                %��2-middle+1���,��Ϊ��һ���ǷŽ�ȥ��ʼ������ģ�������ա�%
                % һ�ζ���һ�㣬����ÿ�ζ������Ŀ���̫����%,
                obj.cachedPacketList(2:((obj.maxSize/2)+1))=[];
                cachedPacketListSize=cachedPacketListSize-(obj.maxSize/2); 
            end
            global SYSTEM_CLOCK;
            obj.cachedPacketList(cachedPacketListSize+1)=CachedPacket(packet.src.packet.seq,SYSTEM_CLOCK);
        end
    end
end

