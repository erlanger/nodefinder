%% @hidden

-module (nodefindersup).
-behaviour (supervisor).

-export ([ start_link/3, start_link/4, init/1 ]).

%-=====================================================================-
%-                                Public                               -
%-=====================================================================-

start_link (Addr, Port, Ttl) ->
  supervisor:start_link ({local,?MODULE}, ?MODULE, [ Addr, Port, Ttl ]).

start_link (Addr, Port, Ttl, IfName) ->
  supervisor:start_link ({local,?MODULE}, ?MODULE, [ Addr, Port, Ttl, IfName ]).

%-=====================================================================-
%-                         Supervisor callbacks                        -
%-=====================================================================-

init (Args) ->
  { ok,
    { { one_for_one, 3, 10 },
      [ { nodefindersrv,
          { nodefindersrv, start_link, Args },
          permanent,
          1000,
          worker,
          [ nodefindersrv ]
        }
      ]
    }
  }.
