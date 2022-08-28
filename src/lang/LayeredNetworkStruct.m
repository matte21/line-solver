function lqn=LayeredNetworkStruct()
% Data structure representation for a LayeredNetwork object
%
% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

lqn=[]; %faster than lqn=struct();
lqn.nidx = 0;  % total number of hosts, tasks, entries, and activities, except the reference tasks
lqn.nhosts = 0;
lqn.ntasks = 0;
lqn.nreftasks = 0;
lqn.nacts = 0;
lqn.nentries = 0;
lqn.ntasksof = [];  % number of tasks on the ith host
lqn.nentriesof = [];
lqn.nactsof = [];
lqn.tshift = 0;
lqn.eshift = 0;
lqn.ashift = 0;
lqn.ntasksof = [];
lqn.nidx = 0;
lqn.hostidx = [];
lqn.taskidx = [];
lqn.entryidx = [];
lqn.actidx = [];
lqn.tasksof = {};
lqn.entriesof = {};
lqn.actsof = {};
lqn.callsof = {};
lqn.hostdem = {};
lqn.think = {};
lqn.sched = {};
lqn.schedid = [];
lqn.names = {};
lqn.hashnames = {};
%lqn.shortnames = {};
lqn.mult = [];
lqn.repl = [];
lqn.type = [];
lqn.graph = sparse([]);
lqn.replies = [];
lqn.replygraph = sparse([]);

lqn.nitems = {};
lqn.itemlevelcap  = {};
lqn.replacementpolicy  = {};
lqn.nitemsof = {};
lqn.itemsdistribution = {};
lqn.iscache = [];
lqn.parent = [];

lqn.callidx = [];
lqn.calltype = sparse([]);
lqn.iscaller = sparse([]);
lqn.issynccaller = sparse([]);
lqn.isasynccaller = sparse([]);
lqn.callpair = [];
lqn.callproc = {};
lqn.callnames = {};
lqn.callhashnames = {};
%lqn.callshortnames = {};
lqn.taskgraph = sparse([]);
lqn.actpretype = sparse([]);
lqn.actposttype = sparse([]);

lqn.replies = false;
lqn.replygraph = [];
lqn.ncalls = [];
lqn.isref = false;
lqn.iscache = false;
end