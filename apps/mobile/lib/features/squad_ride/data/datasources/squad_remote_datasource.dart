import '../../../../core/network/api_client.dart';
import '../../domain/entities/squad_entity.dart';

class SquadRemoteDatasource {
  final ApiClient apiClient;

  SquadRemoteDatasource({required this.apiClient});

  Future<SquadRoomEntity> createSquad(String title) async {
    final response = await apiClient.post('/squad/create', data: {'title': title});
    return _parseSquadResponse(response.data);
  }

  Future<SquadRoomEntity> joinSquad(String squadCode) async {
    final response = await apiClient.post('/squad/join', data: {'squadCode': squadCode});
    return _parseSquadResponse(response.data);
  }

  Future<SquadRoomEntity> getSquad(String squadId) async {
    final response = await apiClient.get('/squad/$squadId');
    return _parseSquadResponse(response.data);
  }

  SquadRoomEntity _parseSquadResponse(Map<String, dynamic> data) {
    final membersJson = (data['members'] as List? ?? []);
    final members = membersJson.map((m) => SquadMemberEntity(
      riderId: m['riderId'] ?? '',
      fullName: m['fullName'] ?? 'Rider',
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      speedKmh: (m['speedKmh'] as num?)?.toDouble(),
      isCreator: m['isCreator'] ?? false,
    )).toList();

    return SquadRoomEntity(
      id: data['_id'] ?? data['id'] ?? '',
      squadCode: data['squadCode'] ?? '',
      title: data['title'] ?? 'Squad Ride',
      creatorId: data['creatorId'] ?? '',
      members: members,
      isActive: data['isActive'] ?? true,
    );
  }
}
