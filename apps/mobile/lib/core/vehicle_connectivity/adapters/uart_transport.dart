abstract class UartTransport {
  Stream<String> get dataStream;
  Future<bool> connect(String address);
  Future<void> disconnect();
  Future<bool> write(String data);
}
