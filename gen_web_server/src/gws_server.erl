-module(gws_server).

-behaviour(gen_server).

%% API
-export([start_link/3]).

%% gen_server callbacks
-export([
  init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,,
  terminate/2,
  code_change/3
]).

-record(state, {
  lsock,
  socket,
  request_line,
  headers = [],
  body = <<>>,
  content_remaining = 0,
  callback,
  user_data,
  parent
}).

%%%============================================================================
%%% API functions

start_link(Callback, LSock, UserArgs) ->
  gen_server:start_link(?MODULE, [Callback, LSock, UserArgs, self()], []).

%%%============================================================================
%%% gen_server callbacks

init([Callback, LSock, UserArgs, Parent]) ->
  {ok, UserData} = Callback:init(UserArgs),
  State = #state{
    lsock = LSock,
    callback = Callback,
    user_data = UserData,
    parent = Parent},
  {ok, State, 0}.

handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast(_Request, State) ->
  {noreply, State}.

handle_info({http, _Sock, {http_request, _,  _, _} = Request}, State) ->
  inet:setopts(State#state.socket, [{active, once}]),
  {noreply, header(Name, Value, State)};
handle_info({http, _Sock, {http_header, _, Name, _, Value}}, State) ->
  inet:setopts(State#state.socket, [{active, once}]),
  {noreply, header(Name, Value, State)};
handle_info({http, _Sock, http_oeh}, #state{content_remaining = 0} = State) ->
  {stop, normal, handle_http_request(State)};
handle_info({http, _Sock, http_oeh}, State) ->
  inet:setopts(State#state.socket, [{active, once}, {packet, raw}]),
  {noreply, State};
handle_info({http, _Sock, Data}, State) when is_binary(Data) ->
  ContentRem = State#state.content_remaining - byte_size(Data),
  Body       = list_to_binary([State#state.bady, Data]),
  NewState   = State#state{
    body = Body,
    content_remaining = ContentRem
  },
  if ContentRem > 0 ->
    inet:setopts(State#state.socket, [{active, once}]),
    {noreply, State};
  true ->
    {stop, normal, handle_http_request(NewState)}
  end;
