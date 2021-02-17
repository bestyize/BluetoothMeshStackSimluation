classdef Cache <handle
    %Cache ���н��յ��Ĳ��ظ����ݰ�����������
    %   �˴���ʾ��ϸ˵��
    
    properties
        maxSize int32;
        cachedPacketList;
    end
    
    methods
        %���캯������ʼ��Cache�Ĵ�С%
        function obj = Cache(maxSize)
            obj.maxSize=maxSize;
            obj.cachedPacketList=[];
        end
        
        %�ж��Ƿ���ܹ������ݰ�%
        function [result]=isPacketInCache(obj,packet)
            %[~,cachedPacketListSize]=size(obj.cachedPacketList);
            cachedPacketListSize=numel(obj.cachedPacketList);
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
            cachedPacketListSize=numel(obj.cachedPacketList);
            if(cachedPacketListSize==obj.maxSize)
                obj.cachedPacketList(1)=[];
            end
            obj.cachedPacketList=[obj.cachedPacketList CachedPacket(packet.src,packet.seq)];
        end
    end
end

