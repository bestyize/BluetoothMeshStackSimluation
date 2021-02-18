classdef NetworkRelayItem<handle
    properties
        networkPDU NetworkPDU;
        unCoveredNeighborList;%在转发前还没覆盖的邻居节点集合%
        totalNeighborList;%当前节点所有邻居节点集合%
    end
    
    methods
        function obj=NetworkRelayItem(networkPDU,totalNeighborList,prevNodeNeighborList)
            obj.networkPDU=networkPDU;
            obj.totalNeighborList=totalNeighborList;
            obj.unCoveredNeighborList=setdiff(totalNeighborList,prevNodeNeighborList);
        end
        
        function obj=cutCoveredNode(obj,prevNodeNeighborList)
            obj.unCoveredNeighborList=setdiff(obj.unCoveredNeighborList,prevNodeNeighborList);%求集合的差：https://zhidao.baidu.com/question/1436496841397196579.html%
        end
    end
   
end