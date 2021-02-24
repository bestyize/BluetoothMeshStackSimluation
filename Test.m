clear;
clc;

% 
% obj=TestObj(@eventHandler);
% obj.eventHandler(123,1111)
% 
% function eventHandler(num,xxx)
%     num+xxx
% end

% clear;
% clc;
% 
% global SYSTEM_TIME;
% 
% SYSTEM_TIME=0;
% position=Position(21,34);
% 
% meshNode=MeshNode(1,position);
% 
% meshNode.sendMsg(2);
% event=meshNode.eventList(1);
% 
% event.eventHandler(meshNode,event);
% 
% for k=1:1:numel(meshNode.eventList)
%     meshNode.eventList(k)
% end

% '123'
% '456'
% 
% 
% linspace(1,1,1)

% a=[1 2 3 4 5];
% b=[];
% 
% setdiff(b,a)
% 
% x=23140.6360815172;
% 
% int64(x)
% 
% global DEFAULT_RANGE;
% 
% DEFAULT_RANGE=15;
% 
% srcId=3;
% dstId=45;
% 
% DrawHelper.drawSrcAndDst(srcId,dstId);

% 
% rrd=12123.123;
% 
% a=floor(rrd)
% pause(10)
% unidrnd(a)

% fid=fopen('mesh.log','a+');
% fclose(fid);

% x=0:60*1000*1000:10000000000

% vector=1:1:10;
% Helper.vectorToString(vector)

% str=datestr(now,31);
% str=strrep(str,":","-");
% str=strrep(str," ","_")

% floor(rand(1,1)*3)+1
% 
% 
% t=200:200:150
% 
% numel(t)

% global DEFAULT_RANGE;
% DEFAULT_RANGE=15;

% matrix=TopoHelper.createTopologyMatrix(200,100,100);

% matrix=TopoHelper.loadTopology();

% srcId=1;
% dstId=10;
% nodeCnt=50;
% DrawHelper.drawSrcAndDst(nodeCnt,srcId,dstId);
% 
% DEFAULT_RANGE=15;
% matrix_200_nodes=[];
% n=200;
% maxX=100;
% maxY=100;
% for k=1:1:n
%     
%     pos=Position(round((DEFAULT_RANGE+rand()*(maxX-2*DEFAULT_RANGE))),round((DEFAULT_RANGE+rand()*(maxY-2*DEFAULT_RANGE))));
%     matrix_200_nodes=[matrix_200_nodes pos];
% end
% 
% matrix_200_nodes

% load("matrix_100_nodes");
% nodeMap=matrix_100_nodes;
% matrix_100_nodes=[];
% 
% for k=1:1:numel(nodeMap)/2
%     pos=Position(nodeMap(1,k),nodeMap(2,k));
%     matrix_100_nodes=[matrix_100_nodes pos];
% end
% 
% matrix_100_nodes

% srcId=1;
% dstId=10;
% nodeCnt=200;
% DrawHelper.drawSrcAndDst(nodeCnt,srcId,dstId);
% 
% linspace(15,85,10)
% 
% DEFAULT_RANGE=15;
% matrix_avg_225_nodes=[];
% n=225;
% maxX=100;
% maxY=100;
% x_set=linspace(15,85,sqrt(n));
% y_set=x_set;
% 
% for k=1:1:numel(x_set)
%     for p=1:1:numel(y_set)
%         pos=Position(x_set(k),y_set(p));
%         matrix_avg_225_nodes=[matrix_avg_225_nodes pos];
%     end
% end
% 
% clear DEFAULT_RANGE n maxX maxY x_set y_set pos k p;


% load("matrix_avg_196_nodes"); 
% matrix_avg_196_nodes=matrix_avg_14_nodes;
% clear matrix_avg_14_nodes;
% save matrix_avg_196_nodes

srcId=1;
dstId=49;
nodeCnt=49;
DrawHelper.drawAvgSrcAndDst(nodeCnt,srcId,dstId);




