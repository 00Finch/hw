use mio;
use std::io::Write;
use std::io;

use super::server::HWServer;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;
use super::handlers;

pub enum Action {
    SendMe(String),
    SendAllButMe(String),
    RemoveClient,
    ByeClient(String),
    ReactProtocolMessage(HWProtocolMessage),
    CheckRegistered,
    JoinLobby,
}

use self::Action::*;

pub fn run_action(server: &mut HWServer, token: mio::Token, poll: &mio::Poll, action: Action) {
    match action {
        SendMe(msg) =>
            server.send(token, &msg),
        SendAllButMe(msg) => {
            for c in server.clients.iter_mut() {
                if c.id != token {
                    c.send_string(&msg)
                }
            }
        },
        ByeClient(msg) => {
            server.react(token, poll, vec![
                SendMe(Bye(&msg).to_raw_protocol()),
                RemoveClient,
                ]);
        },
        RemoveClient => {
            server.clients[token].deregister(poll);
            server.clients.remove(token);
        },
        ReactProtocolMessage(msg) =>
            handlers::handle(server, token, poll, msg),
        CheckRegistered =>
            if server.clients[token].protocol_number > 0 && server.clients[token].nick != "" {
                server.react(token, poll, vec![
                    JoinLobby,
                    ]);
            },
        JoinLobby => {
            let joined_msg;
            {
                let mut lobby_nicks: Vec<&str> = Vec::new();
                for c in server.clients.iter() {
                    if c.room_id.is_some() {
                        lobby_nicks.push(&c.nick);
                    }
                }
                joined_msg = LobbyJoined(&lobby_nicks).to_raw_protocol();
            }
            let everyone_msg = LobbyJoined(&[&server.clients[token].nick]).to_raw_protocol();
            server.clients[token].room_id = Some(server.lobby_id);
            server.react(token, poll, vec![
                SendAllButMe(everyone_msg),
                SendMe(joined_msg),
                ]);
        },
        //_ => unimplemented!(),
    }
}
