classdef EventList < handle
    properties 
        eventList;
    end
    
    methods
        function obj=EventList()
            obj.eventList=[];
        end
        %向节点事件链表里面添加事件%
        function obj=addEvent(obj,event)
            obj.eventList=[obj.eventList event];
            listIndex=numel(obj.eventList)+1;
            while listIndex>1
                if(obj.eventList(listIndex).startTime<obj.eventList(listIndex-1).startTime)
                    tempEvent=obj.theList(listIndex);
                    obj.eventList(listIndex)=obj.eventList(listIndex-1);
                    obj.eventList(listIndex-1)=tempEvent;
                else
                    return;%一旦找到比自己小的了，就马上返回，因为前面的都比自己小了或者相等了%
                end
                listIndex=listIndex-1;%指针向前移动%
            end
        end
        
        function obj=processEvent(obj)
            
        end
        
    end
end