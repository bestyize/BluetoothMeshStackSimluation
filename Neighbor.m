classdef Neighbor
    properties
        advAddr % 6 Byte % 
        unicast % 2 Byte %
        neighborCnt;% 1 Byte 邻节点数量%
        neighborList % neighborCnt*2 Byte 所有的邻居节点的单播地址集合%
    end
    
    methods
        function obj=Neighbor(advAddr,unicast)
            obj.advAddr=advAddr;
            obj.unicast=unicast;
            obj.neighborList=[];
            obj.neighborCnt=0;
            
        end
        
        function [neighbor]=serialize(obj)
            unicastBinary=de2bi(obj.unicast,16,'left-msb');
            unicastArr=[bi2de(unicastBinary(1:8),'left-msb');bi2de(unicastBinary(9:16),'left-msb')];
            
            addressList=zeros(2*n,1);
            for k=1:1:n
                uniBinary=de2bi(obj.neighborList(k),16,'left-msb');
                addressList(2*k-1)=bi2de(uniBinary(1:8),'left-msb');
                addressList(2*k)=bi2de(uniBinary(9:16),'left-msb');
            end
            neighbor=[obj.advAddr';unicastArr;obj.neighborCnt;addressList]';
        end
    end
end