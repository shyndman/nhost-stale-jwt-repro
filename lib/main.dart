import 'dart:async';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:nhost_flutter_graphql/nhost_flutter_graphql.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SafeArea(
        child: Scaffold(
          body: MyHomePage(),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const _interval = Duration(seconds: 3);

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  late final NhostClient nhostClient;
  late DateTime timerStart;
  late Timer timer;
  int expectedSeconds = 0;
  int actualSeconds = 0;

  @override
  void initState() {
    print('initState');
    super.initState();

    WidgetsBinding.instance!.addObserver(this);

    nhostClient = NhostClient(baseUrl: 'https://backend-5e69d1d7.nhost.app');
    nhostClient.auth.login(
      email: 'scotty.hyndman@gmail.com',
      password: 'password',
    );

    timerStart = DateTime.now();
    late void Function() resetTimer;
    resetTimer = () {
      timer = Timer(_interval, () {
        print('tick');
        expectedSeconds += _interval.inSeconds;
        actualSeconds = DateTime.now().difference(timerStart).inSeconds;
        setState(() {});
        resetTimer();
      });
    };

    resetTimer();
  }

  @override
  void dispose() {
    print('dispose');
    super.dispose();

    timer.cancel();
    WidgetsBinding.instance!.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return NhostAuthProvider(
      auth: nhostClient.auth,
      child: NhostGraphQLProvider(
        gqlEndpointUrl: 'https://hasura-5e69d1d7.nhost.app/v1/graphql',
        child: Builder(
          builder: (context) {
            final auth = NhostAuthProvider.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth!.authenticationState.toString()),
                Text('expected: $expectedSeconds seconds'),
                Text('actual: $actualSeconds seconds'),
                const TodoSubscriber(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TodoSubscriber extends StatefulWidget {
  const TodoSubscriber({Key? key}) : super(key: key);

  @override
  _TodoSubscriberState createState() => _TodoSubscriberState();
}

class _TodoSubscriberState extends State<TodoSubscriber> {
  @override
  Widget build(BuildContext context) {
    print('todo build');

    return Subscription(
      options: SubscriptionOptions(document: gql('''
      query {
        todos {
          id
        }
      }
      ''')),
      builder: (result) {
        if (result.hasException) {
          return Text(result.exception.toString());
        } else if (result.isLoading) {
          return const Text('loading');
        } else {
          return Text(result.data.toString());
        }
      },
    );
  }
}
