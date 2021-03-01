classdef MeshNode < handle
    properties
        advAddr;
        unicastAddr;
        position;
        txPower;%noardcast power,relative to tx range%
        txRange;%覆盖的半径%
        phyRate;%物理层速率，1Mbps、2Mbps%
        neighborList;%neighbors advAddr and unicastaddr%
        seq;%节点发送的消息序号%
        msgSendQueue;%msg to send%
        msgCacheQueue;%msg had recived%
        state;%sacnning=0 ,boardcasting=1  % 
        accepting;%1表示节点处于扫描态且正在接收广播信道数据%
        occurCollision;%记录接受过程中是否发生了冲突%
        eventList;%节点发生的事件%
        neighborState;%0表示未收集一跳邻居节点，1表示收集完一跳邻居节点集合，2表示全部收集完成%
        scanChannel;%扫描的信道%
        scanWindow;%扫描窗口%
        advertisingChannel;
        
    end
    
    methods
        
        function obj=MeshNode(unicastAddr,position)
            obj.advAddr=unicastAddr;%用单播地址替换BLE的MAC地址%
            obj.unicastAddr=unicastAddr;
            obj.position=position;
            obj.txRange=15;%默认15m%
            obj.phyRate=1000000;%默认1Mbps%
            obj.neighborList=[];
            obj.eventList=[];
            obj.msgSendQueue=[];
            obj.msgCacheQueue=Cache(100);%默认缓存大小为100%
            obj.state=0;
            obj.accepting=0;
            obj.occurCollision=0;
            obj.seq=1;
            obj.neighborState=0;
            obj.scanWindow=2*1000*1000;%2秒切换%
            obj.advertisingChannel=[37 38 39];
            obj.scanChannel=obj.advertisingChannel(floor(rand(1,1)*numel(obj.advertisingChannel))+1);%节点初始扫描信道随机化%
        end
        
        %******************************************************%
        %                         承载层                       %
        %******************************************************%       
        
        %怎么广播出去？给邻居节点添加一个事件，切换到广播接收状态.这里先给自己一个广播完成事件，广播事件不可被打断%
        function boardcast(obj,advPdu)
            global SYSTEM_TIME;
            global LIST_OF_MESH_NODE;
            channelTime=calculatorBoardcastTime(obj,advPdu);
            event=Event("EVT_ADV_END",SYSTEM_TIME+channelTime,SYSTEM_TIME+channelTime,advPdu,@eventHandler);
            addEvent(obj,event);
