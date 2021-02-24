classdef DrawHelper
    methods(Static)
        %绘制源节点和目标节点图%
        function drawSrcAndDst(nodeCnt,srcId,dstId)
            myMap=TopoHelper.loadTopology(nodeCnt);
            global DEFAULT_RANGE;
            r=DEFAULT_RANGE;
            nodeCount=numel(myMap);
            for k=1:1:nodeCount
                x=myMap(k).x;
                y=myMap(k).y;
                plot(x,y,"r.")
                text(x,y,num2str(k))
                if k==srcId||k==dstId
                     rectangle('Position',[x-r,y-r,2*r,2*r],'Curvature',[1,1],'EdgeColor','b')
                 end
                hold on;
            end
            title("源节点和目的节点示意");
            axis([0 100,0 100]);
        end
        %绘制源节点和目标节点图%
        function drawAvgSrcAndDst(nodeCnt,srcId,dstId)
            myMap=TopoHelper.loadAvgTopology(nodeCnt);
            global DEFAULT_RANGE;
            r=DEFAULT_RANGE;
            nodeCount=numel(myMap);
            for k=1:1:nodeCount
                x=myMap(k).x;
                y=myMap(k).y;
                plot(x,y,"r.")
                text(x,y,num2str(k))
                if k==srcId||k==dstId
                     rectangle('Position',[x-r,y-r,2*r,2*r],'Curvature',[1,1],'EdgeColor','b')
                 end
                hold on;
            end
            title("源节点和目的节点示意");
            axis([0 100,0 100]);
        end
        
        
    end
    
end

