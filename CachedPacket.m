classdef CachedPacket<handle
    %CachedPacket 缓存数据包类
    %   存储已接收的数据包，包括缓存的时间和缓存数据包的id，缓存数据包的由srcId+"_"+seq组成，用来识别重复数据包。
    
    properties
        src;
        seq; 
    end
    
    methods
        %构造函数%
        function obj = CachedPacket(src,seq)
            obj.src=src;
            obj.seq=seq;
        end
        
        function [result]=toString(obj)
            result=sprintf("CachedPacket:{src:%d,dst=%d}",obj.src,obj.seq);
        end
    end
end