%             log=sprintf("time:%ld,node:%d,event:boardcast,action:boardcast packet",SYSTEM_TIME,obj.unicastAddr);
%             Log.print(log);
            if obj.neighborState==0
                %build one hop neighbor list%
                buildOneHopNeighborList(obj);
            end
            advChannelSwitchTime=152;%两个广播信道切换的时间间隔，在2018年sensor那篇文献中，测得的值%
            neighbors=getSelfNeighbor(obj);
            n=numel(neighbors);
            for k=1:1:n
                currNeighborUnicast=neighbors(k);
                channelCnt=numel(obj.advertisingChannel);
                for t=1:1:channelCnt
                    currNodeAdvertisingChannel=obj.advertisingChannel(t);
                    if LIST_OF_MESH_NODE(currNeighborUnicast).scanChannel==currNodeAdvertisingChannel%判断节点当前的扫描信道，广播包只能在一个信道上完成接收%
        %                 节点处于扫描态,并且未接收时才接收广播包
                        if LIST_OF_MESH_NODE(currNeighborUnicast).state==0&&LIST_OF_MESH_NODE(currNeighborUnicast).accepting==0
                            %state=0  非常关键的一点 ：说明当前节点正在扫描接收数据包，因此，数据包冲突丢失，这里应该给个状态%
                            startTime=SYSTEM_TIME+channelTime+(t-1)*(advChannelSwitchTime+channelTime);
                            event=Event("EVT_ADV_RECV_FINISH",startTime,startTime,advPdu,@eventHandler);
                            LIST_OF_MESH_NODE(currNeighborUnicast).addEvent(event);
                            LIST_OF_MESH_NODE(currNeighborUnicast).accepting=1;
                        %节点正在接收，会发生碰撞，丢失数据包%
                        elseif LIST_OF_MESH_NODE(currNeighborUnicast).state==0&&LIST_OF_MESH_NODE(currNeighborUnicast).accepting==1
                            log=sprintf("time:%ld,node:%d,event:packet collision,boardcast node:%d",SYSTEM_TIME,LIST_OF_MESH_NODE(currNeighborUnicast).unicastAddr,obj.unicastAddr);
                            Log.print(log);
                            obj.occurCollision=1;
                        %邻居节点正在广播，由于信道争用，他们的共有邻居节点如果处于扫描接收态，将会碰撞丢包,这种情况在第二种情况中有体现
                        %因此这里仅打印出来，不处理
                        elseif LIST_OF_MESH_NODE(currNeighborUnicast).state==1
        %                     collsionNodeList=intersect(neighbors,LIST_OF_MESH_NODE(currNeighborUnicast).getSelfNeighbor());
        %                     log=sprintf("time:%ld,node:%d,event:neighbor list packet collision,boardcast node:%d,collsion node:%s",SYSTEM_TIME,LIST_OF_MESH_NODE(currNeighborUnicast).unicastAddr,obj.unicastAddr,Helper.vectorToString(collsionNodeList));
        %                     Log.print(log);
                        end                          
                    end
                  
                end
            end
            
        end
        
        %切换扫描信道%
        function switchToNextScanChannel(obj)
            global SYSTEM_TIME;
            currScanChannel=obj.scanChannel;
            allAdvChannel=obj.advertisingChannel;
            n=numel(allAdvChannel);
            for k=1:1:n
                if allAdvChannel(k)==currScanChannel
                    if k<n
                        obj.scanChannel=allAdvChannel(k+1);
                    else
                        obj.scanChannel=allAdvChannel(1);
                    end
                    break;
                end
            end
            Log.print("time:"+SYSTEM_TIME+",node:"+obj.unicastAddr+",event:switch scan channel,prevChannel:"+currScanChannel+",currChannel:"+obj.scanChannel);
        end
        
        %注册切换扫描信道事件%
        function registSwitchScanChannelEvent(obj,totalSimlutationTime)
            times=obj.scanWindow:obj.scanWindow:totalSimlutationTime;
            n=numel(times);
            if n>0
                for k=1:1:n
                    event=Event("EVT_SWITCH_SCAN_CHANNEL",times(k),times(k),[],@eventHandler);
                    addEvent(obj,event);
                end
            end
            
        end
        
        function scanner(obj,advPdu)
%             if(obj.state==1)
%                 %数据包碰撞，丢包%
%                 return;
%             end
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
        
        %计算广播用时%
        function [result]=calculatorBoardcastTime(obj,advPacket)
            txTime=(8*(numel(advPacket)+10)*1000*1000)/obj.phyRate;
            result=floor(txTime);
        end
        
        %非定向不可连接广播包，ADV_NONCONN_IND，或者BLE_PACKET_TYPE_ADV_EXT%
        function onNonconnPacketReceivedSuccess(obj,advData)
            advPDU=AdvPDU.decodeAdvPDU(advData);
            prevUnicast=advAddressToUnicast(obj,advPDU.advA);
            switch (advPDU.adType)
                case 0x29  %PB-ADV%
                    onProvisioningBeaconPacketIn(obj,advPDU.pdu);
                case 0x2A  %Mesh Message%
                    onNetworkPacketIn(obj,prevUnicast,advPDU.pdu);
                case 0x2B  %Mesh Beacon%
                    onBeaconPacketIn(obj,prevUnicast,advPDU.pdu);
                otherwise
                    Log.print("Exception Of ADV_TYPE");
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
%                 log=sprintf("time:%ld,node:%d,event:onNetworkPacketIn,action:discard packet,data:%s",SYSTEM_TIME,obj.unicastAddr,networkPDU.toString());
%                 Log.print(log);
                return;
            elseif (obj.msgCacheQueue.isPacketInCache(cachePacket)==0&&isPacketInSendCache(obj,networkPDU)==0)%未缓存未发送%
                    obj.msgCacheQueue.addPacketToCache(cachePacket);
                    Log.print("time:"+SYSTEM_TIME+",node:"+obj.unicastAddr+",event:receivedPacket,data:"+networkPDU.toString());
                    if(networkPDU.dst==obj.unicastAddr)
                        Log.print("time:"+SYSTEM_TIME+",node:"+obj.unicastAddr+",event:arrive destation,data:"+networkPDU.toString());
                        onTransportPacketIn(obj,networkPDU.transportPDU);
                        return
                    end
                    

                    if networkPDU.ttl>2 %TTL要＞2才能转发%
