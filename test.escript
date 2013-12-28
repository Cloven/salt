#!/usr/bin/env escript
%% -*- erlang -*-
%%! -smp enable -sname salty

%%-mode(compile).
-import(timer).

main(_) ->
  true = code:add_patha("../salt/ebin"),
  application:start(inets),
  application:start(salt),
  test_fast_unbox(55000),
  test_gens(3500).

test_gens(Amount) ->
  {_,Ts,Tm} = erlang:now(),
  gen_keys(Amount),
  {_,Ns,Nm} = erlang:now(),
  Dt = ((Ns - Ts) * 1000000 + (Nm - Tm))/1000000,
  io:format("gens/s: ~p~n", [Amount/Dt]).

test_fast_unbox(Amount) ->
  {PubA, PrivA} = salt:crypto_box_keypair(),
  {PubB, PrivB} = salt:crypto_box_keypair(),
  Nonce = salt:crypto_random_bytes(24),
  PrecA = salt:crypto_box_beforenm(PubB, PrivA),
  PrecB = salt:crypto_box_beforenm(PubA, PrivB),
  Packet = gen_packet(PrecA, "Hello, world!", Nonce),
  {_,Ts,Tm} = erlang:now(),
  {ok, Outpacket} = read_packet_a_lot(PrecB, Packet, Nonce, Amount),
  {_,Ns,Nm} = erlang:now(),
  Dt = ((Ns - Ts) * 1000000 + (Nm - Tm))/1000000,
  io:format("reads/s: ~p~n", [Amount/Dt]).

gen_packet(MyPrec, Plaintext, Nonce) ->
  salt:crypto_box_afternm(Plaintext, Nonce, MyPrec).

read_packet(MyPrec, Packet, Nonce) ->
  salt:crypto_box_open_afternm(Packet, Nonce, MyPrec).

read_packet_a_lot(MyPrec, Packet, Nonce, 0) -> 
  salt:crypto_box_open_afternm(Packet, Nonce, MyPrec);
read_packet_a_lot(MyPrec, Packet, Nonce, N) -> 
  salt:crypto_box_open_afternm(Packet, Nonce, MyPrec),
  read_packet_a_lot(MyPrec, Packet, Nonce, N - 1).

gen_keys(0) -> ok;
gen_keys(N) ->
  {_, _} = salt:crypto_box_keypair(),
  gen_keys(N-1).
