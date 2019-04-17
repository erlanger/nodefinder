%% @doc Multicast Erlang node discovery protocol.
%% Listens on a multicast channel for node discovery requests and
%% responds by connecting to the node.
%% @hidden
%% @end

-module (nodefindersrv).
-behaviour (gen_server).
-export ([ start_link/2, start_link/3, start_link/4, discover/0 ]).
-export ([ init/1,
           handle_call/3,
           handle_cast/2,
           handle_info/2,
           terminate/2,
           code_change/3]).

-oldrecord (state).

-record (state, { socket, addr, port, ifname}).
-record (statev2, { sendsock, recvsock, addr, port, ifname, watchnodes = [] }).

%-=====================================================================-
%-                                Public                               -
%-=====================================================================-

start_link (Addr, Port) ->
	  start_link (Addr, Port, 1).

start_link (Addr, Port, Ttl) ->
      gen_server:start_link ({ local, ?MODULE }, ?MODULE, [ { addr, Addr },
                                                            { port, Port },
                                                            { ttl, Ttl } ], []).

start_link (Addr, Port, Ttl, IfName) ->
  gen_server:start_link ({ local, ?MODULE }, ?MODULE, [ { addr, Addr },
                                                        { port, Port },
                                                        { ttl, Ttl },
                                                        { if_name, IfName} ], []).

discover () ->
  gen_server:call (?MODULE, discover).

%-=====================================================================-
%-                         gen_server callbacks                        -
%-=====================================================================-

init (Args) ->
  process_flag (trap_exit, true),

  check_node_host(),
  net_kernel:monitor_nodes(true),

  Opts = init_socket_opts (Args),

  Port = proplists:get_value (port, Args),
  { ok, RecvSocket } = gen_udp:open (Port, Opts),

  State = init_statev2 (RecvSocket, Args),

  { ok, discover (State) }.

handle_call (discover, _From, State) -> { reply, ok, discover (State) };
handle_call (_Request, _From, State) -> { noreply, State }.

handle_cast (_Request, State) -> { noreply, State }.