%                         log=sprintf("time:%ld,node:%d,event:onNetworkPacketIn,action:relay packet,data:%s",SYSTEM_TIME,obj.unicastAddr,networkPDU.toString());
%                         Log.print(log);
                        networkPDU.ttl=networkPDU.ttl-1;
                       
                       %安排一个发送事件
                       startTime=SYSTEM_TIME+getRandomRelayDelay(obj,getFirstCoveredCount(obj,prevAdvAddr));
                       neighborsNeighborList=findNeighborByNeighborAddr(obj,prevAdvAddr);
                       selfNeighborList=getSelfNeighbor(obj);
                       networkRelayItem=NetworkRelayItem(networkPDU,selfNeighborList,[neighborsNeighborList prevAdvAddr]);
                       addPacketToSendQueue(obj,networkRelayItem); 
                       event=Event("EVT_RRD_ARRIVE",startTime,startTime,networkRelayItem,@eventHandler);
                       addEvent(obj,event);
%                        Log.print("time:"+SYSTEM_TIME+",node:"+obj.unicastAddr+",event:create evt_rrd_arrive,planTime:"+startTime+" ,data:%s"+networkPDU.toString());

                    end
                    
            elseif(networkPDU.dst~=obj.unicastAddr)%已缓存未发送，需要进行节点裁剪%
%                 log=sprintf("time:%ld,node:%d,event:onNetworkPacketIn,action:cut node,data:%s",SYSTEM_TIME,obj.unicastAddr,networkPDU.toString());
%                 Log.print(log);
                %裁剪%
                neighborsNeighborList=findNeighborByNeighborAddr(obj,prevAdvAddr);
                networkRelayItem=getNetworkRelayItem(obj,networkPDU);
                networkRelayItem.cutCoveredNode([neighborsNeighborList prevAdvAddr]);
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
            k=70;%调整系数%
            t=376;%微秒%
            N=5;
            if coveredCount<=N
                rrd=k*t*log10(5);
            else
                rrd=k*t*log10(N);
            end
            rrd=floor(rrd);%rrd最大值%
            %rrd=unidrnd(rrd)+10;%最终的rrd%。加上10us模拟程序处理时间
            rrd=floor(rand(1)*rrd)+10;
            %rrd=floor(rand(1)*20000)+10;%20ms%
            
        end
        %根据邻居节点的地址寻找邻居节点的邻居节点集合%
        function [neighbors]=findNeighborByNeighborAddr(obj,neighborAdvAddr)
            for k=1:1:numel(obj.neighborList)
                neighbor=obj.neighborList(k);
                if neighbor.advAddr==neighborAdvAddr
                    neighbors=neighbor.neighborList;
                    return;
                end
            end
            neighbors=[];
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
                    onProvisioningBeaconPacketIn(obj,beacon);
                case 1  %安全网络信标%
                    onSecureNetworkBeaconPacketIn(obj,beacon);
                case 2  %临居节点集交换信标%
                    onNeighborBeaconPacketIn(obj,prevAdvAddr,beacon);
                otherwise
                    Log.print("未知信标类型");
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
            else %更新邻居节点的二跳邻居节点集合%
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
        
        %安全网络信标%
        function onSecureNetworkBeaconPacketIn(varargin)
            
        end
        %未配网信标%
        function onProvisioningBeaconPacketIn(varargin)
            
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
                    if(obj.eventList(listIndex).startTime==obj.eventList(listIndex-1).startTime)
                       obj.eventList(listIndex).startTime= obj.eventList(listIndex).endTime+1;%有重叠时间，调整一下，保证同一时刻不能处理两个事件%
                    end
                    return;%一旦找到比自己小的了，就马上返回，因为前面的都比自己小了或者相等了%
                end
                listIndex=listIndex-1;%指针向前移动%
            end
        end
        
        %处理事件链表，在这时，最少有一个事件，才能调用%
        function obj=processEventList(obj)
