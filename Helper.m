classdef Helper
    methods(Static)
        %����ǲ����ھӽڵ�%
        function result = checkIsNeighbor(pos1,pos2)
%            global DEFAULT_RANGE;����ȫ�ֱ�������Ϊ��������ʱ��̫��������7s
            %METHOD1 �˴���ʾ�йش˷�����ժҪ
            %   �˴���ʾ��ϸ˵��
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


