clear;
clc;
global LIST_OF_MESH_NODE;
global SYSTEM_TIME;
global DEFAULT_RANGE;
global REACH_NODE;

LIST_OF_MESH_NODE=[];
SYSTEM_TIME=0;
DEFAULT_RANGE=15;
REACH_NODE=[];





main();


function main()
    global LIST_OF_MESH_NODE;
    global SYSTEM_TIME;
    global REACH_NODE;
    
    srcId=3;
    dstId=45;
    packetNum=20;
    rate=20;%20p/s%

    buildNodeList();
    buildOneHopNeighborForEachNode();
    %建立两跳邻居节点关系
    buildTwoHopNeighborForEachNode();
    
    DrawHelper.drawSrcAndDst(srcId,dstId);
    pause(1);%先打印节点%
    %printAvgNodeDegree();
    
    simlulationTime=10*1000*1000;%仿真10秒%
    timestamp=0;
    nodeCount=numel(LIST_OF_MESH_NODE);
    
    packetSendEventHelper(srcId,dstId,packetNum,rate);
    
    %系统开始运行%
    while timestamp<simlulationTime
        SYSTEM_TIME=timestamp;
        for k=1:1:nodeCount
            meshNode=LIST_OF_MESH_NODE(k);
            eventList=meshNode.eventList;
            eventCnt=numel(eventList);
            if eventCnt>0
                currEvent=eventList(1);
                if currEvent.startTime==timestamp
                    meshNode.processEventList();%节点自己维护一个事件链表%
                end
            end
        end
        timestamp=timestamp+1;
    end
    
end

%根据拓扑创建节点%
function buildNodeList()
    global LIST_OF_MESH_NODE;
    nodeMap=TopoHelper.loadTopology();
    nodeCount=size(nodeMap,2);
    for i=1:1:nodeCount
        position=Position(nodeMap(1,i),nodeMap(2,i));
        LIST_OF_MESH_NODE=[LIST_OF_MESH_NODE MeshNode(i,position)];
    end
end

%根据拓扑建立一跳邻居关系。在仿真里面需要提前布置好一跳邻居关系，在这份代码里面也给出了自动建立拓扑关系的部分%
function buildOneHopNeighborForEachNode()
    global LIST_OF_MESH_NODE;
    nodeCount=numel(LIST_OF_MESH_NODE);
    for k=1:1:nodeCount
        LIST_OF_MESH_NODE(k).buildOneHopNeighborList();
    end
end

%建立两跳邻居节点%
function buildTwoHopNeighborForEachNode()
    global LIST_OF_MESH_NODE;
    nodeCount=numel(LIST_OF_MESH_NODE);
    for k=1:1:nodeCount
        LIST_OF_MESH_NODE(k).buildTwoHopNeighborList();
    end
end


%把所有要发送的数据包事件都注册在这里%
function packetSendEventHelper(srcId,dstId,num,rate)
    if rate>50
        Log.print("速率超过允许范围");
        return;
    end
    global SYSTEM_TIME;
    global LIST_OF_MESH_NODE;
    firstTimeToSend=10*1000+SYSTEM_TIME;%第10ms开始发送第一个数据包%
    
    totalSendTime=1000*1000*num/rate;
    if num==1
        totalSendTime=0;
    end
    
    timeToSendList=linspace(firstTimeToSend,firstTimeToSend+totalSendTime,num);
    
    meshNode=LIST_OF_MESH_NODE(srcId);
    
    for k=1:1:num
        meshNode.submitMeshMessageSendEvent(dstId,timeToSendList(k));
    end
    
   
end


