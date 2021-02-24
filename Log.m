classdef Log
    methods(Static)
        function print(logs)
            %logs
            persistent  fid;
            if(isempty(fid))
                str=datestr(now,31);
                str=strrep(str,":","-");
                str=strrep(str," ","_")
                fid=fopen(str+'mesh.log','a+');
            end
            fprintf(fid,logs+"\r\n");
        end
    end
end