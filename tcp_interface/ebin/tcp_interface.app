{
  application,
  tcp_interface,
  [
    {description, "A simple tcp interface"},
    {vsn, "0.1.0"},
    {modules, [
                ti_server,
                ti_sup
              ]},
    {registered, [ti_sup]},
    {applications, [kernel, stdlib, sasl, mnesia]},
    {mod, {ti_app, []}}
  ]
}.
