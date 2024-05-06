package googledocsclone.example.googledocsclone.controllers;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

@Component
public class WebSocketController extends TextWebSocketHandler {

    //private WebSocketSession session;

    private Set<WebSocketSession> sessions = new HashSet<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        super.afterConnectionEstablished(session);
        //this.session = session;
        sessions.add(session);
        System.err.println(session.getId() + " connected");
    }

    public void sendMessageToAll(String message) throws IOException {
        //System.out.println("INSIDE sendMessageToAll");
        for (WebSocketSession session : sessions) {
            if (session.isOpen()) {
                session.sendMessage(new TextMessage(message));
                System.out.println("BACKEND Sent message: " + message + " to session: " + session.getId());
            }
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws IOException {
        String payload = message.getPayload();
        System.out.println("BACKEND Received message: " + payload);

        sendMessageToAll(payload);
    }

    // public void sendMessage(WebSocketSession session, String message) throws IOException {
    //     if (session != null && session.isOpen()) {
    //         session.sendMessage(new TextMessage(message));
    //     }
    // }

    // public WebSocketSession getSession() {
    //     return session;
    // }
}
