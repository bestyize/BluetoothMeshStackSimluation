classdef MeshNode < handle
    properties
        advAddr;
        unicastAddr;
        position;
        txPower;%noardcast power,relative to tx range%
        txRange;%覆盖的半径%
        neighborList;%neighbors advAddr and unicastaddr%
        seq;%节点发送的消息序号%
        msgSendQueue;%msg to send%
        msgCacheQueue;%msg had recived%
        state;%sacnning=0 ,boardcasting=1  % 
        eventList;%节点发生的事件%
        neighborState;%0表示未收集一跳邻居节点，1表示收集完一跳邻居节点集合，2表示全部收集完成%
        
    end
    
    methods
        
        function obj=MeshNode(unicastAddr,position)
            obj.advAddr=unicastAddr;%用单播地址替换BLE的MAC地址%
            obj.unicastAddr=unicastAddr;
            obj.position=position;
            obj.txRange=15;%默认15m%
            obj.neighborList=[];
            obj.eventList=[];
            obj.msgSendQueue=[];
            obj.msgCacheQueue=Cache(100);%默认缓存大小为100%
            obj.state=0;
            obj.seq=1;
            obj.neighborState=0;
        end
        
        %******************************************************%
        %                         承载层                       %
        %******************************************************%       
        
        %怎么广播出去？给邻居节点添加一个事件，切换到广播接收状态.这里先给自己一个广播完成事件，广播事件不可被打断%
        function boardcast(obj,advPdu)
            global SYSTEM_TIME;
            global LIST_OF_MESH_NODE;
            event=Event("EVT_ADV_END",SYSTEM_TIME,SYSTEM_TIME+376,advPdu,@eventHandler);
            addEvent(obj,event);
            
            if obj.neighborState==0
                %build one hop neighbor list%
                buildOneHopNeighborList(obj);
            end
            
            neighbors=getSelfNeighbor(obj);
            n=numel(neighbors);
            for k=1:1:n
                currNode=LIST_OF_MESH_NODE(neighbors(k));
                if currNode.state==0
                    %state=0  非常关键的一点 ：说明当前节点正在扫描接收数据包，因此，数据包冲突丢失，这里应该给个状态%
                end
                currNode.state=0;%更新为扫描接收状态%
                startTime=SYSTEM_TIME;
                event=Event("EVT_ADV_RECV_SUCC",startTime,startTime+376,advPdu,@eventHandler);
                currNode.addEvent(event);
            end
            
            
            %find neighbor%
            
        end
        
        function scanner(obj,advPdu)
            if(obj.state==1)
                %数据包碰撞，丢包%
                return;
            end
            ADV_NONCONN_IND=1;
            if(ADV_NONCONN_IND)
                onNonconnPacketReceivedSuccess(obj,advPdu);
            end
            
        end
        
        function bearerAdv(obj,networkData,adType)
            adva=unicastToAdvAddr(obj);
            body=[adType networkData];
            advPdu=[adva numel(body) body];
            boardcast(obj,advPdu);
        end
        
        function [result]=unicastToAdvAddr(obj)
            uni=obj.unicastAddr;
            uniBinary=de2bi(uni,16,'left-msb');
            result=[0 0 0 0 bi2de(uniBinary(1:8),'left-msb') bi2de(uniBinary(9:16),'left-msb')];
        end
        
        function[result]=advAddressToUnicast(~,advAddress)
            result=advAddress(5)*256+advAddress(6);
        end
        
        %非定向不可连接广播包，ADV_NONCONN_IND，或者BLE_PACKET_TYPE_ADV_EXT%
        function onNonconnPacketReceivedSuccess(obj,advData)
            advPDU=AdvPDU.decodeAdvPDU(advData);
            prevUnicast=advAddressToUnicast(obj,advPDU.advA);
            switch (advPDU.adType)
                case 0x29  %PB-ADV%
                    %未实现配网%
                case 0x2A  %Mesh Message%
                    onNetworkPacketIn(obj,prevUnicast,advPDU.pdu);
                case 0x2B  %Mesh Beacon%
                    onBeaconPacketIn(obj,prevUnicast,advPDU.pdu);
                otherwise
            end
            
        end
        
        %******************************************************%
        %                    NetworkPDU层                    %
        %******************************************************%
        function onNetworkPacketIn(obj,prevAdvAddr,networkData)
            global SYSTEM_TIME;
            networkPDU=NetworkPDU.decodeNetworkPDU(networkData);
            cachePacket=CachedPacket(networkPDU.src,networkPDU.seq);
            if(obj.msgCacheQueue.isPacketInCache(cachePacket)==1&&isPacketInSendCache(obj,networkPDU)==0)%已缓存并且不在发送队列,丢弃%
                return;
            elseif (obj.msgCacheQueue.isPacketInCache(cachePacket)==0&&isPacketInSendCache(obj,networkPDU)==0)%未缓存未发送%
                    obj.msgCacheQueue.addPacketToCache(cachePacket);
                    if(networkPDU.dst==obj.unicastAddr)
                        Log.print("time:"+SYSTEM_TIME+",node:"+unicast+",event:receivedPacket"+networkPDU);
                        onTransportPacketIn(obj,networkPDU.transportPDU);
                        return
                    end
                    if networkPDU.ttl>2 %TTL要＞2才能转发%
                        networkPDU.ttl=networkPDU.ttl-1;
                       
                       %安排一个发送事件
                       startTime=SYSTEM_TIME+getRandomRelayDelay(obj,getFirstCoveredCount(obj,prevAdvAddr));
                       neighborsNeighborList=findNeighborByNeighborAddr(obj,prevAdvAddr);
                       selfNeighborList=getSelfNeighbor(obj);
                       networkRelayItem=NetworkRelayItem(networkPDU,selfNeighborList,neighborsNeighborList);
                       addPacketToSendQueue(obj,networkRelayItem); 
                       event=Event("EVT_RRD_ARRIVE",startTime,startTime+376,networkRelayItem,@eventHandler);
                       addEvent(obj,event);
                    end
                    
            elseif(networkPDU.dst~=obj.unicast)%已缓存未发送，需要进行节点裁剪%
                %裁剪%
                neighborsNeighborList=findNeighborByNeighborAddr(obj,prevAdvAddr);
                networkRelayItem=getNetworkRelayItem(obj,networkPDU);
                networkRelayItem.cutCoveredNode(neighborsNeighborList);
            end
            
        end
        
        function [firstCoverCount]=getFirstCoveredCount(obj,neighborAdvAddr)
            n=numel(obj.neighborList);
            if n>0
                for k=1:1:n
                    neighbor=obj.neighborList(k);
                    if (neighbor.advAddr==neighborAdvAddr)
                        firstCoverCount=numel(setdiff(getSelfNeighbor(obj),neighbor.neighborList));
                        return;
                    end
                end
            end
            firstCoverCount=0;
        end
        
        %随机转发延迟%
        function [rrd]=getRandomRelayDelay(~,coveredCount)
            k=50;%调整系数%
            t=376;%微秒%
            N=5;
            if coveredCount<=N
                rrd=k*t*log10(5);
            else
                rrd=k*t*log10(N);
            end
            rrd=int64(rrd);
        end
        %根据邻居节点的地址寻找邻居节点的邻居节点集合%
        function [neighbors]=findNeighborByNeighborAddr(obj,neighborAdvAddr)
            for k=1:1:numel(obj.neighborList)
                neighbor=obj.neighborList(k);
                if neighbor.advAddr==neighborAdvAddr
                    neighbors=neighbor.neighborList;
                    break;
                end
            end
        end
        
        %本节点的邻居节点集%
        function [neighbors]=getSelfNeighbor(obj)
            n=numel(obj.neighborList);
            selfNeighbor=zeros(1,n);
            selfNeighbor(1)=-1;
            for k=1:1:n
                selfNeighbor(k)=obj.neighborList(k).unicast;
            end
            neighbors=selfNeighbor;
        end
        
        function [result]=getNetworkRelayItem(obj,networkPDU)
            for k=1:1:numel(obj.msgSendQueue)
                pdu=obj.msgSendQueue(k).networkPDU;
                if pdu.src==networkPDU.src&&pdu.seq==networkPDU.seq
                    result=obj.msgSendQueue(k);
                    break;
                end
            end
        end
        
        function networkPDUSend(obj,networkPDU)
            netPack=networkPDU.serialize();
            bearerAdv(obj,netPack,0x2A);
        end
        
        %删除链表头元素,并返回元素%
        function[result]=removeFromSendQueue(obj)
            result=obj.msgSendQueue(1);
           obj.msgSendQueue(1)=[];
        end
        
        
        function[result]=isPacketInSendCache(obj,networkPDU)
            n=numel(obj.msgSendQueue);
            if n>=1
                for k=1:1:n
                    pdu=obj.msgSendQueue(k).networkPDU;
                    if(pdu.src==networkPDU.src&&pdu.seq==networkPDU.seq)
                        result=1;
                        return;
                    end
                end
            end
            result=0;
        end
        
        function addPacketToSendQueue(obj,networkRelayItem)
            obj.msgSendQueue=[obj.msgSendQueue networkRelayItem];
        end
        
        
        %******************************************************%
        %                          传输层                      %
        %******************************************************% 
        
        function onTransportPacketIn(varargin)
            %收到消息%
        end
        
        
        
        %******************************************************%
        %                          Beacon                      %
        %******************************************************%       
        function onBeaconPacketIn(obj,prevAdvAddr,beaconData)
            beacon=Beacon.decodeBeacon(beaconData);
            switch(beacon.beaconType)
                case 0  %未配网信标%
                    %未实现，默认网络已配网%
                case 1  %安全网络信标%
                    %未实现%
                case 2  %临居节点集交换信标%
                    onNeighborBeaconPacketIn(obj,prevAdvAddr,beacon);
                otherwise
            end
        end
        
        %更新二跳邻居节点集合%
        function onNeighborBeaconPacketIn(obj,prevAdvAddr,beacon)
            if beacon.nCnt==0&&beacon.Comp==1 %收集自身邻居节点信息%
                neighborNode=Neighbor(prevAdvAddr,beacon.unicast);
                newNeighborList=beacon.nUnicast;
                currNeighborList=neighbor.neighborList;
                neighborNode.neighborList=[currNeighborList newNeighborList];
                obj.neighborList=[obj.neighborList neighborNode];
            else %更新邻居节点的二跳邻居节点集和%
                for k=1:1:obj.neighborList
                    neighborNode=obj.neighborList(k);%检查邻节点是不是已经存在%
                    if (neighborNode.advAddr==prevAdvAddr)&&(neighborNode.unicast==beacon.unicast)
                        newNeighborList=beacon.nUnicast;
                        currNeighborList=neighbor.neighborList;
                        neighborNode.neighborList=[currNeighborList newNeighborList];
                        neighborNode.neighborCnt=numel(neighborNode.neighborList);
                        break;
                    end
                end                
            end
        end
        
        %广播beacon包%
        function beaconPDUSend(obj,beaconData)
           bearerAdv(obj,beaconData,0x2B); 
        end
        

        %******************************************************%
        %                        事件处理                      %
        %******************************************************%
        
        %向节点事件链表里面添加事件%
        function obj=addEvent(obj,event)
            obj.eventList=[obj.eventList event];
            listIndex=numel(obj.eventList);
            while listIndex>1
                if(obj.eventList(listIndex).startTime<obj.eventList(listIndex-1).startTime)
                    tempEvent=obj.eventList(listIndex);
                    obj.eventList(listIndex)=obj.eventList(listIndex-1);
                    obj.eventList(listIndex-1)=tempEvent;
                else
                    return;%一旦找到比自己小的了，就马上返回，因为前面的都比自己小了或者相等了%
                end
                listIndex=listIndex-1;%指针向前移动%
            end
        end
        
        %处理事件链表，在这时，最少有一个事件，才能调用%
        function obj=processEventList(obj)
            eventListSize=numel(obj.eventList);
            if eventListSize==0
                return;
            end
            currTimeEvent=obj.eventList(1);
            eventTime=currTimeEvent.startTime;
            nextDiff=1;
            for k=1:1:eventListSize
                if eventTime==obj.eventList(k).startTime
                    obj.eventList(k).eventHandler(obj,obj.eventList(k));%处理之后事件链表长度可能已经变了会变长%
                else
                    nextDiff=k;
                    break;
                end
            end
            for k=1:1:nextDiff
                obj.eventList(1)=[];%删除事件%
            end
            
        end
        
        %处理单个事件%
        function eventHandler(obj,event)
            switch (event.type)
                case 'EVT_RRD_ARRIVE'
                    relayItem=event.data;
                    unCoveredNeighborList=relayItem.unCoveredNeighborList;
                    totalNeighborList=relayItem.totalNeighborList;
                    Nu=numel(unCoveredNeighborList);
                    Nr=numel(totalNeighborList);
                    Nc=Nr-Nu;
                    prob=randomRelay(obj,Nc,Nu,Nr);
                    if(rand(1)<=prob)
                        obj.state=1;
                        networkPDUSend(obj,relayItem.networkPDU);
                    end
                    removeFromSendQueue(obj);%不管发不发送都要移除%
                    
                case 'EVT_ADV_START'
                    
                case 'EVT_BEACON_ADV_START'
                    beaconPDUSend(obj,event.data);
                case 'EVT_ADV_END'
                    obj.state=0;%回到扫描状态%
                case 'EVT_ADV_RECV_SUCC'
                    scanner(obj,event.data);
                otherwise
            end
                    
        end
        %
        %Nc 表示已覆盖邻居节点，Nu表示未覆盖邻居节点，Nr表示当前节点的总邻居节点数量
        %
        function[prob]=randomRelay(~,Nc,Nu,Nr)
            k=8;
            if Nc<=k
                prob=1;
            else
                prob=Nu/Nr;
            end
        end
        
        %******************************************************%
        %                    初始化邻居节点集合                 %
        %******************************************************%
        
        function buildOneHopNeighborList(obj)
            global LIST_OF_MESH_NODE;
            n=numel(LIST_OF_MESH_NODE);
            pos=obj.position;
            for k=1:1:n
                node=LIST_OF_MESH_NODE(k);
                if((obj.unicastAddr~=node.unicastAddr)&&Helper.checkIsNeighbor(pos,node.position))
                    neighborNode=Neighbor(node.advAddr,node.unicastAddr);
                    obj.neighborList=[obj.neighborList neighborNode];
                end
            end
            obj.neighborState=1;
        end
        
        
        
        %******************************************************%
        %                        模拟硬件                      %
        %******************************************************%
        
        %节点主动发送消息%
        function submitMeshMessageSendEvent(obj,dst,eventStartTime)
            %global SYSTEM_TIME;
            networkPDU=NetworkPDU(127,obj.seq,obj.unicastAddr,dst);
            obj.seq=obj.seq+1;
            cachePacket=CachedPacket(networkPDU.src,networkPDU.seq);
            obj.msgCacheQueue.addPacketToCache(cachePacket);
            %startTime=SYSTEM_TIME+getRandomRelayDelay(obj,0);
            startTime=eventStartTime;
            neighborsNeighborList=[];%自己发送的包要以概率1广播出去。在广播出去之前，不可能收到邻居节点给自己的这条消息的副本%
            selfNeighborList=getSelfNeighbor(obj);
            networkRelayItem=NetworkRelayItem(networkPDU,selfNeighborList,neighborsNeighborList);
            addPacketToSendQueue(obj,networkRelayItem); 
            event=Event("EVT_RRD_ARRIVE",startTime,startTime+376,networkRelayItem,@eventHandler);
            addEvent(obj,event); 
        end
        
        %发送初始化Beacon，暂不调用%
        function sendInitBeacon(obj)
            global SYSTEM_TIME;
            startTime=SYSTEM_TIME+getRandomRelayDelay(obj,0);
            beacon=Beacon(2,obj.unicastAddr,0,1,zeros(1,12));
            event=Event("EVT_ADV_START",startTime,startTime+376,beacon.serialize(),@eventHandler);
            addEvent(obj,event);
        end
        
        %发送邻节点集合Beacon%
        function sendNeighborListBeacon(obj)
            if obj.neighborState==2
                oneHopNeighborList=getSelfNeighbor(obj);
                n=numel(oneHopNeighborList)-1;
                if n<=12
                    startTime=SYSTEM_TIME+getRandomRelayDelay(obj,0);
                    beacon=Beacon(2,obj.unicastAddr,12,1,oneHopNeighborList);
                    event=Event("EVT_BEACON_ADV_START",startTime,startTime+376,beacon.serialize(),@eventHandler);
                    addEvent(obj,event);
                elseif n<=24
                    startTime1=SYSTEM_TIME+getRandomRelayDelay(obj,0);
                    beacon1=Beacon(2,obj.unicastAddr,12,0,oneHopNeighborList(1:12));
                    event1=Event("EVT_BEACON_ADV_START",startTime1,startTime1+376,beacon1.serialize(),@eventHandler);
                    addEvent(obj,event1);
                    startTime2=startTime1+20*1000;%20ms后下一次广播%
                    beacon2=Beacon(2,obj.unicastAddr,12,1,oneHopNeighborList(13:n));
                    event2=Event("EVT_BEACON_ADV_START",startTime2,startTime2+376,beacon2.serialize(),@eventHandler);
                    addEvent(obj,event2);
                end
                
            end
        end
        
        %******************************************************%
        %                        打印节点消息                   %
        %******************************************************%
        
        %打印邻居节点信息%
        function printSelfNeighbor(obj)
            neighbors=getSelfNeighbor(obj);
            Log.print(neighbors);
        end
        
        function printEventList(obj)
            Log.print(obj.eventList);
        end
       
        
    end
    
end