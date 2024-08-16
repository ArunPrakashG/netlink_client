final class WanInfo {
  const WanInfo({
    required this.interface,
    required this.vlanId,
    required this.protocol,
    required this.igmpStatus,
    required this.state,
    required this.ipAddress,
    required this.subnetMask,
    required this.macAddress,
  });

  final String interface;
  final int vlanId;
  final String protocol;
  final bool igmpStatus;
  final bool state;
  final String ipAddress;
  final String subnetMask;
  final String macAddress;

  @override
  String toString() {
    return '''
WanInfo:
  Interface: $interface
  VLAN ID: $vlanId
  Protocol: $protocol
  IGMP Status: ${igmpStatus ? 'Enabled' : 'Disabled'}
  State: ${state ? 'Up' : 'Down'}
  IP Address: $ipAddress
  Subnet Mask: $subnetMask
  MAC Address: $macAddress
''';
  }
}
