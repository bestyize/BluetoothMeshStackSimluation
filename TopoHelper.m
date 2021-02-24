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
                case 49
                    result=TopoHelper.loadTopology49();
                case 50
                    result=TopoHelper.loadTopology50();
                case 100
                    result=TopoHelper.loadTopology100();
                case 144
                    result=TopoHelper.loadTopology144();
                case 150
                    result=TopoHelper.loadTopology150();
                case 200
                    result=TopoHelper.loadTopology200();
                case 225
                    result=TopoHelper.loadTopology225();
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
        
        
        function [result]=loadTopology49()
            load("matrix_49_nodes.mat",'-mat');
            result=matrix_49_nodes;
        end

        function [result]=loadTopology144()
            load("matrix_144_nodes.mat",'-mat');
            result=matrix_150_nodes;
        end

        function [result]=loadTopology225()
            load("matrix_225_nodes.mat",'-mat');
            result=matrix_225_nodes;
        end
        
        function [result]=loadAvgTopology(nodeCnt)
            result=[];
            switch (nodeCnt)
                case 49
                    result=TopoHelper.loadAvgTopology49();
                case 100
                    result=TopoHelper.loadAvgTopology100();
                case 144
                    result=TopoHelper.loadAvgTopology144();
                case 196
                    result=TopoHelper.loadAvgTopology196();
                case 225
                    result=TopoHelper.loadAvgTopology225();
                otherwise
            end
        end
        
        function [result]=loadAvgTopology49()
            load("matrix_avg_49_nodes.mat",'-mat');
            result=matrix_avg_49_nodes;
        end
        
        function [result]=loadAvgTopology100()
            load("matrix_avg_100_nodes.mat",'-mat');
            result=matrix_avg_100_nodes;
        end

        function [result]=loadAvgTopology144()
            load("matrix_avg_144_nodes.mat",'-mat');
            result=matrix_avg_144_nodes;
        end

        function [result]=loadAvgTopology196()
            load("matrix_avg_196_nodes.mat",'-mat');
            result=matrix_avg_196_nodes;
        end  
        
        function [result]=loadAvgTopology225()
            load("matrix_avg_225_nodes.mat",'-mat');
            result=matrix_avg_225_nodes;
        end 
    end
end

