package googledocsclone.example.googledocsclone.controllers;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;

@Component
public class WebSocketController extends TextWebSocketHandler {

    private WebSocketSession session;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        super.afterConnectionEstablished(session);
        this.session = session;
        System.err.println(session.getId());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws IOException {
        String payload = message.getPayload();
        System.out.println("Received message: " + payload);
    }

    public void sendMessage(String message) throws IOException {
        if (session != null && session.isOpen()) {
            session.sendMessage(new TextMessage(message));
        }
    }
    public WebSocketSession getSession() {
        return session;
    }
}
