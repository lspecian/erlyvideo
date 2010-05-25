%%% @author     Max Lapshin <max@maxidoors.ru>
%%% @copyright  2009 Max Lapshin
%%% @doc        ems_media handler template
%%% @reference  See <a href="http://erlyvideo.org/" target="_top">http://erlyvideo.org/</a> for more information
%%% @end
%%%
%%%
%%% The MIT License
%%%
%%% Copyright (c) 2010 Max Lapshin
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in
%%% all copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%%% THE SOFTWARE.
%%%
%%%---------------------------------------------------------------------------------------
-module(rtsp_media).
-author('Max Lapshin <max@maxidoors.ru>').
-behaviour(ems_media).


-define(D(X), io:format("DEBUG ~p:~p ~p~n",[?MODULE, ?LINE, X])).

-export([init/1, handle_frame/2, handle_control/2, handle_info/2]).

-record(rtsp, {
  url,
  timeout
}).

connect_rtsp(#rtsp{url = URL, timeout = Timeout}) ->
  ?D({"Connecting to RTSP", URL}),
  rtsp_socket:read(URL, [{consumer, self()},{interleaved,true},{timeout,Timeout}]).



%%%------------------------------------------------------------------------
%%% Callback functions from ems_media
%%%------------------------------------------------------------------------

%%----------------------------------------------------------------------
%% @spec (Options::list()) -> {ok, State}                   |
%%                            {ok, State, {Format,Storage}} |
%%                            {stop, Reason}
%%
%% @doc Called by ems_media to initialize specific data for current media type
%% @end
%%----------------------------------------------------------------------

init(Options) ->
  Timeout = proplists:get_value(timeout, Options, 5000),
  State = #rtsp{timeout = Timeout, url = proplists:get_value(url, Options)},
  case connect_rtsp(State) of
    {ok, Reader} ->
      ems_media:set_source(self(), Reader),
      {ok, State};
    Else ->
      error_logger:error_msg("Failed to open RTSP media: ~p, will retry~n", [Else]),
      {stop, no_source}
  end.

%%----------------------------------------------------------------------
%% @spec (ControlInfo::tuple(), State) -> {reply, Reply, State} |
%%                                        {stop, Reason, State} |
%%                                        {error, Reason}
%%
%% @doc Called by ems_media to handle specific events
%% @end
%%----------------------------------------------------------------------
handle_control({subscribe, _Client, _Options}, State) ->
  {reply, ok, State};

handle_control({source_lost, _Source}, State) ->
  %% Source lost returns:
  %% {ok, State, Source} -> new source is created
  %% {stop, Reason, State} -> stop with Reason
  case connect_rtsp(State) of
    {ok, Reader} ->
      {reply, Reader, State};
    Else ->
      {stop, Else, State}
  end;

handle_control({set_source, _Source}, State) ->
  %% Set source returns:
  %% {reply, Reply, State}
  %% {stop, Reason}
  {reply, ok, State};

handle_control(_Control, State) ->
  {reply, ok, State}.

%%----------------------------------------------------------------------
%% @spec (Frame::video_frame(), State) -> {ok, Frame, State} |
%%                                        {noreply, State}   |
%%                                        {stop, Reason, State}
%%
%% @doc Called by ems_media to parse frame.
%% @end
%%----------------------------------------------------------------------
handle_frame(Frame, State) ->
  {reply, Frame, State}.


%%----------------------------------------------------------------------
%% @spec (Message::any(), State) ->  {noreply, State}   |
%%                                   {stop, Reason, State}
%%
%% @doc Called by ems_media to parse incoming message.
%% @end
%%----------------------------------------------------------------------
handle_info(_Message, State) ->
  {noreply, State}.







