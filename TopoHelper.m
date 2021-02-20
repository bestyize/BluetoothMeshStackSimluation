classdef TopoHelper < handle
    methods(Static)
        function [posMatrix]=createTopologyMatrix(num,maxX,maxY)
            global DEFAULT_RANGE;
            poisitionMatrix=[];
            for i=1:1:num
                pos=[round((DEFAULT_RANGE+rand()*(maxX-2*DEFAULT_RANGE)));round((DEFAULT_RANGE+rand()*(maxY-2*DEFAULT_RANGE)))];
                poisitionMatrix=[poisitionMatrix pos];
            end
            posMatrix=poisitionMatrix;
            TopoHelper.saveToLocal(posMatrix);
        end
        %保存到本地%
        function saveToLocal(matrix_nodes)
            save matrix_nodes;
        end
        
        function [result]=loadTopology(nodeCnt)
            result=[];
            switch (nodeCnt)
                case 50
                    result=TopoHelper.loadTopology50();
                case 100
                    result=TopoHelper.loadTopology100();
                case 150
                    result=TopoHelper.loadTopology150();
                case 200
                    result=TopoHelper.loadTopology200();
                otherwise
            end
        end
        
        function [result]=loadTopology50()
            load("matrix_50_nodes.mat",'-mat');
            result=matrix_50_nodes;
        end
        
        function [result]=loadTopology100()
            load("matrix_100_nodes.mat",'-mat');
            result=matrix_100_nodes;
        end

        function [result]=loadTopology150()
            load("matrix_150_nodes.mat",'-mat');
            result=matrix_150_nodes;
        end

        function [result]=loadTopology200()
            load("matrix_200_nodes.mat",'-mat');
            result=matrix_200_nodes;
        end
        
    end
end

