-module(live_media).

-export([init/1, handle_frame/2]).

init(Options) ->
  io:format("Starting live media ~p~n", [Options]),
  {ok, state}.
  
handle_frame(Frame, State) ->
  {ok, Frame, State}.