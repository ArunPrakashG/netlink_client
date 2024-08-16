final class EndpointManager {
  const EndpointManager(this.baseUrl);

  final Uri baseUrl;

  Uri get login => baseUrl.resolve('/boaform/admin/formLogin');
  Uri get logout => baseUrl.resolve('/boaform/admin/formLogout');
  Uri get eponStatus => baseUrl.resolve('/status_epon.asp');
  Uri get pppoeUptime => baseUrl.resolve('/status_pppoe_uptime.asp');
  Uri get netConnectInfo => baseUrl.resolve('/status_net_connet_info.asp');
  Uri get commonJsFile => baseUrl.resolve('/admin/common.js');
}
