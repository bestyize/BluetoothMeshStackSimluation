classdef TestObj
    properties
        eventHandler;
    end
    methods
        function obj=TestObj(eventHandler)
            obj.eventHandler=eventHandler;
        end
    end
end