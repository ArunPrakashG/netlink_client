import 'package:netlink_client/netlink_client.dart';

void main() async {
  final client = NetlinkClient();

  await client.login('xxxxx', 'xxxxxxxxxx');
}
