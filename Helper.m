classdef Helper
    methods(Static)
        %检查是不是邻居节点%
        function result = checkIsNeighbor(pos1,pos2)
%            global DEFAULT_RANGE;不用全局变量是因为这里消耗时间太长，长达7s
            %METHOD1 此处显示有关此方法的摘要
            %   此处显示详细说明
%             x_change=(pos1.x-pos2.x)*(pos1.x-pos2.x);
%             y_change=(pos1.y-pos2.y)*(pos1.y-pos2.y);
            result=(sqrt(power(pos1.x-pos2.x,2)+power(pos1.y-pos2.y,2))<15);
        end
        
        function [result]=vectorToString(vector)
            str="[";
            n=numel(vector);
            for k=1:1:n
                str=str+" "+vector(k);
            end
            result=str+"]";
        end
    end
end