handle_info ({ udp, Socket, IP, InPortNo, Packet },
             State=#statev2{ recvsock = Socket }) ->
  { noreply, process_packet (Packet, IP, InPortNo, State) };

%Add downed node to list of watched nodes
handle_info ({ nodedown, Node }, State) ->
  Nodes = State#statev2.watchnodes,
  NewNodes = [ Node | Nodes ],
  erlang:send_after(30000,self(),{timed_discover, 30}),
  { noreply, State#statev2{watchnodes=NewNodes} };

%Remove node from list of watched nodes
handle_info ({ nodeup,   Node }, State) ->
  Nodes = State#statev2.watchnodes,
  NewNodes = Nodes -- [ Node ],
  %discover connects *THIS* node to the found nodes
  { noreply, discover(State#statev2{watchnodes=NewNodes}) };

%Try to discover nodes if watchnodes list has any nodes in it
handle_info ({ timed_discover,   AgainSecs },
             State = #statev2{watchnodes=Nodes}) when length(Nodes) >= 1 ->
  %TODO: think about exponential timing
  erlang:send_after(AgainSecs * 1000, self(), {timed_discover, AgainSecs * 1000}),
  { noreply, discover(State) };

%If watchnodes is empty simply ignore the timer
handle_info ({ timed_discover, _AgainSecs },
             State = #statev2{watchnodes=[]}) ->
  { noreply, State };

%Swallow unknown messages
handle_info (Msg, State) ->
  error_logger:info_msg("Unknown msg: ~p",[Msg]),
  { noreply, State }.

terminate (_Reason, State = #statev2{}) ->
  gen_udp:close (State#statev2.recvsock),
  gen_udp:close (State#statev2.sendsock),
  ok.

code_change (_OldVsn, State = #statev2{ifname = IfName}, _Extra) ->
  NewState = #statev2{ recvsock = State#state.socket,
                       sendsock = send_socket (1, IfName),
                       addr = State#state.addr,
                       port = State#state.port },
  { ok, NewState };
code_change (_OldVsn, State, _Extra) ->
  { ok, State }.

%-=====================================================================-
%-                               Private                               -
%-=====================================================================-

init_statev2 (RecvSocket, Args) ->
  Ttl = proplists:get_value (ttl, Args),
  #statev2{ recvsock = RecvSocket,
            sendsock = send_socket (Ttl, proplists:get_value (if_name, Args)),
            addr = proplists:get_value (addr, Args),
            port = proplists:get_value (port, Args) }.

init_socket_opts (Args) ->
  Addr = proplists:get_value (addr, Args),
  Membership =
    case proplists:get_value (if_name, Args) of
      undefined -> [ { add_membership, { 0, 0, 0, 0 } } ];
      IfName -> [ { add_membership, { Addr, getifaddrip (IfName) } } ]
    end,
  [ { active, true },
    { ip, Addr },
    { multicast_loop, true },
    { reuseaddr, true },
    list | Membership ].

discover (State) ->
  NodeString = atom_to_list (node ()),
  Time = seconds (),
  Mac = mac ([ <<Time:64>>, NodeString ]),
  Message = [ "DISCOVERV2 ", Mac, " ", <<Time:64>>, " ", NodeString ],
  case gen_udp:send (State#statev2.sendsock,
                     State#statev2.addr,
                     State#statev2.port,
                     Message) of
     ok           -> ok;
     {error, Err} -> error_logger:warning_msg("   UDP send error: ~p~n",[Err])
  end,
  State.

getifaddrip (IfName) ->
  case inet:getifaddrs() of
    {ok, IfAddrs} ->
      {_IfName, IfData} = proplists:lookup(binary_to_list(IfName), IfAddrs),
      case proplists:lookup(addr, IfData) of
        {addr, IfAddr} -> IfAddr;
        none         -> error_logger:error_msg("   No addr on specify interface: ~p~n", [IfName])
      end;
    {error, Err}  -> error_logger:error_msg("   Get interfaces addresses error: ~p~n",[Err])
  end.

mac (Message) ->
  % Don't use cookie directly, creates a known-plaintext attack on cookie.
  % hehe ... as opposed to using ps :)
  Key = crypto:hash(sha, erlang:term_to_binary (erlang:get_cookie ()) ),
  crypto:hmac (sha,Key, Message).

process_packet ("DISCOVER " ++ NodeName, IP, InPortNo, State) ->
  error_logger:warning_msg ("old DISCOVER packet from ~p (~p:~p) ~n",
                            [ NodeName,
                              IP,
                              InPortNo ]),
  State;
process_packet ("DISCOVERV2 " ++ Rest, IP, InPortNo, State) ->
  % Falling a mac is not really worth logging, since having multiple
  % cookies on the network is one way to prevent crosstalk.  However
  % the packet should always have the right structure.

  try
    <<Mac:20/binary, " ",
      Time:64, " ",
      NodeString/binary>> = list_to_binary (Rest),

    case { mac ([ <<Time:64>>, NodeString ]), abs (seconds () - Time) } of
      { Mac, AbsDelta } when AbsDelta < 300 ->
        net_adm:ping (list_to_atom (binary_to_list (NodeString)));
      { Mac, AbsDelta } ->
        error_logger:warning_msg ("expired DISCOVERV2 (~p) from ~p:~p~n",
                                  [ AbsDelta,
                                    IP,
                                    InPortNo ]);
      _ ->
        ok
    end
  catch
    error : { badmatch, _ } ->
      error_logger:warning_msg ("bad DISCOVERV2 from ~p:~p~n",
                                [ list_to_binary (Rest),
                                  IP,
                                  InPortNo ])
  end,

  State;
process_packet (_Packet, _IP, _InPortNo, State) ->
  State.

seconds () ->
  calendar:datetime_to_gregorian_seconds (calendar:universal_time ()).

send_socket (Ttl, IfName) ->
  SendInterface =
    case IfName of
      undefined -> [ { ip, { 0, 0, 0, 0 } } ];
      _IfName   -> [ { bind_to_device, IfName } ]
    end,
  SendOpts = [ { multicast_ttl, Ttl },
               { multicast_loop, true } | SendInterface ],

  { ok, SendSocket } = gen_udp:open (0, SendOpts),

  SendSocket.

%Check that the node host name is reachable
%print a warning if it is not
check_node_host() ->
   Host=hd(tl(string:tokens(atom_to_list(node()),"@"))),
   Warn =
      fun() ->
         error_logger:warning_msg("nodefinder: Host entry for ~p is not found!~n",
                                  [Host])
      end,
   case inet:parse_address(Host) of
      {ok,   _} -> case inet:gethostbyaddr(Host) of %we have anip address
                      {error, _} -> Warn();
                      {ok, _}    -> ok
                   end;
      {error,_} -> case inet:gethostbyname(Host) of %we have a host name
                      {error, _} -> Warn();
                      {ok, _}    -> ok
                   end
   end.
