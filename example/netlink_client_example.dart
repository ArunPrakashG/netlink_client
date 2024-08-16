import 'package:netlink_client/netlink_client.dart';

void main() async {
  final client = NetlinkClient();

  await client.logout();

  if (await client.login('xxxxx', 'xxxxxxxxxx')) {
    print('Login successful');
  } else {
    print('Login failed');
  }
}
