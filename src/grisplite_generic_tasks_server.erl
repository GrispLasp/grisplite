-module(grisplite_generic_tasks_server).

-behaviour(gen_server).

-include_lib("grisplite.hrl").

%% API
-export([start_link/0]).
-export([terminate/0]).
-export([add_task/1]).
-export([add_permatask/1]).
-export([remove_all_tasks/0]).
-export([remove_task/1]).
-export([get_all_tasks/0]).
-export([find_task/1]).

%% Gen Server Callbacks
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).
-export([code_change/3]).


%% Records
-record(state, {lasp_identifiers = []}).


%% ===================================================================
%% API functions
%% ===================================================================

start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

terminate() -> gen_server:call(?MODULE, {terminate}).

add_task(Task) -> gen_server:call(?MODULE, {add_task, Task}).

add_permatask(Task) -> gen_server:call(?MODULE, {add_permatask, Task}).

remove_task(Name) -> gen_server:call(?MODULE, {remove_task, Name}).

remove_all_tasks() -> gen_server:call(?MODULE, {remove_all_tasks}).

get_all_tasks() -> gen_server:call(?MODULE, {get_all_tasks}).

find_task(Name) -> gen_server:call(?MODULE, {find_task, Name}).


%% ===================================================================
%% Gen Server callbacks
%% ===================================================================

init([]) ->
  logger:log(info, "Starting a generic tasks server ~n"),
  %% Ensure Gen Server gets notified when his supervisor dies
  Vars = grisplite_config:get(generic_tasks_sets_names, []),
  LaspIdentifiers = [ grisplite_util:atom_to_lasp_identifier(X, state_orset) || X <- Vars ],
  grisplite_util:declare_crdts(Vars),
  process_flag(trap_exit, true),
  {ok, #state{lasp_identifiers = LaspIdentifiers}}.

% TODO: add infinite execution of a task
handle_call({add_task, {TaskName, Targets, Fun}}, _From, State) ->
  logger:log(info, "=== ~p ~p ~p ===~n", [TaskName, Targets, Fun]),
  Task = {TaskName, Targets, Fun},
  {ok, Tasks} = lasp:query({<<"tasks">>, state_orset}),
  TasksList = sets:to_list(Tasks),
  TaskExists = [{Name, Targets, Fun} || {Name, Targets, Fun} <- TasksList, Name =:= TaskName],
  case length(TaskExists) of
    1 ->
      logger:log(info, "=== Error, task already exists ==="),
      {reply, {ko, task_already_exist}, State};
    0 ->
      lasp:update({<<"tasks">>, state_orset}, {add, Task}, self()),
      {reply, ok, State}
  end;

handle_call({add_permatask, {TaskName, Targets, Fun}}, _From, State) ->
  logger:log(info, "=== [PERMANENT] ~p ~p ~p ===~n", [TaskName, Targets, Fun]),
  Task = {TaskName, Targets, Fun},
  {ok, Tasks} = lasp:query({<<"permatasks">>, state_orset}),
  TasksList = sets:to_list(Tasks),
  TaskExists = [{Name, Targets, Fun} || {Name, Targets, Fun} <- TasksList, Name =:= TaskName],
  case length(TaskExists) of
    1 ->
      logger:log(info, "=== Error, task already exists ==="),
      {reply, {ko, task_already_exist}, State};
    0 ->
      lasp:update({<<"permatasks">>, state_orset}, {add, Task}, self()),
      {reply, ok, State}
  end;


handle_call({remove_task, TaskName}, _From, State) ->
  {ok, Tasks} = lasp:query({<<"tasks">>, state_orset}),
  TasksList = sets:to_list(Tasks),
  TaskToRemove = [{Name, Targets, Fun} || {Name, Targets, Fun} <- TasksList, Name =:= TaskName],
  case length(TaskToRemove) of
    1 ->
      ExtractedTask = hd(TaskToRemove),
      logger:log(info, "=== Task to Remove ~p ===~n", [ExtractedTask]),
      lasp:update({<<"tasks">>, state_orset}, {rmv, ExtractedTask}, self());
    0 ->
      logger:log(info, "=== Task does not exist ===~n");
    _ ->
      logger:log(info, "=== Error, more than 1 task === ~n")
  end,
  {reply, ok, State};


handle_call({remove_all_tasks}, _From, State) ->
  {ok, Tasks} = lasp:query({<<"tasks">>, state_orset}),
  TasksList = sets:to_list(Tasks),
  lasp:update({<<"tasks">>, state_orset}, {rmv_all, TasksList}, self()),
  {reply, ok, State};

handle_call({get_all_tasks}, _From, State) ->
  {ok, Tasks} = lasp:query({<<"tasks">>, state_orset}),
  TasksList = sets:to_list(Tasks),
  {reply, TasksList, State};

handle_call({find_task, TaskName}, _From, State) ->
  {ok, Tasks} = lasp:query({<<"tasks">>, state_orset}),
  TasksList = sets:to_list(Tasks),
  Task = [{Name, Targets, Fun} || {Name, Targets, Fun} <- TasksList, Name =:= TaskName],
  case length(Task) of
    0 ->
      {reply, task_not_found, State};
    1 ->
      {reply, {ok, hd(Task)}, State};
    _ ->
      {reply, more_than_one_task, State}
  end;

handle_call(stop, _From, State) ->
  {stop, normal, ok, State}.


handle_info(Msg, State) ->
    logger:log(info, "=== Unknown message: ~p~n", [Msg]),
    {noreply, State}.

handle_cast(_Msg, State) -> {noreply, State}.

terminate(Reason, _S) ->
  logger:log(error, "=== Terminating Generic server (reason: ~p) ===~n",[Reason]),
  ok.

code_change(_OldVsn, S, _Extra) ->
  {ok, S}.


%%====================================================================
%% Internal Functions
%%====================================================================
