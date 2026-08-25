import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, UseGuards } from '@nestjs/common';
import { TelematicsService } from '../modules/telematics/telematics.service';
import { SafetySosService } from '../modules/safety_sos/safety_sos.service';
import { StreamTelemetryDto } from '../modules/telematics/dto/stream-telemetry.dto';
import { TriggerSosDto } from '../modules/safety_sos/dto/trigger-sos.dto';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: 'telemetry',
})
export class TelemetryGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(TelemetryGateway.name);

  constructor(
    private readonly telematicsService: TelematicsService,
    private readonly sosService: SafetySosService,
  ) {}

  handleConnection(client: Socket) {
    this.logger.log(`Client connected to Telemetry Gateway: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('telemetry:stream')
  handleTelemetryStream(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { riderId: string; telemetry: StreamTelemetryDto },
  ) {
    if (!payload.riderId || !payload.telemetry) return;
    this.telematicsService.processTelemetry(payload.riderId, payload.telemetry);
    client.emit('telemetry:ack', { timestamp: new Date().toISOString() });
  }

  @SubscribeMessage('sos:trigger')
  async handleSosTrigger(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { riderId: string; sosData: TriggerSosDto },
  ) {
    this.logger.warn(`Received WSS SOS trigger for rider ${payload.riderId}`);
    const incident = await this.sosService.triggerSos(payload.riderId, payload.sosData);
    this.server.emit('sos:alert_broadcast', incident);
    client.emit('sos:acknowledged', { incidentId: incident._id, status: 'DISPATCHED' });
  }
}
