// Copyright (c) 2015, maldicion069 (Cristian Rodríguez) <ccrisrober@gmail.con>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.package com.example

import std.algorithm : remove;
import std.conv : to;
import std.socket : InternetAddress, Socket, SocketException, SocketSet, TcpSocket;
import std.stdio : writeln, writefln, sprintf, readln;
import std.json;
import object_user;
import utils;
import std.file;
import std.variant;
import key_object;
import map;

ObjectUser[int] positions;

void main(string[] args)
{
  ushort port;

  if (args.length >= 2)
      port = to!ushort(args[1]);
  else
      port = 8090;

	writefln("[S/s] Game Mode / [_] Test Mode:");
	string opc;
	auto isGame = false;
	opc = readln();
	opc = std.uni.toLower(opc);
	if (opc[0] == 's') {
		isGame = true;
	}
	if(isGame) {
		writefln("Game Mode");
	} else {
		writefln("Test Mode");
	}

  auto listener = new TcpSocket();
  assert(listener.isAlive);
  listener.blocking = false;
  listener.bind(new InternetAddress(port));
  listener.listen(10);
  writefln("Listening on port %d.", port);

  enum MAX_CONNECTIONS = 60;
  // Room for listener.
  auto socketSet = new SocketSet(MAX_CONNECTIONS + 1);
  Socket[] reads;

	string text = readText("data.json");
	//writeln(text);

	auto data = jsonToVariant(text);
	string map_0 = "";
	foreach(Variant line; data["map"]) {
		map_0 ~= to!string(line);
	}
	//writeln(map_0);

	//TODO Remove pointer at finish!
	KeyObject*[string] keys;
	keys["Red"] = new KeyObject(1, 5 * 64, 5 * 64, "Red");
	keys["Blue"] = new KeyObject(2, 6 * 64, 5 * 64, "Blue");
	keys["Yellow"] = new KeyObject(3, 7 * 64, 5 * 64, "Yellow");
	keys["Green"] = new KeyObject(4, 8 * 64, 5 * 64, "Green");

	KeyObject[int] keys_0;
	foreach(Variant key; data["keys"]) {
		keys_0[keys[to!string(key)].getId] = *keys[to!string(key)];
	}

	foreach (key; keys_0) {
		RealObjects[key.getId] = key;
	}

	TMap[] maps;
	maps ~= TMap(to!int(to!string(data["id"])), map_0,
				to!int(to!string(data["width"])), to!int(to!string(data["height"])), keys_0);

    while (true)
    {
        socketSet.add(listener);

        foreach (sock; reads)
            socketSet.add(sock);

        Socket.select(socketSet, null, null);

		bool goExit = false;
		string val = "";
        for (size_t i = 0; i < reads.length; i++)
        {
            if (socketSet.isSet(reads[i]))
            {
                char[1024] buf;
                auto datLength = reads[i].receive(buf[]);

                if (datLength == Socket.ERROR)
                    writeln("Connection error.");
                else if (datLength != 0)
                {
                    writefln("Received %d bytes from %s: \"%s\"", datLength, reads[i].remoteAddress().toString(), buf[0..datLength]);
                    val = "";
        					goExit = false;
        					JSONValue json;
        					string str = to!string(buf[0..datLength]);
        					try {
        						json = parseJSON(str);
        						val = json["Action"].str;
        						writeln(val);
        					}
        					catch (JSONException je) {
        						//writeln(je);
        					}

        					if (val == "initWName") {
        						string username = json["Name"].str;
        						ObjectUser ou = ObjectUser(to!int(reads[i].remoteAddress.toPortString()), 5*64, 5*64);

        						NewConnection nc = NewConnection("sendMap", maps[ou.getMap], ou.getPosX, ou.getPosY, ou.getId, positions);
        						positions[to!int(reads[i].remoteAddress.toPortString())] = ou;

        						string ret = toJson(nc) ~ "\n";

        						JSONValue v = toJsonValue(ou);
        						v.object["Action"] = "new";
        						str = toJson(v);

        						reads[i].send(ret);

        						writefln("\tTotal connections: %d", reads.length);
        						writefln("\tTotal connections: %d", positions.length);

        					} else if (val == "move") {
        						positions[to!int(reads[i].remoteAddress.toPortString())].setPosition(to!float(to!string(json.opIndex("Pos").opIndex("X"))), to!float(to!string(json.opIndex("Pos").opIndex("Y"))));
        						if(!isGame) {
									reads[i].send(str);
								}
							} else if (val == "position") {
        						sendPosition(reads[i], to!int(reads[i].remoteAddress.toPortString()));
        						continue;
        					} else if (val == "fight") {
        						/*sendFightToAnotherClient(
        							reads[i], to!int(reads[i].remoteAddress.toPortString()),
        							reads[json.opIndex("Id_enemy").uinteger], to!int(reads[json.opIndex("Id_enemy").uinteger].remoteAddress.toPortString())
        						);*/
        					} else if (val == "finishBattle") {
        					} else if (val == "getObj") {
        						int id_obj = to!int(to!string(json.opIndex("Id_obj")));
        						int id_user = to!int(to!string(json.opIndex("Id_user")));
        						json["Action"] = "remObj";
        						KeyObject ko = maps[0].removeKeyObject(id_obj);
        						positions[id_user].addObject(ko);
        						str = toJson(json);
        					} else if (val == "freeObj") {
        						int id_obj = to!int(to!string(json.opIndex("Obj").opIndex("Id_obj")));
        						int id_user = to!int(to!string(json.opIndex("Id_user")));
        						float posX = to!float(to!string(json.opIndex("Obj").opIndex("PosX")));
        						float posY =to!float(to!string(json.opIndex("Obj").opIndex("PosY")));
        						KeyObject obj = maps[0].addKeyObject(
        							id_obj,
        							posX,
        							posY
        						);
        						positions[id_user].removeObject(obj.getId);
        						AddObj addObj = AddObj("addObj", obj);
        						str = toJson(addObj);
        					} else if (val == "exit") {
        						positions.remove(to!int(reads[i].remoteAddress.toPortString()));
        						writefln("\tTotal connections: %d", positions.length);

								if(isGame) {
									Exit ex = Exit("exit", to!int(reads[i].remoteAddress.toPortString()));

        							str = toJson(ex);
								} else {
									reads[i].send(toJson(ExitStr("exit", "Me")) ~ "\n");
								}

        						goExit = true;
        					}
							if(isGame) {
        						foreach (sock; reads) {
        							if(sock.isAlive && sock != reads[i]) {
        								sock.send(str);
        								writeln(sock.remoteAddress);
        								writeln(sock.remoteAddress.toPortString());
        							}
        						}
							}
        					if(goExit) {
        						goExit = false;
        						goto exit;
        					}
        					continue;
                }
                else
                {
                    try
                    {
                        // if the connection closed due to an error, remoteAddress() could fail
                        writefln("Connection from %s closed.", reads[i].remoteAddress().toString());
                    }
                    catch (SocketException)
                    {
                        writeln("Connection closed.");
                    }
                }
				exit:
                // release socket resources now
				positions.remove(to!int(reads[i].remoteAddress.toPortString()));
                reads[i].close();

                reads = reads.remove(i);
                // i will be incremented by the for, we don't want it to be.
                i--;

                writefln("\tTotal connections: %d", reads.length);
            }
        }

        if (socketSet.isSet(listener))        // connection request
        {
            Socket sn = listener.accept();
            scope (failure)
            {
                writefln("Error accepting");

                if (sn)
                    sn.close();
            }
            assert(sn.isAlive);
            assert(listener.isAlive);

            if (reads.length < MAX_CONNECTIONS)
            {
                writefln("Connection from %s established.", sn.remoteAddress().toString());
				reads ~= sn;
			}
            else
            {
                writefln("Rejected connection from %s; too many connections.", sn.remoteAddress().toString());
                sn.close();
                assert(!sn.isAlive);
                assert(listener.isAlive);
            }
        }

        socketSet.reset();
    }
}

static void sendPosition(ref Socket sock, int port) {
	JSONValue v = toJsonValue(positions[port]);
	string ret = toJson(v);
	sock.send(ret);
}

static void sendFightToAnotherClient(ref Socket sock_emisor, int id_emisor, ref Socket sock_receiver, int id_receiver) {
	SendFightAnotherClient sf = SendFightAnotherClient ("hide", [id_emisor, id_receiver]);
}
