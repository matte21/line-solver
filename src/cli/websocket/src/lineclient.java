import java.util.*;
import java.io.*;
import java.net.*;
import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.handshake.ServerHandshake;

/**
 * This example demonstrates how to create a websocket connection to a server. Only the most
 * important callbacks are overloaded.
 */
public class LINEWebSocketClient extends WebSocketClient {
  
 public String message;

  public LINEWebSocketClient(URI serverURI, String msg) {
    super(serverURI);
    this.message = msg;
  }

  @Override
  public void onOpen(ServerHandshake handshakedata) { 
  	send(this.message);
  }

  @Override
  public void onMessage(String message) { System.out.println(message); }

  @Override
  public void onClose(int code, String reason, boolean remote) { }

  @Override
  public void onError(Exception ex) { ex.printStackTrace(); }

  public static void main(String[] args) throws URISyntaxException {
	Scanner sc = new Scanner(System.in);
	String message = new String("");
        for(int i = 1; sc.hasNext()== true; i++){
            message = message + "\n" + sc.nextLine();
        }

    LINEWebSocketClient c = new LINEWebSocketClient(new URI("ws://"+args[0]+":"+args[1]), message); 
    c.connect();
  }

}
