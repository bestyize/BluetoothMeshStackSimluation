classdef Log
    methods(Static)
        function print(logs)
            logs
            persistent  fid
            if(isempty(fid))
                fid=fopen('mesh.log','a+');
            end
            fprintf(fid,logs+"\r\n");
        end
    end
end