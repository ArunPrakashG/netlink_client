import 'package:netlink_client/netlink_client.dart';

void main() async {
  final client = NetlinkClient();

  await client.initialize();

  if (!await client.isSessionActive()) {
    await client.login(username: 'xxxxxx', password: 'xxxxxxx');
  }

  final wanInfo = await client.getWanInfo();

  for (final info in wanInfo) {
    print(info);
  }
}
