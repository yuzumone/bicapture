import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:puppeteer/puppeteer.dart';

void main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addSeparator('Capture Microsoft Power BI Dashboard as image.\n');
  parser.addFlag('help',
      abbr: 'h',
      negatable: false,
      help: 'Show this message.', callback: (help) {
    if (help) {
      print(parser.usage);
      exit(64);
    }
  });
  parser.addOption('dashboard', help: 'dashboard id');
  parser.addOption('width', abbr: 'W', help: 'viewport width');
  parser.addOption('height', abbr: 'H', help: 'viewport height');
  parser.addOption('output', abbr: 'o', help: 'output file name');
  var results = parser.parse(arguments);
  var dashboard = results['dashboard'];
  var width = results['width'];
  var height = results['height'];
  var output = results['output'];
  if ([dashboard, width, height, output].contains(null)) {
    print('Set options');
    print(parser.usage);
    exit(1);
  }

  var client = http.Client();
  var res = await client.get('http://127.0.0.1:9222/json/version');
  var data = json.decode(res.body);
  var endpoint = data['webSocketDebuggerUrl'];

  var browser = await puppeteer.connect(browserWsEndpoint: endpoint);
  var page = await browser.newPage();
  var url = 'https://app.powerbi.com/groups/me/dashboards/$dashboard';
  await page.setViewport(
      DeviceViewport(width: int.parse(width), height: int.parse(height)));
  await page.goto(url, wait: Until.networkAlmostIdle);

  var selector =
      '#dashboardLandingContainer > legacy-scoped-root > ng-transclude > '
      'dashboard-scoped-services-bridge > dashboard-container-inner > div > div > '
      'div.dashboardSliderMain.fillAvailableSpace.errorBannerOff > div > div';
  var graph = await page.$(selector);
  var screenshot = await graph.screenshot();
  await File(output).writeAsBytes(screenshot);
  await page.close();

  print('Complate');
  exit(0);
}
