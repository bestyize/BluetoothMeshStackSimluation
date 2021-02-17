classdef Event < handle
    properties
        type;
        startTime uint64;
        endTime uint64;
        data;
        eventHandler;%函数指针，@functionname%
    end
    
    methods
        function obj=Event(type,startTime,endTime,data,eventHandler)
            obj.type=type;
            obj.startTime=startTime;
            obj.endTime=endTime;
            obj.data=data;
            obj.eventHandler=eventHandler;
        end
    end
end