%             global SYSTEM_TIME;
            eventListSize=numel(obj.eventList);
            if eventListSize==0
                return;
            end
            obj.eventList(1).eventHandler(obj,obj.eventList(1));

            %Log.print("time:"+SYSTEM_TIME+",node:"+obj.unicastAddr+",event:remove evt,eventType:"+obj.eventList(1).type);
            obj.eventList(1)=[];%删除事件%
        end
        
%        %处理事件链表，在这时，最少有一个事件，才能调用%
%         function obj=processEventList(obj)
%             global SYSTEM_TIME;
%             eventListSize=numel(obj.eventList);
%             if eventListSize==0
%                 return;
%             end
%             currTimeEvent=obj.eventList(1);
%             eventTime=currTimeEvent.startTime;
%             nextDiff=1;
%             for k=1:1:eventListSize
%                 if eventTime==obj.eventList(k).startTime
%                     obj.eventList(k).eventHandler(obj,obj.eventList(k));%处理之后事件链表长度可能已经变了会变长%
%                 else
%                     nextDiff=k;
%                     break;
%                 end
%             end
%             for k=1:1:nextDiff
%                  Log.print("time:"+SYSTEM_TIME+",node:"+obj.unicastAddr+",event:remove evt,eventType:"+obj.eventList(1).type);
%                  obj.eventList(1)=[];%删除事件%
%             end
%             
%         end
        
        %处理单个事件%
        function eventHandler(obj,event)
            global SYSTEM_TIME;
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
                         obj.state=1;%切换到广播态%
                        networkPDUSend(obj,relayItem.networkPDU);
                    else
                        log=sprintf("time:%ld,node:%d,event:abandon replay,data:%s",SYSTEM_TIME,obj.unicastAddr,relayItem.networkPDU.toString());
                        Log.print(log);
                    end
                    removeFromSendQueue(obj);%不管发不发送都要移除%
                    log=sprintf("time:%ld,node:%d,event:EVT_RRD_ARRIVE,data:%s",SYSTEM_TIME,obj.unicastAddr,relayItem.networkPDU.toString());
                    Log.print(log);
                case 'EVT_BEACON_ADV_START'
                    obj.state=1;%切换到广播态%
                    beaconPDUSend(obj,event.data);
                case 'EVT_ADV_END'
                    obj.state=0;%回到扫描状态%
                    
