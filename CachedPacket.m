classdef CachedPacket<handle
    %CachedPacket �������ݰ���
    %   �洢�ѽ��յ����ݰ������������ʱ��ͻ������ݰ���id���������ݰ�����srcId+"_"+seq��ɣ�����ʶ���ظ����ݰ���
    
    properties
        src;
        seq; 
    end
    
    methods
        %���캯��%
        function obj = CachedPacket(src,seq)
            obj.src=src;
            obj.seq=seq;
        end
        
        function [result]=toString(obj)
            result=sprintf("CachedPacket:{src:%d,dst=%d}",obj.src,obj.seq);
        end
    end
end

