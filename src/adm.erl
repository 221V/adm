-module(adm).
-description('ADM Monitoring Bootcode').
-behaviour(supervisor).
-behaviour(application).
-export([start/2, stop/1, init/1,main/1]).

main(X)   -> mad:repl(X).
tables() -> [ fs ].
opt()    -> [ set, named_table, { keypos, 1 }, public ].
spec()   -> ranch:child_spec(http, 100, ranch_tcp, port(), cowboy_protocol, env()).
env()    -> [ { env, [ { dispatch, points() } ] } ].
static() ->   { dir, "priv/static", mime() }.
n2o()    ->   { dir, "deps/n2o/priv", mime() }.
mime()   -> [ { mimetypes, cow_mimetypes, all   } ].
port()   -> [ { port, wf:config(n2o,port,8108)  } ].
points() -> cowboy_router:compile([{'_',
            [ {"/static/[...]",       n2o_static,  static()},
              {"/adm.css",            cowboy_static,  { file, "priv/static/adm.css", mime() }},
              {"/5HT.css",            cowboy_static,  { file, "priv/static/5HT.css", mime() }},
              {"/adm.min.js",         cowboy_static,  { file, "priv/static/adm.min.js", mime() }},
              {"/d3.js",              cowboy_static,  { file, "priv/static/d3.js", mime() }},
              {"/Geometria-Light.otf",cowboy_static,  { file, "priv/static/Geometria-Light.otf", mime() }},
              {"/n2o/[...]",          n2o_static,  n2o()},
              {"/ws/[...]",           n2o_stream,  []},
              {'_',                   n2o_cowboy,  []} ]} ]).

stop(_)    -> ok.
start(_,_) -> supervisor:start_link({local,adm},adm,[]).
init([])   -> kvs:join(), case wf:config(n2o,mq) of n2o_syn -> syn:init(); _ -> ok end,
              [ ets:new(T,opt()) || T <- tables() ],
              { ok, { { one_for_one, 5, 10 }, [spec()] } }.
