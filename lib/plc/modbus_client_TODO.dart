// modbus_client_TODO.dart file
import 'plc_client.dart';

class ModbusClientTodo implements PlcClient {
  @override
  Future<void> connect() async {
    // TODO: implement Modbus connection.
  }

  @override
  Future<void> disconnect() async {
    // TODO: implement Modbus disconnect.
  }

  @override
  Future<void> sendRecommendation(List<int> ids) async {
    // TODO: send recommendations to PLC.
  }
}