%                     log=sprintf("time:%ld,node:%d,event:EVT_ADV_END",SYSTEM_TIME,obj.unicastAddr);
%                     Log.print(log);
                case 'EVT_ADV_RECV_FINISH'
                    %log=sprintf("time:%ld,node:%d,event:EVT_ADV_RECV_FINISH",SYSTEM_TIME,obj.unicastAddr);
                    %Log.print(log);
                    obj.accepting=0;
                    if obj.occurCollision==1%接收失败.但是当前接收失败不代表不能接受到正常的数据包。有可能在另一个不冲突的时刻接收成功%
                        obj.occurCollision=0;
                        log=sprintf("time:%ld,node:%d,event:packet receive failed,reason:occurCollision",SYSTEM_TIME,obj.unicastAddr);
                        Log.print(log);
                        return;
                    end
                    scanner(obj,event.data);
                case 'EVT_ONE_HOP_NEIGHBOR_UPDATE_SUCCESS'
                    sendInitBeaconFinished(obj);
                case 'EVT_START_BUILD_TWO_HOP_NEIGHBOR_LIST'
                    sendNeighborListBeacon(obj);
                case 'EVT_SWITCH_SCAN_CHANNEL'
                    switchToNextScanChannel(obj);
                otherwise
            end
                    
        end
        %
        %Nc 表示已覆盖邻居节点，Nu表示未覆盖邻居节点，Nr表示当前节点的总邻居节点数量
        %
        function[prob]=randomRelay(~,Nc,Nu,Nr)
            k=8;
            if Nc<=k&&Nu~=0
                prob=1;
            else
                prob=Nu/Nr;
            end
            %prob=1;
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
        
        %直接建立两跳邻居节点，在这份代码里面也给出了利用Beacon建立二跳邻居节点的能力%
        function buildTwoHopNeighborList(obj)
            global LIST_OF_MESH_NODE;
            n=numel(obj.neighborList);
            for k=1:1:n
                neighborNode=LIST_OF_MESH_NODE(obj.neighborList(k).unicast);
                neighborNeighborList=neighborNode.getSelfNeighbor();
                obj.neighborList(k).neighborList=neighborNeighborList;
            end
            
        end
        
        
        
        %******************************************************%
        %                        模拟硬件                      %
        %******************************************************%
        
        %节点主动发送消息%
        function submitMeshMessageSendEvent(obj,dst,eventStartTime)
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
            event=Event("EVT_RRD_ARRIVE",startTime,startTime,networkRelayItem,@eventHandler);
            addEvent(obj,event); 
            log=sprintf("time:%ld,node:%d,event:send networkPDU,data:%s",startTime,obj.unicastAddr,networkPDU.toString());
            Log.print(log);
        end
        
        %发送初始化Beacon，暂不调用%
        function sendInitBeacon(obj,startTime)
            %global SYSTEM_TIME;
            %startTime=SYSTEM_TIME+getRandomRelayDelay(obj,0);
            beacon=Beacon(2,obj.unicastAddr,0,1,zeros(1,12));
            event=Event("EVT_BEACON_ADV_START",startTime,startTime,beacon.serialize(),@eventHandler);
            addEvent(obj,event);
        end
        
        function registInitBeaconFinishEvent(obj,startTime)
            event=Event("EVT_ONE_HOP_NEIGHBOR_UPDATE_SUCCESS",startTime,startTime,[],@eventHandler);
            addEvent(obj,event);
        end
        
        %通知完成一跳邻居节点收集%
        function sendInitBeaconFinished(obj)
            obj.neighborState=1;
        end
        %开始二跳邻居节点收集%
        function registBuildTwoHopNeighborListEvent(obj,startTime)
            event=Event("EVT_START_BUILD_TWO_HOP_NEIGHBOR_LIST",startTime,startTime,[],@eventHandler);
            addEvent(obj,event);
        end
        
        %发送邻节点集合Beacon%
        function sendNeighborListBeacon(obj)
            global SYSTEM_TIME;
            if obj.neighborState==2
                oneHopNeighborList=getSelfNeighbor(obj);
                n=numel(oneHopNeighborList)-1;
                if n<=12
                    startTime=SYSTEM_TIME+getRandomRelayDelay(obj,0);
                    beacon=Beacon(2,obj.unicastAddr,12,1,oneHopNeighborList);
                    event=Event("EVT_BEACON_ADV_START",startTime,startTime,beacon.serialize(),@eventHandler);
                    addEvent(obj,event);
                elseif n<=24
                    startTime1=SYSTEM_TIME+getRandomRelayDelay(obj,0);
                    beacon1=Beacon(2,obj.unicastAddr,12,0,oneHopNeighborList(1:12));
                    event1=Event("EVT_BEACON_ADV_START",startTime1,startTime1,beacon1.serialize(),@eventHandler);
                    addEvent(obj,event1);
                    startTime2=startTime1+20*1000;%20ms后下一次广播%
                    beacon2=Beacon(2,obj.unicastAddr,12,1,oneHopNeighborList(13:n));
                    event2=Event("EVT_BEACON_ADV_START",startTime2,startTime2,beacon2.serialize(),@eventHandler);
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
        
        %打印当前的事件链表%
        function printEventList(obj)
            log="";
            n=numel(obj.eventList);
            
            for k=1:1:n
                event=obj.eventList(k);
                log=log+sprintf("event:{type:%s,startTime:%ld,endTime:%ld},",event.type,event.startTime,event.endTime);
            end
            Log.print(log);
        end
        
        function printCacheList(obj)
           msgCacheList=obj.msgCacheQueue.cachedPacketList;
           log="";
           n=numel(msgCacheList);
           for k=1:1:n
               cache=msgCacheList(k);
               log=log+"cache:{src:"+cache.src+",seq:"+cache.seq+"},";
           end
           Log.print(log);
        end
        
       
       
        
    end
    
end