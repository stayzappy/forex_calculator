import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(Icons.color_lens,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Theme'),
                  subtitle: Text(themeProvider.currentTheme ==
                          ThemeProvider.whiteYellowTheme
                      ? 'White & Yellow'
                      : 'Black & Yellow'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Toggle between themes
                    final newTheme = themeProvider.currentTheme ==
                            ThemeProvider.whiteYellowTheme
                        ? ThemeProvider.blackYellowTheme
                        : ThemeProvider.whiteYellowTheme;

                    themeProvider.changeTheme(newTheme);
                  },
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(Icons.notifications,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Notifications'),
                  subtitle: const Text('Enable/Disable'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(Icons.bar_chart,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Default Calculation Mode'),
                  subtitle: const Text('Standard'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(Icons.info_outline,
                      color: Theme.of(context).primaryColor),
                  title: const Text('About'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('App version 1.0.0'),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(
                              text:
                                  'Built by: ZappyTheDev, Check out more of my works ',
                            ),
                            TextSpan(
                              text: 'here',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Add your link action here
                                  // For example, launching a URL:
                                  // launchUrl(Uri.parse('https://yourwebsite.com'));
                                },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
